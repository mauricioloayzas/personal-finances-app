import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../core/enums.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> logout() async {
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'sub');
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
    final payload = {'email': email, 'password': password};

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

  Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_ORCHESTRATOR_URL']}/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'password': password,
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

  Future<Map<String, dynamic>> _fetchProfileDetails(String profileId) async {
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

  Future<Map<String, dynamic>> createProfile(String name, String email) async {
    final profileId = dotenv.env['SERVICE_PROFILE_ID'];
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final urlEndpoint = '$apiOrchestratorUrl/profiles/$profileId/children';

    final payload = {
      'name': name,
      'email': email,
      'type': ProfileType.person.name,
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

  Future<List<dynamic>> fetchProfiles() async {
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
      final profileDetails = await Future.wait(
        rbacs.map<Future<Map<String, dynamic>>>((rbac) {
          return _fetchProfileDetails(rbac['profile_id'].toString());
        }).toList(),
      );
      return profileDetails;
    } else {
      return [];
    }
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
