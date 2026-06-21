import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class KeyCustodyService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();
  
  bool _isUnlocked = false;

  bool get isUnlocked => _isUnlocked;

  /// Clear the session to lock the vault immediately (auto-lock or manual sign-out)
  void lockVault() {
    _isUnlocked = false;
  }

  /// Manually unlock vault
  void setUnlocked() {
    _isUnlocked = true;
  }

  /// Save PIN for vault access
  Future<void> savePin(String pin) async {
    await _storage.write(key: 'vault_pin', value: pin);
  }

  /// Verify PIN and unlock vault
  Future<bool> unlockWithPin(String pin) async {
    final savedPin = await _storage.read(key: 'vault_pin');
    if (savedPin == pin) {
      _isUnlocked = true;
      return true;
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
    _isUnlocked = false;
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
        _isUnlocked = true;
        return true;
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
}
