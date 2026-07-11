import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../services/analysis_storage.dart';
import '../services/frame_extractor_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/discipline_selector.dart';
import '../widgets/surface_card.dart';
import 'analysis_result_screen.dart';

class AnalysisSetupScreen extends StatefulWidget {
  const AnalysisSetupScreen({super.key});

  @override
  State<AnalysisSetupScreen> createState() => _AnalysisSetupScreenState();
}

class _AnalysisSetupScreenState extends State<AnalysisSetupScreen> {
  final _geminiService = GeminiService();
  final _frameExtractor = FrameExtractorService();
  final _analysisStorage = AnalysisStorage();
  final _picker = ImagePicker();

  Discipline _selectedDiscipline = Discipline.cwt;
  AnalysisMode _analysisMode = AnalysisMode.overview;
  XFile? _selectedVideo;
  Uint8List? _videoThumbnail;
  bool _isAnalyzing = false;
  String? _errorMessage;
  double _progress = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _geminiService.setApiKey(apiKey);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _errorMessage = null;
          _videoThumbnail = null;
        });

        // Generate thumbnail
        final thumbnail = await _frameExtractor.getVideoThumbnail(video.path);
        if (mounted && thumbnail != null) {
          setState(() {
            _videoThumbnail = thumbnail;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '동영상 선택 실패: $e';
      });
    }
  }

  void _startProgressAnimation() {
    _progressTimer?.cancel();
    _progress = 0;
    // Animate from 0% to 95% with diminishing speed
    // Feels natural: fast at start, slows down as it approaches completion
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted || _progress >= 0.95) {
        timer.cancel();
        return;
      }
      setState(() {
        // Slow down as we approach 0.95
        final remaining = 0.95 - _progress;
        final increment = remaining * 0.025; // 2.5% of remaining each tick
        _progress = (_progress + increment).clamp(0.0, 0.95);
      });
    });
  }

  void _stopProgressAnimation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _startAnalysis() async {
    if (_selectedVideo == null) {
      setState(() {
        _errorMessage = '분석할 동영상을 선택해주세요.';
      });
      return;
    }

    if (!_geminiService.isConfigured) {
      setState(() {
        _errorMessage = 'API 키가 설정되지 않았습니다.';
      });
      return;
    }

    final rubric = Rubric.forDiscipline(_selectedDiscipline);
    if (rubric == null) {
      setState(() {
        _errorMessage = '아직 지원하지 않는 종목입니다: ${_selectedDiscipline.displayName}';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _progress = 0;
    });

    try {
      // Start fake progress animation immediately
      _startProgressAnimation();

      // Extract frames from video (0% ~ 20%)
      final videoFile = File(_selectedVideo!.path);
      final extractResult = await _frameExtractor.extractFromVideo(
        videoFile,
        onProgress: (done, total) {
          // Don't update progress here - let animation handle it
        },
      );

      // Call Gemini API
      final requestId = DateTime.now().microsecondsSinceEpoch.toString();
      final apiResult = await _geminiService.analyzeFrames(
        requestId: requestId,
        discipline: _selectedDiscipline,
        mode: _analysisMode,
        frames: extractResult.frames,
      );

      // Stop fake progress
      _stopProgressAnimation();

      // Save thumbnail to file
      String? thumbnailPath;
      if (_videoThumbnail != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final thumbnailDir = Directory('${appDir.path}/thumbnails');
        if (!await thumbnailDir.exists()) {
          await thumbnailDir.create(recursive: true);
        }
        final thumbnailFile = File('${thumbnailDir.path}/${apiResult.id}.jpg');
        await thumbnailFile.writeAsBytes(_videoThumbnail!);
        thumbnailPath = thumbnailFile.path;
      }

      // Add video and thumbnail paths to result
      final result = apiResult.copyWith(
        videoPath: _selectedVideo!.path,
        thumbnailPath: thumbnailPath,
      );

      setState(() {
        _progress = 1.0;
      });

      // Save the result to storage
      await _analysisStorage.saveResult(result);

      // Navigate to results
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      _stopProgressAnimation();
      setState(() {
        _errorMessage = '분석 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildDisciplineSection(),
                    const SizedBox(height: 20),
                    _buildModeSection(),
                    const SizedBox(height: 20),
                    _buildMediaSection(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                    if (_isAnalyzing) ...[
                      const SizedBox(height: 16),
                      _buildProgressIndicator(),
                    ],
                    const SizedBox(height: 24),
                    _buildAnalyzeButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
          ),
          Text('폼 분석', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('\u{1F431}', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 폼 분석',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBright,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '다이빙 영상을 업로드하면 AIDA 기준으로 폼을 분석해드려요.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineSection() {
    final supported = Rubric.supportedDisciplines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('종목', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        DisciplineSelector(
          selected: _selectedDiscipline,
          onSelected: (discipline) {
            setState(() => _selectedDiscipline = discipline);
          },
          filter: (d) => supported.contains(d),
        ),
        if (!supported.contains(_selectedDiscipline))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedDiscipline.displayName}은 아직 지원하지 않습니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.coral),
            ),
          ),
      ],
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('분석 모드', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildModeChip(
                label: '전체 분석',
                subtitle: '다이브 전체 흐름',
                mode: AnalysisMode.overview,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeChip(
                label: '구간 분석',
                subtitle: '특정 구간 집중',
                mode: AnalysisMode.segment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required String subtitle,
    required AnalysisMode mode,
  }) {
    final isSelected = _analysisMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _analysisMode = mode),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.text : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(Icons.phone_android, color: AppColors.primaryBright, size: 40),
            const SizedBox(height: 12),
            Text(
              '모바일 앱 전용 기능',
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '동영상 분석은 iOS/Android 앱에서만 사용 가능합니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('동영상', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        if (_selectedVideo == null) ...[
          _buildMediaPicker(),
        ] else ...[
          _buildSelectedMedia(),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() {
              _selectedVideo = null;
              _videoThumbnail = null;
            }),
            child: Text(
              '다시 선택',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPicker() {
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.tealDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.videocam, color: AppColors.primaryBright, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              '동영상 선택',
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '다이빙 영상을 선택해주세요',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface2,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoThumbnail != null)
            Image.memory(
              _videoThumbnail!,
              fit: BoxFit.cover,
            )
          else
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.coral, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.caption.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppColors.surface2,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          _progress < 0.5 ? '프레임 추출 중...' : '분석 중...',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final canAnalyze = !kIsWeb &&
        _selectedVideo != null &&
        !_isAnalyzing &&
        Rubric.supportedDisciplines.contains(_selectedDiscipline);

    return GestureDetector(
      onTap: canAnalyze ? _startAnalysis : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: canAnalyze ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isAnalyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: canAnalyze ? Colors.white : AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '분석 시작',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: canAnalyze ? Colors.white : AppColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
