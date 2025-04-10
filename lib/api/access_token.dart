import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class AccessToken {
  static String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  Future<String> getAccessToken() async {
    // Load JSON from assets
    final jsonString = await rootBundle.loadString(
        'lib/assets/service_account.json');

    final Map<String, dynamic> serviceAccount = json.decode(jsonString);

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(serviceAccount),
      [firebaseMessagingScope],
    );

    final accessToken = client.credentials.accessToken.data;
    print("Access Token: $accessToken");

    return accessToken;
  }
}
