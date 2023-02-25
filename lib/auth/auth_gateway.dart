import 'dart:convert';

import 'package:firedart/auth/client.dart';
import 'package:firedart/auth/token_provider.dart';

import '../constants.dart';
import 'exceptions.dart';
import 'user_gateway.dart';

class AuthGateway {
  final KeyClient client;
  final TokenProvider tokenProvider;
  final bool useEmulator;
  final String? projectId;

  AuthGateway(
    this.client,
    this.tokenProvider, {
    bool useEmulator = false,
    this.projectId,
  }) : useEmulator = useEmulator;

  Future<User> signUp(String email, String password) async => _auth(
        'signUp',
        {
          'email': email,
          'password': password,
        },
      );

  Future<User> signIn(String email, String password) async => _auth(
        'signInWithPassword',
        {
          'email': email,
          'password': password,
        },
      );

  Future<User> signInAnonymously(String apiKey) async => _auth(
        'signUp',
        {},
        apiKey: apiKey,
      );

  Future<void> resetPassword(String email) => _post(
        'sendOobCode',
        {
          'requestType': 'PASSWORD_RESET',
          'email': email,
        },
      );

  Future<User> _auth(
    String method,
    Map<String, String> payload, {
    String? apiKey,
  }) async {
    var body = {
      ...payload,
      'returnSecureToken': 'true',
    };

    var map = await _post(method, body, apiKey: apiKey);
    tokenProvider.setToken(map);
    return User.fromMap(map);
  }

  Future<Map<String, dynamic>> _post(
    String method,
    Map<String, String> body, {
    String? apiKey,
  }) async {
    // var requestUrl =
    //     'https://identitytoolkit.googleapis.com/v1/accounts:$method';

    // var requestUrl = !useEmulator
    //     ? '$AUTH_HOST_URI/accounts:$method'
    //     : '${AUTH_EMULATOR_HOST_URI.replaceFirst('{{project_id}}', projectId!)}/accounts:$method';

    // var uri = Uri.parse(requestUrl);

    var queryParams = <String, dynamic>{};
    if (apiKey != null) {
      queryParams.addAll({'key': apiKey});
    }

    var uri = Uri.https(
      AUTH_HOST_URI_AUTHORITY,
      '$AUTH_HOST_URI_PATH:$method',
      queryParams,
    );

    var response = await client.post(
      uri,
      body: body,
    );

    if (response.statusCode != 200) {
      throw AuthException(response.body);
    }

    return json.decode(response.body);
  }
}
