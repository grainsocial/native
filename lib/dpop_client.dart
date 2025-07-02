import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:uuid/uuid.dart';

class DpopHttpClient {
  final JsonWebKey dpopKey;
  final Map<String, String> _nonces = {}; // origin -> nonce

  DpopHttpClient({required this.dpopKey});

  /// Extract origin (scheme + host + port) from a URL
  String _extractOrigin(String url) {
    final uri = Uri.parse(url);
    final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }

  /// Strip query and fragment from URL per spec
  String _buildHtu(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  /// Calculate ath claim: base64url(sha256(access_token))
  String _calculateAth(String accessToken) {
    final hash = sha256.convert(utf8.encode(accessToken));
    return base64Url.encode(hash.bytes).replaceAll('=', '');
  }

  /// Calculate the JWK Thumbprint for EC or RSA keys per RFC 7638.
  /// The input [jwk] is the public part of your key as a Map`<String, dynamic>`.
  ///
  /// For EC keys, required fields are: crv, kty, x, y
  /// For RSA keys, required fields are: e, kty, n
  String calculateJwkThumbprint(Map<String, dynamic> jwk) {
    late Map<String, String> ordered;

    if (jwk['kty'] == 'EC') {
      ordered = {'crv': jwk['crv'], 'kty': jwk['kty'], 'x': jwk['x'], 'y': jwk['y']};
    } else if (jwk['kty'] == 'RSA') {
      ordered = {'e': jwk['e'], 'kty': jwk['kty'], 'n': jwk['n']};
    } else {
      throw ArgumentError('Unsupported key type for thumbprint calculation');
    }

    final jsonString = jsonEncode(ordered);

    final digest = sha256.convert(utf8.encode(jsonString));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Build the DPoP JWT proof
  Future<String> _buildProof({
    required String htm,
    required String htu,
    String? nonce,
    String? ath,
  }) async {
    final now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final jti = Uuid().v4();

    final publicJwk = Map<String, String>.from(dpopKey.toJson())..remove('d');

    final payload = {
      'htu': htu,
      'htm': htm,
      'iat': now,
      'jti': jti,
      if (nonce != null) 'nonce': nonce,
      if (ath != null) 'ath': ath,
    };

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = payload
      ..addRecipient(dpopKey, algorithm: dpopKey.algorithm)
      ..setProtectedHeader('typ', 'dpop+jwt')
      ..setProtectedHeader('jwk', publicJwk);

    final jws = builder.build();
    return jws.toCompactSerialization();
  }

  /// Public method to send requests with DPoP proof, retries once on use_dpop_nonce error
  Future<http.Response> send({
    required String method,
    required Uri url,
    required String accessToken,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final origin = _extractOrigin(url.toString());
    final nonce = _nonces[origin];

    final htu = _buildHtu(url.toString());
    final ath = _calculateAth(accessToken);

    final proof = await _buildProof(htm: method.toUpperCase(), htu: htu, nonce: nonce, ath: ath);

    // Compose headers, allowing override of Content-Type for raw uploads
    final requestHeaders = <String, String>{
      'Authorization': 'DPoP $accessToken',
      'DPoP': proof,
      if (headers != null) ...headers,
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(url, headers: requestHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(url, headers: requestHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: requestHeaders, body: body);
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    final newNonce = response.headers['dpop-nonce'];
    if (newNonce != null && newNonce != nonce) {
      // Save new nonce for origin
      _nonces[origin] = newNonce;
    }

    if (response.statusCode == 401) {
      final wwwAuth = response.headers['www-authenticate'];
      if (wwwAuth != null &&
          wwwAuth.contains('DPoP') &&
          wwwAuth.contains('error="use_dpop_nonce"') &&
          newNonce != null &&
          newNonce != nonce) {
        // Retry once with updated nonce
        return send(
          method: method,
          url: url,
          accessToken: accessToken,
          headers: headers,
          body: body,
        );
      }
    }

    return response;
  }
}
