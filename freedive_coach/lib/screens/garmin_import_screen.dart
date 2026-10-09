import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/garmin_service.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class GarminImportScreen extends StatefulWidget {
  const GarminImportScreen({super.key});

  @override
  State<GarminImportScreen> createState() => _GarminImportScreenState();
}

class _GarminImportScreenState extends State<GarminImportScreen> {
  final _garminService = GarminService();
  final _logStorage = LogStorage();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isLoggingIn = false;
  bool _isImporting = false;
  bool _showPassword = false;
  String? _savedUsername;
  String? _errorMessage;
  List<GarminDiveActivity> _activities = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _garminService.isLoggedIn();
    final username = await _garminService.getSavedUsername();

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _savedUsername = username;
        _isLoading = false;
      });

      if (loggedIn) {
        _loadActivities();
      }
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '아이디와 비밀번호를 입력해주세요');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    final result = await _garminService.login(username, password);

    if (mounted) {
      setState(() => _isLoggingIn = false);

      if (result.success) {
        setState(() {
          _isLoggedIn = true;
          _savedUsername = username;
        });
        _passwordController.clear();
        _loadActivities();
      } else {
        setState(() => _errorMessage = result.error);
      }
    }
  }

  Future<void> _logout() async {
    await _garminService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _savedUsername = null;
        _activities = [];
        _selectedIds.clear();
      });
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 먼저 다이빙 활동 조회 시도
    var result = await _garminService.getDiveActivities(limit: 50);

    // 다이빙 활동이 없으면 전체 활동에서 필터링
    if (result.success && (result.activities?.isEmpty ?? true)) {
      result = await _garminService.getAllActivities(limit: 100);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _activities = result.activities ?? [];
          if (_activities.isEmpty) {
            _errorMessage = '다이빙 활동을 찾을 수 없습니다.\nGarmin에 프리다이빙/다이빙 활동이 기록되어 있는지 확인해주세요.';
          }
        } else {
          _errorMessage = result.error;
        }
      });
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가져올 활동을 선택해주세요')),
      );
      return;
    }

    setState(() => _isImporting = true);

    int imported = 0;
    for (final activity in _activities) {
      if (_selectedIds.contains(activity.activityId)) {
        // 활동 유형에 따라 종목 결정
        final discipline = activity.maxDepth != null && activity.maxDepth! > 0
            ? Discipline.cwt  // 깊이가 있으면 CWT로 기본 설정
            : Discipline.sta; // 깊이가 없으면 STA로 설정

        final log = DiveLog.create(
          diveDate: activity.startTime,
          discipline: discipline,
          depth: activity.maxDepth,
          duration: activity.duration,
          location: activity.locationName,
          notes: '${activity.activityName}\n(Garmin에서 가져옴)',
        );

        await _logStorage.saveLog(log);
        imported++;
      }
    }

    if (mounted) {
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported개의 다이빙 로그를 가져왔습니다')),
      );

      Navigator.of(context).pop(true);
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _isLoggedIn
                      ? _buildActivityList()
                      : _buildLoginForm(),
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
          Column(
            children: [
              Text('Garmin 연동', style: AppTextStyles.titleSmall),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '실험실',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (_isLoggedIn)
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '로그아웃',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ),
            )
          else
            const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWarningBanner(),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.tealDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.watch,
                        color: AppColors.primaryBright,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Garmin Connect 로그인', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Garmin 계정으로 로그인하여 다이빙 기록을 가져오세요',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  style: AppTextStyles.body,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일 또는 사용자명',
                    labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: AppTextStyles.body,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.coral, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoggingIn ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bg,
                            ),
                          )
                        : const Text('로그인'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science, color: AppColors.coral, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '실험실 기능',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '이 기능은 비공식 API를 사용합니다. Garmin 정책 변경에 따라 작동하지 않을 수 있습니다.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.coral),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('알아두세요', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.security, '로그인 정보는 기기에만 저장됩니다'),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.sync, '프리다이빙/다이빙 활동만 가져올 수 있습니다'),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.watch, 'Garmin 다이브 워치가 필요합니다'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        if (_savedUsername != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _savedUsername!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _loadActivities,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
          )
        else if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.scuba_diving, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  '다이빙 활동이 없습니다',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '다이빙 활동 ${_activities.length}개',
                  style: AppTextStyles.sectionTitle,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _activities.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.clear();
                        _selectedIds.addAll(_activities.map((a) => a.activityId));
                      }
                    });
                  },
                  child: Text(
                    _selectedIds.length == _activities.length ? '선택 해제' : '전체 선택',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: _activities.length,
              itemBuilder: (context, index) => _buildActivityItem(_activities[index]),
            ),
          ),
        ],
        if (_activities.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isImporting || _selectedIds.isEmpty ? null : _importSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bg,
                    disabledBackgroundColor: AppColors.surface2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bg,
                          ),
                        )
                      : Text('${_selectedIds.length}개 가져오기'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(GarminDiveActivity activity) {
    final isSelected = _selectedIds.contains(activity.activityId);
    final dateStr = '${activity.startTime.year}.${activity.startTime.month.toString().padLeft(2, '0')}.${activity.startTime.day.toString().padLeft(2, '0')}';
    final durationStr = '${activity.duration.inMinutes}분 ${activity.duration.inSeconds % 60}초';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(activity.activityId);
          } else {
            _selectedIds.add(activity.activityId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? null : Border.all(color: AppColors.line),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.bg)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.activityName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                      if (activity.locationName != null) ...[
                        Text(' · ', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                        Expanded(
                          child: Text(
                            activity.locationName!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (activity.maxDepth != null)
                  Text(
                    '${activity.maxDepth!.toStringAsFixed(1)}m',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  durationStr,
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
