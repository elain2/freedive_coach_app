import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Garmin Connect 비공식 API 서비스
/// 주의: 비공식 API이므로 언제든지 변경될 수 있습니다.
class GarminService {
  static const String _baseUrl = 'https://connect.garmin.com';
  static const String _ssoUrl = 'https://sso.garmin.com/sso';
  static const String _modernUrl = 'https://connect.garmin.com/modern';

  static const String _prefsKeyToken = 'garmin_oauth_token';
  static const String _prefsKeyUsername = 'garmin_username';

  String? _oauthToken;
  final http.Client _client = http.Client();

  /// 저장된 로그인 정보 확인
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _oauthToken = prefs.getString(_prefsKeyToken);
    return _oauthToken != null;
  }

  /// 저장된 사용자명 가져오기
  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyUsername);
  }

  /// Garmin Connect 로그인
  Future<GarminLoginResult> login(String username, String password) async {
    try {
      // Step 1: SSO 로그인 페이지 요청하여 CSRF 토큰 획득
      final ssoParams = {
        'service': _modernUrl,
        'webhost': _baseUrl,
        'source': _modernUrl,
        'redirectAfterAccountLoginUrl': _modernUrl,
        'redirectAfterAccountCreationUrl': _modernUrl,
        'gauthHost': _ssoUrl,
        'locale': 'ko_KR',
        'id': 'gauth-widget',
        'cssUrl': 'https://static.garmincdn.com/com.garmin.connect/ui/css/gauth-custom-v1.2-min.css',
        'clientId': 'GarminConnect',
        'rememberMeShown': 'true',
        'rememberMeChecked': 'false',
        'createAccountShown': 'true',
        'openCreateAccount': 'false',
        'displayNameShown': 'false',
        'consumeServiceTicket': 'false',
        'initialFocus': 'true',
        'embedWidget': 'false',
        'generateExtraServiceTicket': 'true',
        'generateTwoExtraServiceTickets': 'false',
        'generateNoServiceTicket': 'false',
        'globalOptInShown': 'true',
        'globalOptInChecked': 'false',
        'mobile': 'false',
        'connectLegalTerms': 'true',
        'locationPromptShown': 'true',
        'showPassword': 'true',
      };

      final ssoUri = Uri.parse('$_ssoUrl/signin').replace(queryParameters: ssoParams);

      final ssoResponse = await _client.get(
        ssoUri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (ssoResponse.statusCode != 200) {
        return GarminLoginResult.failure('SSO 페이지 접근 실패: ${ssoResponse.statusCode}');
      }

      // CSRF 토큰 추출
      final csrfMatch = RegExp(r'name="_csrf"\s+value="([^"]+)"').firstMatch(ssoResponse.body);
      final csrf = csrfMatch?.group(1);

      if (csrf == null) {
        return GarminLoginResult.failure('CSRF 토큰을 찾을 수 없습니다');
      }

      // 쿠키 추출
      final cookies = ssoResponse.headers['set-cookie'] ?? '';

      // Step 2: 로그인 요청
      final loginResponse = await _client.post(
        Uri.parse('$_ssoUrl/signin'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookies,
          'Origin': 'https://sso.garmin.com',
          'Referer': ssoUri.toString(),
        },
        body: {
          'username': username,
          'password': password,
          '_csrf': csrf,
          'embed': 'false',
        },
      );

      // 로그인 성공 시 티켓 URL로 리다이렉트
      if (loginResponse.statusCode == 200) {
        final ticketMatch = RegExp(r'ticket=([^"]+)"').firstMatch(loginResponse.body);
        final ticket = ticketMatch?.group(1);

        if (ticket != null) {
          // Step 3: 티켓으로 OAuth 토큰 획득
          final tokenResponse = await _client.get(
            Uri.parse('$_modernUrl/?ticket=$ticket'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            },
          );

          final tokenCookies = tokenResponse.headers['set-cookie'] ?? '';
          final oauthMatch = RegExp(r'GARMIN-SSO-GUID=([^;]+)').firstMatch(tokenCookies);

          if (oauthMatch != null) {
            _oauthToken = oauthMatch.group(1);

            // 토큰 저장
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefsKeyToken, _oauthToken!);
            await prefs.setString(_prefsKeyUsername, username);

            return GarminLoginResult.success();
          }
        }

        // 로그인 실패 메시지 확인
        if (loginResponse.body.contains('locked')) {
          return GarminLoginResult.failure('계정이 잠겼습니다. Garmin 웹사이트에서 확인해주세요.');
        }
        if (loginResponse.body.contains('error')) {
          return GarminLoginResult.failure('아이디 또는 비밀번호가 올바르지 않습니다.');
        }
      }

      return GarminLoginResult.failure('로그인에 실패했습니다. 다시 시도해주세요.');
    } catch (e) {
      return GarminLoginResult.failure('네트워크 오류: $e');
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyToken);
    await prefs.remove(_prefsKeyUsername);
    _oauthToken = null;
  }

  /// 다이빙 활동 목록 가져오기
  Future<GarminActivitiesResult> getDiveActivities({int limit = 20, int start = 0}) async {
    if (_oauthToken == null) {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return GarminActivitiesResult.failure('로그인이 필요합니다');
      }
    }

    try {
      // 다이빙 관련 활동 타입으로 필터링
      // Garmin 활동 타입: freediving, diving, apnea_diving
      final response = await _client.get(
        Uri.parse('$_modernUrl/proxy/activitylist-service/activities/search/activities'
            '?limit=$limit&start=$start&activityType=freediving,diving,apnea_diving,apnea_hunting'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Cookie': 'GARMIN-SSO-GUID=$_oauthToken',
          'Accept': 'application/json',
          'NK': 'NT',
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        return GarminActivitiesResult.failure('세션이 만료되었습니다. 다시 로그인해주세요.');
      }

      if (response.statusCode != 200) {
        return GarminActivitiesResult.failure('활동 목록 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      final activities = data.map((item) => GarminDiveActivity.fromJson(item)).toList();

      return GarminActivitiesResult.success(activities);
    } catch (e) {
      return GarminActivitiesResult.failure('데이터 조회 오류: $e');
    }
  }

  /// 특정 활동의 상세 정보 가져오기
  Future<GarminActivityDetailResult> getActivityDetail(String activityId) async {
    if (_oauthToken == null) {
      return GarminActivityDetailResult.failure('로그인이 필요합니다');
    }

    try {
      final response = await _client.get(
        Uri.parse('$_modernUrl/proxy/activity-service/activity/$activityId'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Cookie': 'GARMIN-SSO-GUID=$_oauthToken',
          'Accept': 'application/json',
          'NK': 'NT',
        },
      );

      if (response.statusCode != 200) {
        return GarminActivityDetailResult.failure('상세 정보 조회 실패');
      }

      final data = jsonDecode(response.body);
      return GarminActivityDetailResult.success(data);
    } catch (e) {
      return GarminActivityDetailResult.failure('데이터 조회 오류: $e');
    }
  }

  /// 모든 활동 가져오기 (다이빙 타입 없이)
  Future<GarminActivitiesResult> getAllActivities({int limit = 50, int start = 0}) async {
    if (_oauthToken == null) {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return GarminActivitiesResult.failure('로그인이 필요합니다');
      }
    }

    try {
      final response = await _client.get(
        Uri.parse('$_modernUrl/proxy/activitylist-service/activities/search/activities'
            '?limit=$limit&start=$start'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Cookie': 'GARMIN-SSO-GUID=$_oauthToken',
          'Accept': 'application/json',
          'NK': 'NT',
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        return GarminActivitiesResult.failure('세션이 만료되었습니다. 다시 로그인해주세요.');
      }

      if (response.statusCode != 200) {
        return GarminActivitiesResult.failure('활동 목록 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      final activities = data.map((item) => GarminDiveActivity.fromJson(item)).toList();

      // 다이빙 관련 활동만 필터링
      final diveActivities = activities.where((a) =>
        a.activityType.toLowerCase().contains('dive') ||
        a.activityType.toLowerCase().contains('diving') ||
        a.activityType.toLowerCase().contains('apnea') ||
        a.activityType.toLowerCase().contains('freediv')
      ).toList();

      return GarminActivitiesResult.success(diveActivities);
    } catch (e) {
      return GarminActivitiesResult.failure('데이터 조회 오류: $e');
    }
  }
}

/// 로그인 결과
class GarminLoginResult {
  final bool success;
  final String? error;

  GarminLoginResult._(this.success, this.error);

  factory GarminLoginResult.success() => GarminLoginResult._(true, null);
  factory GarminLoginResult.failure(String error) => GarminLoginResult._(false, error);
}

/// 활동 목록 조회 결과
class GarminActivitiesResult {
  final bool success;
  final List<GarminDiveActivity>? activities;
  final String? error;

  GarminActivitiesResult._(this.success, this.activities, this.error);

  factory GarminActivitiesResult.success(List<GarminDiveActivity> activities) =>
      GarminActivitiesResult._(true, activities, null);
  factory GarminActivitiesResult.failure(String error) =>
      GarminActivitiesResult._(false, null, error);
}

/// 활동 상세 조회 결과
class GarminActivityDetailResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  GarminActivityDetailResult._(this.success, this.data, this.error);

  factory GarminActivityDetailResult.success(Map<String, dynamic> data) =>
      GarminActivityDetailResult._(true, data, null);
  factory GarminActivityDetailResult.failure(String error) =>
      GarminActivityDetailResult._(false, null, error);
}

/// Garmin 다이빙 활동 데이터
class GarminDiveActivity {
  final String activityId;
  final String activityName;
  final String activityType;
  final DateTime startTime;
  final Duration duration;
  final double? maxDepth; // meters
  final double? avgDepth;
  final double? waterTemperature;
  final int? diveCount;
  final String? locationName;

  GarminDiveActivity({
    required this.activityId,
    required this.activityName,
    required this.activityType,
    required this.startTime,
    required this.duration,
    this.maxDepth,
    this.avgDepth,
    this.waterTemperature,
    this.diveCount,
    this.locationName,
  });

  factory GarminDiveActivity.fromJson(Map<String, dynamic> json) {
    return GarminDiveActivity(
      activityId: json['activityId']?.toString() ?? '',
      activityName: json['activityName'] ?? '다이빙',
      activityType: json['activityType']?['typeKey'] ?? json['activityType'] ?? 'diving',
      startTime: DateTime.tryParse(json['startTimeLocal'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: (json['duration'] ?? 0).toInt()),
      maxDepth: _parseDouble(json['maxDepth']),
      avgDepth: _parseDouble(json['avgDepth']),
      waterTemperature: _parseDouble(json['waterTemperature']),
      diveCount: json['diveNumber'] ?? json['lapCount'],
      locationName: json['locationName'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
