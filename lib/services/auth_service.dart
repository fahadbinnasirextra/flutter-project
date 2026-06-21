import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _cmsBase = 'https://cms.bahria.edu.pk';
  static const _lmsBase = 'https://lms.bahria.edu.pk';
  static const _storage = FlutterSecureStorage();

  String? cmsCookie;
  String? lmsCookie;

  Future<Map<String, dynamic>> login(String enrollment, String password) async {
    try {
      // Step 1: GET login page for VIEWSTATE
      final client = http.Client();
      final loginPageResp = await client.get(
        Uri.parse('$_cmsBase/Sys/Common/Login.aspx'),
      );
      final doc = html_parser.parse(loginPageResp.body);
      final viewState = doc.querySelector('#__VIEWSTATE')?.attributes['value'] ?? '';
      final viewStateGen = doc.querySelector('#__VIEWSTATEGENERATOR')?.attributes['value'] ?? '';
      final eventValidation = doc.querySelector('#__EVENTVALIDATION')?.attributes['value'] ?? '';
      final initialCookie = _parseCookie(loginPageResp.headers['set-cookie'] ?? '');

      // Step 2: POST login
      final loginResp = await client.post(
        Uri.parse('$_cmsBase/Sys/Common/Login.aspx'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': initialCookie,
        },
        body: {
          '__VIEWSTATE': viewState,
          '__VIEWSTATEGENERATOR': viewStateGen,
          '__EVENTVALIDATION': eventValidation,
          '__EVENTTARGET': '',
          'ctl00\$BodyPH\$tbEnrollment': enrollment,
          'ctl00\$BodyPH\$tbPassword': password,
          'ctl00\$BodyPH\$ddlInstituteID': '2',
          'ctl00\$BodyPH\$ddlSubUserType': 'None',
          'ctl00\$hfJsEnabled': '0',
          'ctl00\$BodyPH\$btnLogin': 'Login',
        },
      );

      if (!loginResp.body.contains('Dashboard') && loginResp.statusCode != 302) {
        return {'success': false, 'message': 'Invalid credentials'};
      }

      cmsCookie = _parseCookie(loginResp.headers['set-cookie'] ?? initialCookie);

      // Step 3: GoToLMS
      final lmsRedirectResp = await client.get(
        Uri.parse('$_cmsBase/Sys/Common/GoToLMS.aspx'),
        headers: {'Cookie': cmsCookie!},
      );

      // Step 4: Follow auth.php?C= link
      String? authUrl = lmsRedirectResp.headers['location'];
      if (authUrl == null && lmsRedirectResp.body.contains('auth.php')) {
        final match = RegExp(r'auth\.php\?C=[a-zA-Z0-9]+').firstMatch(lmsRedirectResp.body);
        if (match != null) authUrl = '$_lmsBase/${match.group(0)}';
      }
      if (authUrl != null) {
        if (!authUrl.startsWith('http')) authUrl = '$_lmsBase/$authUrl';
        final lmsResp = await client.get(Uri.parse(authUrl));
        lmsCookie = _parseCookie(lmsResp.headers['set-cookie'] ?? '');
      }

      // Save session
      await _storage.write(key: 'cms_cookie', value: cmsCookie);
      await _storage.write(key: 'lms_cookie', value: lmsCookie);
      await _storage.write(key: 'enrollment', value: enrollment);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('enrollment', enrollment);

      client.close();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> loadSession() async {
    cmsCookie = await _storage.read(key: 'cms_cookie');
    lmsCookie = await _storage.read(key: 'lms_cookie');
    return cmsCookie != null && lmsCookie != null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String _parseCookie(String raw) {
    return raw.split(',').map((c) => c.split(';').first.trim()).join('; ');
  }
}
