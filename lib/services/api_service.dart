import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:mifinper/models/profile.dart';
import 'package:mifinper/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../core/enums.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Static cache to persist across instances during the same session
  static List<dynamic>? _cachedProfiles;
  static String? _selectedProfileId;

  Future<void> logout() async {
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'sub');
    _cachedProfiles = null;
    _selectedProfileId = null;
    // Opcionalmente borrar credenciales guardadas si se desea forzar re-login manual
    // await _storage.delete(key: 'saved_email');
    // await _storage.delete(key: 'saved_password');
  }

  Future<bool> isBiometricSupported() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Autentícate para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final loginUrl = '${dotenv.env['API_ORCHESTRATOR_URL']}/auth/login';
    final payload = {
      'email': email,
      'password': password,
      'appId': dotenv.env['APLICATION_ID'],
    };

    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String? idToken = responseData['IdToken'];
      final String? sub = responseData['sub'];

      if (idToken != null && sub != null) {
        await _storage.write(key: 'idToken', value: idToken);
        await _storage.write(key: 'sub', value: sub);
        // Guardamos las credenciales para futuro login biométrico
        await _storage.write(key: 'saved_email', value: email);
        await _storage.write(key: 'saved_password', value: password);
      } else {
        throw Exception('Respuesta inválida del servidor.');
      }
    } else {
      throw Exception('Email o contraseña incorrectos.');
    }
  }

  Future<void> biometricLogin() async {
    final email = await _storage.read(key: 'saved_email');
    final password = await _storage.read(key: 'saved_password');

    if (email != null && password != null) {
      final authenticated = await authenticateWithBiometrics();
      if (authenticated) {
        await login(email, password);
      } else {
        throw Exception('Autenticación biométrica fallida o cancelada.');
      }
    } else {
      throw Exception('No hay credenciales guardadas para biometría.');
    }
  }

  Future<bool> canCheckBiometrics() async {
    final email = await _storage.read(key: 'saved_email');
    final password = await _storage.read(key: 'saved_password');
    if (email == null || password == null) return false;
    
    return await isBiometricSupported();
  }

  Future<List<dynamic>> fetchCountries() async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/countries'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load countries');
    }
  }

  Future<Map<String, dynamic>> fetchCountryById(String id) async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/countries/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load country');
    }
  }

  Future<List<dynamic>> fetchLanguages() async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/languages'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load languages');
    }
  }

  Future<Map<String, dynamic>> fetchLanguageById(String id) async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/languages/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load language');
    }
  }

  Future<List<dynamic>> fetchCurrencies() async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/currencies'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load currencies');
    }
  }

  Future<Map<String, dynamic>> fetchCurrencyById(String id) async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/currencies/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load currency');
    }
  }

  Future<List<dynamic>> fetchTimezones() async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/timezones'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load timezones');
    }
  }

  Future<Map<String, dynamic>> fetchTimezoneById(String id) async {
    final idToken = await _storage.read(key: 'idToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/timezones/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load timezone');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String countryId,
    required String timeZoneId,
    required String languageId,
  }) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'country_id': countryId,
        'time_zone_id': timeZoneId,
        'language_id': languageId,
        'appId': dotenv.env['APLICATION_ID'],
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'message': 'Failed to register user'};
    }
  }

  Future<Map<String, dynamic>> confirmUser(
      String email, String confirmationCode) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/auth/confirm-user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'confirmationCode': confirmationCode,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'message': 'Failed to confirm user'};
    }
  }

  Future<Map<String, dynamic>> fetchProfileDetails(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final response = await http.get(
      Uri.parse('$apiOrchestratorUrl/profiles/$profileId'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile details');
    }
  }

  Future<Map<String, dynamic>> createProfile({
    required String name,
    required String email,
    required String countryId,
    required String currencyId,
    Map<String, dynamic>? extraData,
  }) async {
    final profileId = dotenv.env['SERVICE_PROFILE_ID'];
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/profiles/$profileId/children';

    final payload = {
      'name': name,
      'email': email,
      'type': ProfileType.person.name,
      'country_id': countryId,
      'currency_id': currencyId,
      if (extraData != null) ...extraData,
    };

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create profile');
    }
  }

  Future<Map<String, dynamic>> updateProfile(String profileId, Map<String, dynamic> profileData) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/profiles/$profileId';

    final response = await http.put(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(profileData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> fetchUser(String userId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/users/$userId';

    final response = await http.get(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to fetch user');
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/users/$userId';

    final response = await http.put(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update user');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/users';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create user');
    }
  }


  Future<Map<String, dynamic>> createRbac(
      String profileId, String userId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/profiles/$profileId/rbac';

    final payload = {
      'application_id': dotenv.env['APLICATION_ID'],
      'role_id': dotenv.env['ROLE_ID'],
      'user_id': userId,
    };

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create rbac');
    }
  }

  Future<List<dynamic>> fetchProfiles({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfiles != null) {
      return _cachedProfiles!;
    }

    final idToken = await _storage.read(key: 'idToken');
    final sub = await _storage.read(key: 'sub');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];

    final response = await http.get(
      Uri.parse('$apiOrchestratorUrl/profiles/rbacs/by-user?user_id=$sub'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> rbacs = jsonDecode(response.body);
      final Set<String> profileIds = rbacs.map((rbac) => rbac['profile_id'].toString()).toSet();
      final profileDetails = await Future.wait(
        profileIds.map<Future<Map<String, dynamic>>>((profileId) {
          return fetchProfileDetails(profileId);
        }).toList(),
      );
      _cachedProfiles = profileDetails;
      return profileDetails;
    } else {
      return [];
    }
  }

  void clearProfilesCache() {
    _cachedProfiles = null;
  }

  String? get selectedProfileId => _selectedProfileId;
  
  void setSelectedProfileId(String? id) {
    _selectedProfileId = id;
  }

  Future<List<dynamic>> fetchAccounts(String profileId, String? codeParent,
      {bool isOnlyParent = false, bool isOnlyFinal = false}) async {
    if (profileId.isEmpty) {
      return [];
    }
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final Map<String, String> queryParameters = {};

    if (codeParent != null && codeParent.isNotEmpty) {
      queryParameters['code_parent'] = codeParent;
    }
    if (isOnlyParent) {
      queryParameters['only_parent'] = 'true';
    }
    if (isOnlyFinal) {
      queryParameters['only_final'] = 'true';
    }

    final uri = Uri.parse('$apiPFUrl/profiles/$profileId/accounts').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load accounts');
    }
  }

  Future<Map<String, dynamic>> getAccountProfileDetails(
      String profileId, String accountId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final response = await http.get(
      Uri.parse('$apiPFUrl/profiles/$profileId/accounts/$accountId'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile details');
    }
  }

  Future<Map<String, dynamic>> initProfileAccounts(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];

    final response = await http.get(
      Uri.parse('$apiPFUrl/profiles/$profileId/accounts/init'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to initialize profile accounts');
    }
  }

  Future<Map<String, dynamic>> getAccountProfileDetailsByCode(
      String profileId, String accountCode) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    accountCode = accountCode.replaceAll(".", "-");
    final response = await http.get(
      Uri.parse('$apiPFUrl/profiles/$profileId/accounts/code/$accountCode'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile details');
    }
  }

  Future<Map<String, dynamic>> createAccount(
      String profileId, Map<String, dynamic> accountData) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint = '$apiPFUrl/profiles/$profileId/accounts';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(accountData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create account');
    }
  }

  Future<Map<String, dynamic>> editAccount(String profileId, String accountId,
      Map<String, dynamic> accountData) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint = '$apiPFUrl/profiles/$profileId/accounts/$accountId';

    final response = await http.patch(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(accountData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to edit account');
    }
  }

  Future<List<dynamic>> fetchJournals(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final response = await http.get(
      Uri.parse('$apiPFUrl/profiles/$profileId/journal'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load accounts');
    }
  }

  Future<void> createJournalEntry(String profileId, String date,
      String description, List<JournalEntry> entries) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint = '$apiPFUrl/profiles/$profileId/journal';

    final payload = {
      'date': date,
      'description': description,
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create journal entry');
    }
  }

  Future<List<dynamic>> fetchDashboardInformation(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];

    final DateTime now = DateTime.now();

    final DateFormat yearFormat = DateFormat('yyyy');
    final DateFormat monthFormat = DateFormat('MM');

    final String year = yearFormat.format(now);
    final String month = monthFormat.format(now);

    final response = await http.get(
      Uri.parse(
          '$apiPFUrl/profiles/$profileId/dashboard?year=$year&month=$month'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load accounts');
    }
  }

  Future<void> createGeneralLedgerMonthlyRollover(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint =
        '$apiPFUrl/profiles/$profileId/general-ledger-monthly-rollover';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ??
          'Failed to create general ledger monthly rollover');
    }
  }

  Future<Map<String, dynamic>> fetchCloseMonthResult(
      String profileId, String year, String month) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint =
        '$apiPFUrl/profiles/$profileId/general-ledger-close-month-result';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({'year': year, 'month': month}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to fetch close month result');
    }
  }

  Future<Map<String, dynamic>> fetchCloseMonthBalance(
      String profileId, String year, String month) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint =
        '$apiPFUrl/profiles/$profileId/general-ledger-close-month-balance';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({'year': year, 'month': month}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to fetch close month balance');
    }
  }

  Future<Map<String, dynamic>> createSummaryMonth(
      String profileId, String year, String month,
      {required double result, required double balance}) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];
    final urlEndpoint = '$apiPFUrl/profiles/$profileId/summary-months';

    final response = await http.post(
      Uri.parse(urlEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'year': year,
        'month': month,
        'result': result,
        'balance': balance,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to create summary month');
    }
  }

  Future<List<dynamic>> fetchSummaryMonths(String profileId, {int? year}) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];

    final Map<String, String> queryParameters = {};
    if (year != null) {
      queryParameters['year'] = year.toString();
    }

    final uri = Uri.parse('$apiPFUrl/profiles/$profileId/summary-months')
        .replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load summary months');
    }
  }

  Future<List<dynamic>> fetchJournalMovements(
      String profileId, String accountId,
      {int? year, int? month}) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiPFUrl = dotenv.env['API_PF_URL'];

    final Map<String, String> queryParameters = {};
    if (year != null) {
      queryParameters['year'] = year.toString();
    }
    if (month != null) {
      queryParameters['month'] = month.toString();
    }

    final uri =
        Uri.parse('$apiPFUrl/profiles/$profileId/journal/$accountId/all')
            .replace(
                queryParameters:
                    queryParameters.isEmpty ? null : queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to load journal movements');
    }
  }
}
