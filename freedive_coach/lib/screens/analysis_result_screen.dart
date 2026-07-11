import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.result.videoPath != null && widget.result.videoPath!.isNotEmpty) {
      final file = File(widget.result.videoPath!);
      if (await file.exists()) {
        _videoController = VideoPlayerController.file(file);
        try {
          await _videoController!.initialize();
          _videoController!.addListener(_videoListener);
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        } catch (e) {
          debugPrint('Video init error: $e');
        }
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      final isPlaying = _videoController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    if (_isVideoInitialized || widget.result.videoPath != null)
                      _buildVideoCard(),
                    if (_isVideoInitialized || widget.result.videoPath != null)
                      const SizedBox(height: 16),
                    _buildOverallCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildCategoriesCard(),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                    const SizedBox(height: 16),
                    _buildHookCard(context),
                    const SizedBox(height: 16),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, color: AppColors.text, size: 24),
          ),
          Text('분석 결과', style: AppTextStyles.titleSmall),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return GestureDetector(
      onTap: _isVideoInitialized ? _togglePlayPause : null,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14405F), Color(0xFF071522)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized && _videoController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBright,
                ),
              ),
            // Play/Pause overlay
            if (_isVideoInitialized)
              AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            // Top badges
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  AppBadge(
                    text: widget.result.discipline.displayName,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    text: widget.result.mode == AnalysisMode.overview ? '전체 분석' : '구간 분석',
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    textColor: AppColors.text,
                  ),
                ],
              ),
            ),
            // Video progress bar
            if (_isVideoInitialized && _videoController != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primaryBright,
                    bufferedColor: AppColors.surface2,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),
            // Duration
            if (_isVideoInitialized && _videoController != null)
              Positioned(
                bottom: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_videoController!.value.duration),
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14405F), Color(0xFF071522)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.result.averageScore.toStringAsFixed(1),
                style: AppTextStyles.titleLarge.copyWith(fontSize: 56),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 5',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreLabel(widget.result.averageScore),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBright),
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 4.5) return '훌륭해요!';
    if (score >= 4.0) return '좋아요!';
    if (score >= 3.5) return '괜찮아요';
    if (score >= 3.0) return '조금 더 연습해요';
    return '기초부터 다시!';
  }

  Widget _buildSummaryCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  '다이빙 캣 코치 총평',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.result.overall,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('항목별 점수', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          ...widget.result.categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCategoryRow(category),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryResult category) {
    final percentage = (category.score / 5.0 * 100).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.name,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            Row(
              children: [
                Text(
                  category.score.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($percentage%)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * (category.score / 5.0);
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: barWidth,
                height: 8,
                decoration: BoxDecoration(
                  color: _getScoreColor(category.score),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                category.note,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4.0) return AppColors.primaryBright;
    if (score >= 3.0) return AppColors.amber;
    return AppColors.coral;
  }

  Widget _buildTipsCard() {
    final tips = widget.result.categories
        .where((c) => c.tip.isNotEmpty)
        .map((c) => c.tip)
        .toList();

    if (tips.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u{1F4A1} 개선 팁', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key < tips.length - 1 ? 10 : 0),
                child: _buildTip(entry.key + 1, entry.value),
              )),
        ],
      ),
    );
  }

  Widget _buildTip(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.tealDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHookCard(BuildContext context) {
    if (widget.result.hook.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SNS 공유용 문구',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.result.hook));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('클립보드에 복사되었습니다')),
                        );
                      },
                      child: const Icon(Icons.copy, size: 14, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${widget.result.hook}"',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO: Implement log linking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그 연결 기능 준비 중')),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link, size: 16, color: AppColors.text),
                  const SizedBox(width: 6),
                  Text('로그에 연결', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '완료',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
