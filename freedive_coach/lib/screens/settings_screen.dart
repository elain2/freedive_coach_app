import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/data_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'help_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _exportService = DataExportService();
  bool _useMetric = true;
  bool _notifications = true;
  bool _autoBackup = false;
  bool _isExporting = false;
  bool _isImporting = false;

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    _buildDataSection(),
                    const SizedBox(height: 24),
                    _buildInfoSection(),
                    const SizedBox(height: 40),
                    _buildVersionInfo(),
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
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.muted),
            ),
          ),
          Text('설정', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('프로필', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.person_outline,
                title: '닉네임',
                value: '다이버님',
                onTap: () => _showEditDialog('닉네임', '다이버님'),
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.card_membership,
                title: '자격증',
                value: 'AIDA 2',
                onTap: () => _showCertificationPicker(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('환경설정', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildToggleItem(
                icon: Icons.straighten,
                title: '단위',
                description: _useMetric ? '미터법 (m)' : '야드파운드법 (ft)',
                value: _useMetric,
                onChanged: (value) => setState(() => _useMetric = value),
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildToggleItem(
                icon: Icons.notifications_outlined,
                title: '알림',
                description: '훈련 리마인더 및 앱 알림',
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('데이터', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildToggleItem(
                icon: Icons.cloud_upload_outlined,
                title: '자동 백업',
                description: '로그 데이터를 자동으로 백업',
                value: _autoBackup,
                onChanged: (value) {
                  setState(() => _autoBackup = value);
                  if (value) {
                    _showSnackBar('자동 백업이 활성화되었습니다');
                  }
                },
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.download_outlined,
                title: '데이터 내보내기',
                value: _isExporting ? '내보내는 중...' : '',
                onTap: _isExporting ? null : () => _showExportOptions(),
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.upload_outlined,
                title: '데이터 가져오기',
                value: _isImporting ? '가져오는 중...' : '',
                onTap: _isImporting ? null : () => _showImportOptions(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('정보', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.help_outline,
                title: '도움말',
                value: '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.info_outline,
                title: '앱 정보',
                value: '',
                onTap: () => _showAboutDialog(),
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보 처리방침',
                value: '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(type: LegalType.privacy),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: '이용약관',
                value: '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(type: LegalType.terms),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: AppTextStyles.body),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'Freedive Coach',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$title 변경', style: AppTextStyles.titleSmall),
        content: TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: '$title 입력',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('$title이(가) 변경되었습니다');
            },
            child: Text('저장', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showCertificationPicker() {
    final certifications = [
      'AIDA 1',
      'AIDA 2',
      'AIDA 3',
      'AIDA 4',
      'SSI Level 1',
      'SSI Level 2',
      'SSI Level 3',
      'PADI Basic',
      'PADI Advanced',
      '기타',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              Text('자격증 선택', style: AppTextStyles.titleSmall),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: certifications.map((cert) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('자격증이 $cert(으)로 변경되었습니다');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(cert, style: AppTextStyles.bodySmall),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              Text('데이터 내보내기', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              Text(
                '내보내기 형식을 선택하세요',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                Icons.code,
                'JSON (전체 백업)',
                '모든 데이터를 JSON 형식으로 내보냅니다',
                () async {
                  Navigator.pop(context);
                  await _exportJson();
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                Icons.table_chart,
                'CSV (다이빙 로그)',
                '다이빙 로그만 CSV 형식으로 내보냅니다',
                () async {
                  Navigator.pop(context);
                  await _exportCSV();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tealDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryBright),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);
    try {
      await _exportService.shareJsonExport();
      _showSnackBar('데이터가 성공적으로 내보내졌습니다');
    } catch (e) {
      _showSnackBar('내보내기 실패: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    try {
      await _exportService.shareCSVExport();
      _showSnackBar('CSV가 성공적으로 내보내졌습니다');
    } catch (e) {
      _showSnackBar('내보내기 실패: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              Text('데이터 가져오기', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              Text(
                'JSON 백업 파일을 선택하세요',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _importJson();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.tealDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder_open, size: 20, color: AppColors.primaryBright),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('파일 선택', style: AppTextStyles.body),
                            const SizedBox(height: 2),
                            Text(
                              'JSON 백업 파일을 선택합니다',
                              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '기존 데이터와 병합됩니다. 중복된 항목은 덮어씁니다.',
                style: AppTextStyles.caption.copyWith(color: AppColors.coral),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importJson() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final content = await file.readAsString();

        final importResult = await _exportService.importFromJson(content);

        if (importResult.success) {
          _showSnackBar(
            '가져오기 완료: 로그 ${importResult.logsImported}개, '
            '훈련 ${importResult.trainingsImported}개, '
            '분석 ${importResult.analysesImported}개',
          );
        } else {
          _showSnackBar('가져오기 실패: ${importResult.error}');
        }
      }
    } catch (e) {
      _showSnackBar('가져오기 실패: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tealDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('\u{1F431}', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Freedive Coach', style: AppTextStyles.titleSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '프리다이빙 훈련 & 로그 앱',
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text('버전: 1.0.0', style: AppTextStyles.bodySmall),
            Text('빌드: 2024.01', style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            Text(
              '© 2024 Freedive Coach',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
