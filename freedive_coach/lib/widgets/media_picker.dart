import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_attachment.dart';
import '../theme/app_theme.dart';

/// Widget for picking and displaying media attachments
class MediaPicker extends StatelessWidget {
  final List<MediaAttachment> attachments;
  final ValueChanged<List<XFile>> onMediaAdded;
  final ValueChanged<String>? onMediaRemoved;
  final int maxAttachments;

  const MediaPicker({
    super.key,
    required this.attachments,
    required this.onMediaAdded,
    this.onMediaRemoved,
    this.maxAttachments = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('미디어', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...attachments.map((attachment) => _MediaThumbnail(
                attachment: attachment,
                onRemove: onMediaRemoved != null
                    ? () => onMediaRemoved!(attachment.id)
                    : null,
              )),
              if (attachments.length < maxAttachments)
                _AddMediaButton(onTap: () => _showMediaOptions(context)),
            ],
          ),
        ),
      ],
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MediaOptionsSheet(
        onOptionSelected: (source, isVideo) async {
          Navigator.pop(context);
          await _pickMedia(source, isVideo);
        },
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();

    try {
      if (isVideo) {
        final video = await picker.pickVideo(source: source);
        if (video != null) {
          onMediaAdded([video]);
        }
      } else {
        if (source == ImageSource.gallery) {
          final images = await picker.pickMultiImage();
          if (images.isNotEmpty) {
            final remaining = maxAttachments - attachments.length;
            onMediaAdded(images.take(remaining).toList());
          }
        } else {
          final image = await picker.pickImage(source: source);
          if (image != null) {
            onMediaAdded([image]);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }
}

class _MediaThumbnail extends StatelessWidget {
  final MediaAttachment attachment;
  final VoidCallback? onRemove;

  const _MediaThumbnail({
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface2,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (attachment.type == MediaType.video)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final file = File(attachment.filePath);
    if (attachment.type == MediaType.photo) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      // Video thumbnail
      if (attachment.thumbnailPath != null) {
        return Image.file(
          File(attachment.thumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface2,
      child: Icon(
        attachment.type == MediaType.photo ? Icons.photo : Icons.videocam,
        color: AppColors.muted,
        size: 24,
      ),
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMediaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: const Icon(
          Icons.add,
          size: 24,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _MediaOptionsSheet extends StatelessWidget {
  final Function(ImageSource source, bool isVideo) onOptionSelected;

  const _MediaOptionsSheet({required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('미디어 추가', style: AppTextStyles.titleSmall),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OptionButton(
                  icon: Icons.photo_library,
                  label: '갤러리',
                  onTap: () => onOptionSelected(ImageSource.gallery, false),
                ),
                _OptionButton(
                  icon: Icons.camera_alt,
                  label: '사진 촬영',
                  onTap: () => onOptionSelected(ImageSource.camera, false),
                ),
                _OptionButton(
                  icon: Icons.videocam,
                  label: '동영상',
                  onTap: () => onOptionSelected(ImageSource.gallery, true),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryBright),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

/// Preview widget for newly selected media (before saving)
class MediaPreviewList extends StatelessWidget {
  final List<XFile> files;
  final ValueChanged<int>? onRemove;

  const MediaPreviewList({
    super.key,
    required this.files,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface2,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface2,
                      child: const Icon(
                        Icons.photo,
                        color: AppColors.muted,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove!(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
