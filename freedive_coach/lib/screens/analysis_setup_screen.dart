import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
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
  final _picker = ImagePicker();

  Discipline _selectedDiscipline = Discipline.cwt;
  AnalysisMode _analysisMode = AnalysisMode.overview;
  List<XFile> _selectedFiles = [];
  bool _isAnalyzing = false;
  String? _errorMessage;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // In production, load API key from secure storage or environment
    // For testing, you would call: _geminiService.setApiKey('your-api-key');
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles = images.take(12).toList();
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 선택 실패: $e';
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedFiles = [video];
          _errorMessage = '동영상 분석은 아직 준비 중입니다. 이미지를 선택해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '동영상 선택 실패: $e';
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _errorMessage = '분석할 이미지를 선택해주세요.';
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
      // Extract frames from images
      final imageFiles = _selectedFiles.map((f) => File(f.path)).toList();
      final extractResult = await _frameExtractor.extractFromImages(
        imageFiles,
        onProgress: (done, total) {
          setState(() {
            _progress = done / total * 0.5; // First 50% for extraction
          });
        },
      );

      setState(() {
        _progress = 0.5;
      });

      // Call Gemini API
      final requestId = DateTime.now().microsecondsSinceEpoch.toString();
      final result = await _geminiService.analyzeFrames(
        requestId: requestId,
        discipline: _selectedDiscipline,
        mode: _analysisMode,
        frames: extractResult.frames,
      );

      setState(() {
        _progress = 1.0;
      });

      // Navigate to results
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
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
                  '다이빙 영상이나 사진을 업로드하면 AIDA 기준으로 폼을 분석해드려요.',
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
                color: isSelected ? AppColors.primaryBright : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('미디어', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        if (_selectedFiles.isEmpty) ...[
          _buildMediaPicker(),
        ] else ...[
          _buildSelectedMedia(),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedFiles = []),
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
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, color: AppColors.muted, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '사진 선택',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _pickVideo,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, color: AppColors.muted, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '동영상 선택',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                  Text(
                    '(준비중)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMedia() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Padding(
            padding: EdgeInsets.only(right: index < _selectedFiles.length - 1 ? 12 : 0),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface2,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: AppColors.muted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.coral.withOpacity(0.3)),
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
    final canAnalyze = _selectedFiles.isNotEmpty &&
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
