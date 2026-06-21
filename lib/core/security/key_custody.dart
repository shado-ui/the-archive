import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class KeyCustodyService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();
  
  // Cache the derived key in-memory during active sessions
  List<int>? _cachedVaultKey;

  List<int>? get vaultKey => _cachedVaultKey;
  bool get isUnlocked => _cachedVaultKey != null;

  /// Clear the session key to lock the vault immediately (auto-lock or manual sign-out)
  void lockVault() {
    _cachedVaultKey = null;
  }

  /// Manually unlock vault with key in-memory (useful for testing or direct key entry)
  void setVaultKey(List<int> key) {
    _cachedVaultKey = key;
  }

  /// Derive key from user's vault password and server-side salt using PBKDF2-HMAC-SHA256
  Future<List<int>> deriveKey(String vaultPassword, String saltHex) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(Sha256()),
      iterations: 100000,
      bits: 256,
    );
    
    final salt = hexDecode(saltHex);
    final secretKey = SecretKey(utf8.encode(vaultPassword));
    final derived = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    
    return await derived.extractBytes();
  }

  /// Persists the derived vault key locally in Secure Storage
  Future<void> saveKeySecurely(List<int> derivedKey) async {
    final base64Key = base64Encode(derivedKey);
    await _storage.write(key: 'master_vault_key', value: base64Key);
    _cachedVaultKey = derivedKey;
  }

  /// Verifies if a master key is already persisted in local secure storage
  Future<bool> hasSavedKey() async {
    final base64Key = await _storage.read(key: 'master_vault_key');
    return base64Key != null;
  }

  /// Erases local secure key cache (wipe device data / logout)
  Future<void> clearSecureStorage() async {
    await _storage.delete(key: 'master_vault_key');
    _cachedVaultKey = null;
  }

  /// Gate secure storage retrieval using biometric local authentication
  Future<bool> unlockWithBiometrics() async {
    final hasBiometrics = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    
    if (!hasBiometrics || !isSupported) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock your vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        final base64Key = await _storage.read(key: 'master_vault_key');
        if (base64Key != null) {
          _cachedVaultKey = base64Decode(base64Key);
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Check if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    final hasBiometrics = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return hasBiometrics && isSupported;
  }

  /// Save PIN for quick unlock
  Future<void> savePin(String pin) async {
    await _storage.write(key: 'vault_pin', value: pin);
  }

  /// Verify PIN and unlock vault
  Future<bool> unlockWithPin(String pin) async {
    final savedPin = await _storage.read(key: 'vault_pin');
    if (savedPin == pin) {
      final base64Key = await _storage.read(key: 'master_vault_key');
      if (base64Key != null) {
        _cachedVaultKey = base64Decode(base64Key);
        return true;
      }
    }
    return false;
  }

  /// Check if PIN is set
  Future<bool> hasPin() async {
    final pin = await _storage.read(key: 'vault_pin');
    return pin != null;
  }

  /// Clear PIN
  Future<void> clearPin() async {
    await _storage.delete(key: 'vault_pin');
  }

  /// Decodes hex string to list of bytes
  List<int> hexDecode(String hex) {
    var result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
