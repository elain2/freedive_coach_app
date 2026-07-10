import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../models/media_attachment.dart';
import '../services/ai_parsing_service.dart';
import '../services/log_storage.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';
import '../services/text_parsing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/discipline_selector.dart';
import '../widgets/media_picker.dart';

class NewLogScreen extends StatefulWidget {
  final DiveLog? existingLog;

  const NewLogScreen({super.key, this.existingLog});

  @override
  State<NewLogScreen> createState() => _NewLogScreenState();
}

class _NewLogScreenState extends State<NewLogScreen> {
  final _logStorage = LogStorage();
  final _mediaService = MediaService();
  final _textParsingService = TextParsingService();
  final _speechService = SpeechService();
  final _aiParsingService = AIParsingService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _diveDate;
  late Discipline _discipline;
  final _locationController = TextEditingController();
  final _depthController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationMinController = TextEditingController();
  final _durationSecController = TextEditingController();
  final _mouthfillController = TextEditingController();
  final _freefallController = TextEditingController();
  final _weightController = TextEditingController();
  final _conditionController = TextEditingController();
  final _notesController = TextEditingController();
  final _quickInputController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isQuickInputMode = true;
  bool _isListening = false;
  bool _isAIParsing = false;

  // Media state
  List<MediaAttachment> _existingAttachments = [];
  List<XFile> _newMediaFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _isEditing = true;
      _isQuickInputMode = false;
      _diveDate = log.diveDate;
      _discipline = log.discipline;
      _locationController.text = log.location ?? '';
      if (log.depth != null) _depthController.text = log.depth!.toStringAsFixed(0);
      if (log.distance != null) _distanceController.text = log.distance!.toStringAsFixed(0);
      if (log.duration != null) {
        _durationMinController.text = log.duration!.inMinutes.toString();
        _durationSecController.text = (log.duration!.inSeconds % 60).toString();
      }
      if (log.mouthfillDepth != null) _mouthfillController.text = log.mouthfillDepth!.toStringAsFixed(0);
      if (log.freefallDepth != null) _freefallController.text = log.freefallDepth!.toStringAsFixed(0);
      if (log.weight != null) _weightController.text = log.weight!.toStringAsFixed(1);
      _conditionController.text = log.condition ?? '';
      _notesController.text = log.notes ?? '';
      _loadExistingAttachments();
    } else {
      _diveDate = DateTime.now();
      _discipline = Discipline.cwt;
    }
  }

  Future<void> _loadExistingAttachments() async {
    if (widget.existingLog != null) {
      final attachments = await _mediaService.getAttachments(widget.existingLog!.id);
      if (mounted) {
        setState(() => _existingAttachments = attachments);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _depthController.dispose();
    _distanceController.dispose();
    _durationMinController.dispose();
    _durationSecController.dispose();
    _mouthfillController.dispose();
    _freefallController.dispose();
    _weightController.dispose();
    _conditionController.dispose();
    _notesController.dispose();
    _quickInputController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _diveDate = picked);
    }
  }

  Future<void> _saveLog() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      Duration? duration;
      final minStr = _durationMinController.text.trim();
      final secStr = _durationSecController.text.trim();
      if (minStr.isNotEmpty || secStr.isNotEmpty) {
        final minutes = int.tryParse(minStr) ?? 0;
        final seconds = int.tryParse(secStr) ?? 0;
        duration = Duration(minutes: minutes, seconds: seconds);
      }

      final log = _isEditing
          ? widget.existingLog!.copyWith(
              diveDate: _diveDate,
              discipline: _discipline,
              location: _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
              depth: double.tryParse(_depthController.text),
              distance: double.tryParse(_distanceController.text),
              duration: duration,
              mouthfillDepth: double.tryParse(_mouthfillController.text),
              freefallDepth: double.tryParse(_freefallController.text),
              weight: double.tryParse(_weightController.text),
              condition: _conditionController.text.trim().isNotEmpty
                  ? _conditionController.text.trim()
                  : null,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              rawInput: _quickInputController.text.trim().isNotEmpty
                  ? _quickInputController.text.trim()
                  : null,
            )
          : DiveLog.create(
              diveDate: _diveDate,
              discipline: _discipline,
              location: _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
              depth: double.tryParse(_depthController.text),
              distance: double.tryParse(_distanceController.text),
              duration: duration,
              mouthfillDepth: double.tryParse(_mouthfillController.text),
              freefallDepth: double.tryParse(_freefallController.text),
              weight: double.tryParse(_weightController.text),
              condition: _conditionController.text.trim().isNotEmpty
                  ? _conditionController.text.trim()
                  : null,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              rawInput: _quickInputController.text.trim().isNotEmpty
                  ? _quickInputController.text.trim()
                  : null,
            );

      await _logStorage.saveLog(log);

      // Save new media attachments
      for (final file in _newMediaFiles) {
        final savedPath = await _mediaService.saveMediaFile(file.path, log.id);
        final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
            file.path.toLowerCase().endsWith('.mov') ||
            file.path.toLowerCase().endsWith('.avi');
        await _mediaService.addAttachment(
          logId: log.id,
          type: isVideo ? MediaType.video : MediaType.photo,
          filePath: savedPath,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _parseQuickInput() {
    final text = _quickInputController.text.trim();
    if (text.isEmpty) return;

    final parsed = _textParsingService.parseText(text);

    setState(() {
      if (parsed.discipline != null) {
        _discipline = parsed.discipline!;
      }
      if (parsed.location != null) {
        _locationController.text = parsed.location!;
      }
      if (parsed.depth != null) {
        _depthController.text = parsed.depth!.toStringAsFixed(0);
      }
      if (parsed.distance != null) {
        _distanceController.text = parsed.distance!.toStringAsFixed(0);
      }
      if (parsed.duration != null) {
        _durationMinController.text = parsed.duration!.inMinutes.toString();
        final secs = parsed.duration!.inSeconds % 60;
        if (secs > 0) {
          _durationSecController.text = secs.toString();
        }
      }
      if (parsed.mouthfillDepth != null) {
        _mouthfillController.text = parsed.mouthfillDepth!.toStringAsFixed(0);
      }
      if (parsed.freefallDepth != null) {
        _freefallController.text = parsed.freefallDepth!.toStringAsFixed(0);
      }
      if (parsed.condition != null) {
        _conditionController.text = parsed.condition!;
      }
      if (parsed.date != null) {
        _diveDate = parsed.date!;
      }

      // Switch to detail mode after parsing
      _isQuickInputMode = false;
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      final initialized = await _speechService.initialize();
      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('음성 인식을 사용할 수 없습니다')),
          );
        }
        return;
      }

      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _quickInputController.text = text;
          });
        },
        onListeningStarted: () {
          setState(() => _isListening = true);
        },
        onListeningStopped: () {
          setState(() => _isListening = false);
        },
      );
    }
  }

  Future<void> _parseWithAI() async {
    final text = _quickInputController.text.trim();
    if (text.isEmpty) return;

    if (!_aiParsingService.isConfigured) {
      // Fallback to local parsing
      _parseQuickInput();
      return;
    }

    setState(() => _isAIParsing = true);

    try {
      final parsed = await _aiParsingService.parseLogInput(text);

      if (parsed.hasAnyData) {
        setState(() {
          if (parsed.discipline != null) {
            _discipline = parsed.discipline!;
          }
          if (parsed.location != null) {
            _locationController.text = parsed.location!;
          }
          if (parsed.depth != null) {
            _depthController.text = parsed.depth!.toStringAsFixed(0);
          }
          if (parsed.distance != null) {
            _distanceController.text = parsed.distance!.toStringAsFixed(0);
          }
          if (parsed.duration != null) {
            _durationMinController.text = parsed.duration!.inMinutes.toString();
            final secs = parsed.duration!.inSeconds % 60;
            if (secs > 0) {
              _durationSecController.text = secs.toString();
            }
          }
          if (parsed.mouthfillDepth != null) {
            _mouthfillController.text = parsed.mouthfillDepth!.toStringAsFixed(0);
          }
          if (parsed.freefallDepth != null) {
            _freefallController.text = parsed.freefallDepth!.toStringAsFixed(0);
          }
          if (parsed.weight != null) {
            _weightController.text = parsed.weight!.toStringAsFixed(1);
          }
          if (parsed.condition != null) {
            _conditionController.text = parsed.condition!;
          }
          if (parsed.notes != null) {
            _notesController.text = parsed.notes!;
          }
          if (parsed.date != null) {
            _diveDate = parsed.date!;
          }

          _isQuickInputMode = false;
        });
      } else {
        // Fallback to local parsing
        _parseQuickInput();
      }
    } catch (e) {
      // Fallback to local parsing on error
      _parseQuickInput();
    } finally {
      if (mounted) {
        setState(() => _isAIParsing = false);
      }
    }
  }

  void _onMediaAdded(List<XFile> files) {
    setState(() {
      _newMediaFiles.addAll(files);
    });
  }

  void _onNewMediaRemoved(int index) {
    setState(() {
      _newMediaFiles.removeAt(index);
    });
  }

  Future<void> _onExistingMediaRemoved(String attachmentId) async {
    final attachment = _existingAttachments.firstWhere((a) => a.id == attachmentId);
    await _mediaService.deleteMediaFile(attachment.filePath);
    if (attachment.thumbnailPath != null) {
      await _mediaService.deleteMediaFile(attachment.thumbnailPath!);
    }
    await _mediaService.deleteAttachment(attachmentId);
    setState(() {
      _existingAttachments.removeWhere((a) => a.id == attachmentId);
    });
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isEditing) ...[
                        _buildQuickInputSection(),
                        const SizedBox(height: 20),
                      ],
                      if (!_isQuickInputMode || _isEditing) ...[
                        _buildDateSection(),
                        const SizedBox(height: 20),
                        _buildDisciplineSection(),
                        const SizedBox(height: 20),
                        _buildFieldsSection(),
                        const SizedBox(height: 20),
                        _buildTechniqueSection(),
                        const SizedBox(height: 20),
                        _buildDetailsSection(),
                        const SizedBox(height: 20),
                        _buildMediaSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ),
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
          Text(
            _isEditing ? '로그 수정' : '새 로그',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.muted),
            const SizedBox(width: 10),
            Text('날짜', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
            const Spacer(),
            Text(
              '${_diveDate.year}년 ${_diveDate.month}월 ${_diveDate.day}일',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('종목', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        DisciplineSelector(
          selected: _discipline,
          onSelected: (discipline) {
            setState(() => _discipline = discipline);
          },
        ),
      ],
    );
  }

  Widget _buildFieldsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _buildTextFieldRow(
            label: '장소',
            icon: Icons.location_on_outlined,
            controller: _locationController,
            hint: '예: 제주 서귀포',
          ),
          _buildDivider(),
          if (_discipline.isDepthDiscipline) ...[
            _buildTextFieldRow(
              label: '수심',
              icon: Icons.arrow_downward,
              controller: _depthController,
              hint: '0',
              suffix: 'm',
              keyboardType: TextInputType.number,
            ),
          ] else if (_discipline.isDistanceDiscipline) ...[
            _buildTextFieldRow(
              label: '거리',
              icon: Icons.straighten,
              controller: _distanceController,
              hint: '0',
              suffix: 'm',
              keyboardType: TextInputType.number,
            ),
          ],
          if (!_discipline.isTimeDiscipline) _buildDivider(),
          _buildDurationRow(),
        ],
      ),
    );
  }

  Widget _buildTechniqueSection() {
    if (!_discipline.isDepthDiscipline) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('테크닉', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildTextFieldRow(
                label: '마우스필',
                icon: Icons.expand_more,
                controller: _mouthfillController,
                hint: '0',
                suffix: 'm',
                keyboardType: TextInputType.number,
              ),
              _buildDivider(),
              _buildTextFieldRow(
                label: '프리폴',
                icon: Icons.keyboard_double_arrow_down,
                controller: _freefallController,
                hint: '0',
                suffix: 'm',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상세 정보', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildTextFieldRow(
                label: '웨이트',
                icon: Icons.fitness_center,
                controller: _weightController,
                hint: '0',
                suffix: 'kg',
                keyboardType: TextInputType.number,
              ),
              _buildDivider(),
              _buildTextFieldRow(
                label: '컨디션',
                icon: Icons.monitor_heart_outlined,
                controller: _conditionController,
                hint: '예: 귀 타이트',
              ),
              _buildDivider(),
              _buildTextFieldRow(
                label: '메모',
                icon: Icons.notes,
                controller: _notesController,
                hint: '자유롭게 메모',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('빠른 입력', style: AppTextStyles.sectionTitle),
            if (_isQuickInputMode)
              GestureDetector(
                onTap: () => setState(() => _isQuickInputMode = false),
                child: Text(
                  '상세 입력',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(
              color: _isListening ? AppColors.primary : AppColors.line,
              width: _isListening ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickInputController,
                        maxLines: 3,
                        style: AppTextStyles.bodySmall,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? '말씀하세요...'
                              : '예: 오늘 제주에서 CWT 32m 성공, 마우스필 28m',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: _isListening
                                ? AppColors.primary
                                : AppColors.muted.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleVoiceInput,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.primary : AppColors.tealDim,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isListening) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '녹음 중...',
                        style: AppTextStyles.caption.copyWith(color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
              ],
              Container(height: 1, color: AppColors.line),
              GestureDetector(
                onTap: _isAIParsing ? null : _parseWithAI,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isAIParsing) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI 분석 중...',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ] else ...[
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _aiParsingService.isConfigured ? 'AI 파싱' : '자동 파싱',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isQuickInputMode) ...[
          const SizedBox(height: 12),
          Text(
            _aiParsingService.isConfigured
                ? '텍스트 또는 음성으로 입력하면 AI가 자동으로 파싱합니다.'
                : '텍스트를 입력하고 자동 파싱을 누르면 필드가 자동으로 채워집니다.',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaPicker(
          attachments: _existingAttachments,
          onMediaAdded: _onMediaAdded,
          onMediaRemoved: _onExistingMediaRemoved,
        ),
        if (_newMediaFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '새로 추가된 미디어',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          MediaPreviewList(
            files: _newMediaFiles,
            onRemove: _onNewMediaRemoved,
          ),
        ],
      ],
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted.withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Text(suffix, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              '시간',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _durationMinController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted.withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Text('분', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _durationSecController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted.withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Text('초', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: AppColors.line),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveLog,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _isSaving ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '저장하기',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
