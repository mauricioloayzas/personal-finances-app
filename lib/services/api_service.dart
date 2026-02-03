import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<void> logout() async {
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'sub');
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
      } else {
        throw Exception('Respuesta inválida del servidor.');
      }
    } else {
      throw Exception('Email o contraseña incorrectos.');
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
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load profiles');
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
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final response = await http.get(
      Uri.parse('$apiOrchestratorUrl/profiles/$profileId/accounts/$accountId'),
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

  Future<Map<String, dynamic>> getAccountProfileDetailsByCode(
      String profileId, String accountCode) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    accountCode = accountCode.replaceAll(".", "-");
    final response = await http.get(
      Uri.parse(
          '$apiOrchestratorUrl/profiles/$profileId/accounts/code/$accountCode'),
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
}
