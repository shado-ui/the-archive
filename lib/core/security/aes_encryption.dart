import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class AesEncryption {
  static final _algorithm = AesGcm.with256bits();

  /// Encrypt a plaintext string using a 256-bit key.
  /// Returns a JSON string packaging the ciphertext, nonce, and authentication MAC.
  static Future<String> encrypt(String plaintext, List<int> keyBytes) async {
    final secretKey = SecretKey(keyBytes);
    final clearText = utf8.encode(plaintext);
    
    final secretBox = await _algorithm.encrypt(
      clearText,
      secretKey: secretKey,
    );
    
    final package = {
      'nonce': base64Encode(secretBox.nonce),
      'cipher': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    
    return jsonEncode(package);
  }

  /// Decrypt a JSON encrypted package (nonce + cipher + mac) using the same 256-bit key.
  static Future<String> decrypt(String encryptedPackage, List<int> keyBytes) async {
    final secretKey = SecretKey(keyBytes);
    final Map<String, dynamic> package = jsonDecode(encryptedPackage);
    
    final secretBox = SecretBox(
      base64Decode(package['cipher']),
      nonce: base64Decode(package['nonce']),
      mac: Mac(base64Decode(package['mac'])),
    );
    
    final decryptedBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    
    return utf8.decode(decryptedBytes);
  }
}
