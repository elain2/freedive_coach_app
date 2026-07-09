import 'dart:io';
import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../models/media_attachment.dart';
import '../services/log_storage.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'new_log_screen.dart';

class LogDetailScreen extends StatefulWidget {
  final DiveLog log;

  const LogDetailScreen({super.key, required this.log});

  @override
  State<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends State<LogDetailScreen> {
  final _logStorage = LogStorage();
  final _mediaService = MediaService();
  late DiveLog _log;
  List<MediaAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    final attachments = await _mediaService.getAttachments(_log.id);
    if (mounted) {
      setState(() => _attachments = attachments);
    }
  }

  Future<void> _editLog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewLogScreen(existingLog: _log),
      ),
    );

    if (result == true) {
      // Reload the log and attachments
      final updatedLog = await _logStorage.getLog(_log.id);
      if (updatedLog != null && mounted) {
        setState(() => _log = updatedLog);
        _loadAttachments();
      }
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        title: Text('로그 삭제', style: AppTextStyles.titleSmall),
        content: Text(
          '이 로그를 삭제하시겠습니까?\n삭제된 로그는 복구할 수 없습니다.',
          style: AppTextStyles.body.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '삭제',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete all media first
      await _mediaService.deleteAllMediaForLog(_log.id);
      await _logStorage.deleteLog(_log.id);
      if (mounted) {
        Navigator.of(context).pop(true);
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
                    _buildMainCard(),
                    const SizedBox(height: 16),
                    if (_log.discipline.isDepthDiscipline &&
                        (_log.mouthfillDepth != null || _log.freefallDepth != null))
                      ...[
                        _buildTechniqueCard(),
                        const SizedBox(height: 16),
                      ],
                    if (_hasDetails()) ...[
                      _buildDetailsCard(),
                      const SizedBox(height: 16),
                    ],
                    if (_log.notes != null && _log.notes!.isNotEmpty) ...[
                      _buildNotesCard(),
                      const SizedBox(height: 16),
                    ],
                    if (_attachments.isNotEmpty) ...[
                      _buildMediaGallery(),
                      const SizedBox(height: 16),
                    ],
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDetails() {
    return _log.weight != null ||
        _log.condition != null ||
        _log.contractions != null;
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
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.muted),
            ),
          ),
          Text('로그 상세', style: AppTextStyles.titleSmall),
          GestureDetector(
            onTap: _editLog,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.edit, size: 16, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_log.diveDateFormatted, style: AppTextStyles.caption),
              AppBadge(text: _log.discipline.displayName),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrimaryMetric(),
          if (_log.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  _log.location!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
          if (_log.duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  _log.durationFormatted,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric() {
    if (_log.discipline.isTimeDiscipline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _log.durationFormatted,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
          ),
        ],
      );
    }

    final value = _log.primaryMetric;
    if (value == null) {
      return Text('-', style: AppTextStyles.titleLarge.copyWith(fontSize: 48));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
        ),
        const SizedBox(width: 4),
        Text(
          _log.discipline.primaryUnit,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('테크닉', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        SurfaceCard(
          child: Column(
            children: [
              if (_log.mouthfillDepth != null)
                _buildInfoRow(
                  icon: Icons.expand_more,
                  label: '마우스필',
                  value: '${_log.mouthfillDepth!.toStringAsFixed(0)}m',
                ),
              if (_log.mouthfillDepth != null && _log.freefallDepth != null)
                _buildDivider(),
              if (_log.freefallDepth != null)
                _buildInfoRow(
                  icon: Icons.keyboard_double_arrow_down,
                  label: '프리폴',
                  value: '${_log.freefallDepth!.toStringAsFixed(0)}m',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상세 정보', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        SurfaceCard(
          child: Column(
            children: [
              if (_log.weight != null) ...[
                _buildInfoRow(
                  icon: Icons.fitness_center,
                  label: '웨이트',
                  value: '${_log.weight!.toStringAsFixed(1)}kg',
                ),
              ],
              if (_log.weight != null && (_log.condition != null || _log.contractions != null))
                _buildDivider(),
              if (_log.condition != null) ...[
                _buildInfoRow(
                  icon: Icons.monitor_heart_outlined,
                  label: '컨디션',
                  value: _log.condition!,
                ),
              ],
              if (_log.condition != null && _log.contractions != null)
                _buildDivider(),
              if (_log.contractions != null) ...[
                _buildInfoRow(
                  icon: Icons.waves,
                  label: '컨트랙션',
                  value: '${_log.contractions}회',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('메모', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        SurfaceCard(
          child: Text(
            _log.notes!,
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('미디어', style: AppTextStyles.sectionTitle),
            Text(
              '${_attachments.length}개',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final attachment = _attachments[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _attachments.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _showMediaViewer(attachment),
                  child: _buildMediaThumbnail(attachment),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaThumbnail(MediaAttachment attachment) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface2,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildThumbnailContent(attachment),
        ),
        if (attachment.type == MediaType.video)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailContent(MediaAttachment attachment) {
    final file = File(attachment.filePath);
    if (attachment.type == MediaType.photo) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(attachment),
      );
    } else {
      if (attachment.thumbnailPath != null) {
        return Image.file(
          File(attachment.thumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(attachment),
        );
      }
      return _buildPlaceholder(attachment);
    }
  }

  Widget _buildPlaceholder(MediaAttachment attachment) {
    return Container(
      color: AppColors.surface2,
      child: Center(
        child: Icon(
          attachment.type == MediaType.photo ? Icons.photo : Icons.videocam,
          color: AppColors.muted,
          size: 32,
        ),
      ),
    );
  }

  void _showMediaViewer(MediaAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MediaViewerScreen(attachment: attachment),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(height: 1, color: AppColors.line),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _deleteLog,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.coral.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  '삭제',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _editLog,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '수정하기',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaViewerScreen extends StatelessWidget {
  final MediaAttachment attachment;

  const _MediaViewerScreen({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: attachment.type == MediaType.photo
                  ? InteractiveViewer(
                      child: Image.file(
                        File(attachment.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam,
                          size: 64,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '비디오 재생은 준비 중입니다',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            if (attachment.comment != null && attachment.comment!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    attachment.comment!,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
