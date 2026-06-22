import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/colors.dart';
import '../core/models/dart_models.dart';
import '../core/providers/state_providers.dart';
import '../core/security/key_custody.dart';

String generateUUID() {
  final random = Random.secure();
  final hex = List.generate(16, (i) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

String generateVaultSaltHex() {
  final random = Random.secure();
  return List.generate(32, (_) => random.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

String authErrorMessage(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

// --------------------------------------------------------------------
// UI Styles & Custom Widgets
// --------------------------------------------------------------------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? elevation;

  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.elevation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: elevation != null && elevation! > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: elevation!,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

// --------------------------------------------------------------------
// 1. Splash Screen
// --------------------------------------------------------------------
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SessionSession extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      if (session != null) {
        context.go('/unlock');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.spaceDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 80, color: AppColors.roseSpark),
            SizedBox(height: 16),
            Text(
              "THE ARCHIVE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "A Secure Life & Relationship Registry",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 2. Login & Signup Screen
// --------------------------------------------------------------------
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _saltController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required.")),
      );
      return;
    }

    setState(() => _loading = true);
    final authRepo = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        final saltHex = _saltController.text.trim().isEmpty
            ? generateVaultSaltHex()
            : _saltController.text.trim();
        _saltController.text = saltHex;

        final response = await authRepo.signUp(email, password, saltHex);
        if (!mounted) return;

        if (response.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created. Set your vault password next.")),
          );
          context.go('/unlock');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful. Check your email to confirm, then sign in.")),
          );
        }
      } else {
        await authRepo.signIn(email, password);
        if (!mounted) return;
        context.go('/unlock');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication failed: ${authErrorMessage(e)}")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.spaceDark, AppColors.deepSpace],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 50, color: AppColors.roseSpark),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp ? "Create Private Archive" : "Unlock Relationship Archive",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _saltController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Key Derivation Salt (Hex)",
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.autorenew_rounded, color: AppColors.auroraCyan),
                            onPressed: () {
                              _saltController.text = generateVaultSaltHex();
                            },
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseSpark,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _loading ? null : _handleAuth,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isSignUp ? "Register Account" : "Access Database", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _isSignUp = !_isSignUp;
                        if (_isSignUp && _saltController.text.isEmpty) {
                          _saltController.text = generateVaultSaltHex();
                        }
                      }),
                      child: Text(
                        _isSignUp ? "Already have an account? Login" : "Create new private relationship archive",
                        style: const TextStyle(color: AppColors.auroraCyan),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 3. Vault Unlock Screen (Input Master Key)
// --------------------------------------------------------------------
class VaultUnlockScreen extends ConsumerStatefulWidget {
  const VaultUnlockScreen({super.key});

  @override
  ConsumerState<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends ConsumerState<VaultUnlockScreen> {
  final _pinController = TextEditingController();
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _pinSet = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAndPin();
  }

  Future<void> _checkBiometricAndPin() async {
    final keyCustody = ref.read(keyCustodyProvider);
    final hasBio = await keyCustody.isBiometricAvailable();
    final hasPin = await keyCustody.hasPin();
    if (mounted) {
      setState(() {
        _biometricAvailable = hasBio;
        _pinSet = hasPin;
      });
    }
  }

  Future<void> _unlockVault() async {
    setState(() => _loading = true);
    final keyCustody = ref.read(keyCustodyProvider);
    final partnerRepo = ref.read(partnerProfileRepositoryProvider);
    final user = ref.read(currentUserProvider);
    
    try {
      if (user == null) throw Exception("Session inactive. Re-authenticate.");
      
      final pin = _pinController.text.trim();
      if (pin.isEmpty) throw Exception("Please enter your PIN");
      final success = await keyCustody.unlockWithPin(pin);
      if (!success) throw Exception("Invalid PIN");
      
      // Check if partner profile exists, if not redirect to setup
      final partnerProfile = await partnerRepo.getPartnerProfile(user.id);
      if (partnerProfile == null && mounted) {
        context.go('/setup');
        return;
      }
      
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unlock Failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final keyCustody = ref.read(keyCustodyProvider);
    final partnerRepo = ref.read(partnerProfileRepositoryProvider);
    final user = ref.read(currentUserProvider);
    
    final success = await keyCustody.unlockWithBiometrics();
    if (success) {
      // Check if partner profile exists, if not redirect to setup
      final partnerProfile = await partnerRepo.getPartnerProfile(user!.id);
      if (partnerProfile == null && mounted) {
        context.go('/setup');
        return;
      }
      
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Biometric verification failed. Use PIN.")),
        );
      }
    }
  }

  void _showPinSetupDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Set Up PIN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: pinController,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "Enter 6-digit PIN",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                counterStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.auroraCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 6) {
                final keyCustody = ref.read(keyCustodyProvider);
                await keyCustody.savePin(pin);
                if (mounted) {
                  setState(() => _pinSet = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PIN set successfully")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.auroraCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Set PIN", style: TextStyle(color: AppColors.spaceDark, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final isDark = ref.watch(isDarkModeProvider);
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(appTheme, isDark),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              elevation: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.auroraCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, size: 48, color: AppColors.auroraCyan),
                  ),
                  const SizedBox(height: 24),
                  const Text("Vault Security", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _pinSet ? "Enter your PIN to unlock" : "Create a PIN to secure your vault",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "PIN",
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      counterStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.auroraCyan, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.auroraCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : (_pinSet ? _unlockVault : () => _showPinSetupDialog()),
                      child: _loading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text(_pinSet ? "Unlock" : "Create PIN", style: const TextStyle(color: AppColors.spaceDark, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_biometricAvailable && _pinSet)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fingerprint_rounded, size: 48, color: AppColors.roseSpark),
                                onPressed: _unlockWithBiometrics,
                              ),
                              const SizedBox(height: 8),
                              const Text("Biometric", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 3. Setup/Onboarding Screen
// --------------------------------------------------------------------
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _partnerNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  int _currentStep = 0;
  bool _loading = false;

  final List<String> _steps = [
    "Welcome to The Krisha Archive",
    "Partner Information",
    "Setup Complete",
  ];

  Future<void> _completeSetup() async {
    setState(() => _loading = true);
    try {
      final partnerRepo = ref.read(partnerProfileRepositoryProvider);
      final user = ref.read(currentUserProvider);
      
      if (user == null) throw Exception("No active session");
      
      final partnerProfile = PartnerProfile(
        id: '',
        userId: user.id,
        fullName: _partnerNameController.text.trim(),
        nicknames: _nicknameController.text.trim().isNotEmpty 
          ? [_nicknameController.text.trim()] 
          : [],
        bucketList: [],
        dreams: [],
        favoriteBrands: [],
        favoriteClothingStyles: [],
        fears: [],
        goals: [],
        hobbies: [],
        insecurities: [],
        strengths: [],
        weaknesses: [],
      );
      
      await partnerRepo.upsertPartnerProfile(partnerProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Setup complete! Welcome to The Krisha Archive")),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Setup failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final isDark = ref.watch(isDarkModeProvider);
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(appTheme, isDark),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_edu_rounded, size: 60, color: AppColors.roseSpark),
                const SizedBox(height: 24),
                Text(
                  _steps[_currentStep],
                  style: TextStyle(
                    color: AppColors.getTextPrimary(isDark),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildStepContent(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getTextSecondary(isDark).withOpacity(0.3),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _previousStep,
                          child: Text("Back", style: TextStyle(color: AppColors.getTextPrimary(isDark))),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccent(appTheme),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : (_currentStep == _steps.length - 1 ? _completeSetup : _nextStep),
                        child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_currentStep == _steps.length - 1 ? "Complete Setup" : "Next", 
                              style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentStep ? AppColors.getAccent(appTheme) : AppColors.getTextMuted(isDark),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final isDark = ref.watch(isDarkModeProvider);
    
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            Text(
              "A secure digital archive for your relationship memories, milestones, and intimate moments.",
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureItem(Icons.favorite_rounded, "Memories & Stories", "Preserve your precious moments together"),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.lock_rounded, "Secure Vault", "AES-256 encrypted password manager"),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.calendar_month_rounded, "Timeline & Events", "Track anniversaries and milestones"),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.psychology_rounded, "Relationship Insights", "Love languages, comfort guidelines, and more"),
          ],
        );
      case 1:
        return Column(
          children: [
            TextField(
              controller: _partnerNameController,
              style: TextStyle(color: AppColors.getTextPrimary(isDark)),
              decoration: InputDecoration(
                labelText: "Partner's Full Name *",
                labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.getGlassBorder(isDark))),
                hintText: "e.g., Krisha Johnson",
                hintStyle: TextStyle(color: AppColors.getTextMuted(isDark)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              style: TextStyle(color: AppColors.getTextPrimary(isDark)),
              decoration: InputDecoration(
                labelText: "Nickname (Optional)",
                labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.getGlassBorder(isDark))),
                hintText: "e.g., Baby, Love, Sweetheart",
                hintStyle: TextStyle(color: AppColors.getTextMuted(isDark)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You can always update this information later in the Partner Profile section.",
              style: TextStyle(
                color: AppColors.getTextMuted(isDark),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.successGreen),
            const SizedBox(height: 16),
            Text(
              "You're all set!",
              style: TextStyle(
                color: AppColors.getTextPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your archive is ready. Start by adding your first memory or explore the dashboard.",
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    final isDark = ref.watch(isDarkModeProvider);
    
    return Row(
      children: [
        Icon(icon, color: AppColors.getAccent(ref.watch(themeProvider)), size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextPrimary(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------
// 4. Responsive Navigation Layout Scaffolding
// --------------------------------------------------------------------
class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  const SidebarItem({required this.label, required this.icon, required this.route});
}

class SidebarGroup {
  final String title;
  final List<SidebarItem> items;
  const SidebarGroup({required this.title, required this.items});
}

class MainNavigationScaffold extends ConsumerWidget {
  final Widget child;

  const MainNavigationScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final router = GoRouter.of(context);
    final currentRoute = router.state.matchedLocation;
    final appTheme = ref.watch(themeProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final groups = [
      const SidebarGroup(
        title: "DASHBOARD & CORE",
        items: [
          SidebarItem(label: "Dashboard", icon: Icons.dashboard_rounded, route: "/dashboard"),
          SidebarItem(label: "Timeline", icon: Icons.timeline_rounded, route: "/timeline"),
          SidebarItem(label: "Calendar", icon: Icons.calendar_month_rounded, route: "/calendar"),
          SidebarItem(label: "Analytics", icon: Icons.bar_chart_rounded, route: "/analytics"),
        ],
      ),
      const SidebarGroup(
        title: "LIFE OS™ SYSTEM",
        items: [
          SidebarItem(label: "Life Planner", icon: Icons.today_rounded, route: "/life_planner"),
          SidebarItem(label: "Goals", icon: Icons.flag_rounded, route: "/goals"),
          SidebarItem(label: "Habits", icon: Icons.autorenew_rounded, route: "/habits"),
          SidebarItem(label: "Tasks", icon: Icons.task_alt_rounded, route: "/tasks"),
          SidebarItem(label: "Focus Tracker", icon: Icons.timer_rounded, route: "/focus"),
        ],
      ),
      const SidebarGroup(
        title: "LOVE & MEMORIES",
        items: [
          SidebarItem(label: "Memories", icon: Icons.favorite_rounded, route: "/memories"),
          SidebarItem(label: "Gallery", icon: Icons.photo_library_rounded, route: "/gallery"),
          SidebarItem(label: "Quotes", icon: Icons.format_quote_rounded, route: "/quotes"),
          SidebarItem(label: "Preferences", icon: Icons.volunteer_activism_rounded, route: "/preferences"),
          SidebarItem(label: "Social Matrix", icon: Icons.people_alt_rounded, route: "/social_matrix"),
          SidebarItem(label: "Cycle Tracker", icon: Icons.bubble_chart_rounded, route: "/period"),
        ],
      ),
      const SidebarGroup(
        title: "SECURITY & SYSTEM",
        items: [
          SidebarItem(label: "Cipher Vault", icon: Icons.lock_rounded, route: "/vault"),
          SidebarItem(label: "Settings", icon: Icons.settings_rounded, route: "/settings"),
        ],
      ),
    ];

    void showMobileMoreMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.spaceDark,
        barrierColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ALL SECTIONS",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: groups.expand((g) => g.items).length,
                    itemBuilder: (context, idx) {
                      final item = groups.expand((g) => g.items).elementAt(idx);
                      final isSelected = currentRoute == item.route;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.route);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.roseSpark.withOpacity(0.15) : AppColors.cardBg,
                            border: Border.all(
                              color: isSelected ? AppColors.roseSpark : AppColors.glassBorder,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected ? AppColors.roseSpark : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    int getMobileBottomIndex() {
      if (currentRoute == "/life_planner") return 0;
      if (currentRoute == "/calendar") return 1;
      if (currentRoute == "/memories") return 2;
      if (currentRoute == "/vault") return 3;
      return 4;
    }

    void onMobileBottomTap(int idx) {
      if (idx == 4) {
        showMobileMoreMenu();
      } else {
        switch (idx) {
          case 0: context.go("/life_planner"); break;
          case 1: context.go("/calendar"); break;
          case 2: context.go("/memories"); break;
          case 3: context.go("/vault"); break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(appTheme, isDark),
      body: Row(
        children: [
          if (isDesktop) ...[
            Container(
              width: 270,
              decoration: BoxDecoration(
                color: AppColors.getSurface(appTheme, isDark),
                border: Border(right: BorderSide(color: AppColors.getGlassBorder(isDark), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.history_edu_rounded, color: AppColors.roseSpark, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "THE ARCHIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Life & Love OS v1.5",
                                style: TextStyle(
                                  color: AppColors.roseSpark.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.textSecondary, size: 20),
                          onPressed: () => ref.read(isDarkModeProvider.notifier).toggleDarkMode(),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<AppTheme>(
                          icon: Icon(Icons.palette, color: AppColors.textSecondary, size: 20),
                          onSelected: (theme) => ref.read(themeProvider.notifier).setTheme(theme),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: AppTheme.cosmicDark,
                              child: Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.auroraCyan, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('Cosmic Dark', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: AppTheme.midnightBlue,
                              child: Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.midnightAccent, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('Midnight Blue', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: AppTheme.sunsetGlow,
                              child: Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.sunsetAccent, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('Sunset Glow', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: AppTheme.forestGreen,
                              child: Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.forestAccent, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('Forest Green', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: AppTheme.oceanDepth,
                              child: Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.oceanAccent, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('Ocean Depth', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: groups.map((g) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 20, bottom: 8),
                                child: Text(
                                  g.title,
                                  style: TextStyle(
                                    color: AppColors.getTextMuted(isDark),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              ...g.items.map((item) {
                                final isSelected = currentRoute == item.route;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => context.go(item.route),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.roseSpark.withOpacity(0.12) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? AppColors.roseSpark.withOpacity(0.3) : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.icon,
                                              color: isSelected ? AppColors.roseSpark : AppColors.getTextSecondary(isDark),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              item.label,
                                              style: TextStyle(
                                                color: isSelected ? AppColors.roseSpark : AppColors.getTextSecondary(isDark),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              backgroundColor: AppColors.nebulaViolet,
              currentIndex: getMobileBottomIndex(),
              onTap: onMobileBottomTap,
              unselectedItemColor: AppColors.textMuted,
              selectedItemColor: AppColors.roseSpark,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.today_rounded), label: 'Planner'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Memories'),
                BottomNavigationBarItem(icon: Icon(Icons.lock_rounded), label: 'Vault'),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
              ],
            )
          : null,
    );
  }
}

// --------------------------------------------------------------------
// 5. Master Dashboard Screen
// --------------------------------------------------------------------
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(globalTimelineProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, color: AppColors.goldAccent),
            onPressed: () {
              ref.read(keyCustodyProvider).lockVault();
              context.go('/unlock');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            GlassCard(
              elevation: 4,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.roseSpark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 32, color: AppColors.roseSpark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome Back", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text("Your Relationship Hub", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Relational countdown matrix
            isDesktop
                ? const Row(
                    children: [
                      Expanded(child: CountdownCard(title: "Relationship Anniversary", dateLabel: "Dec 18", countdownDays: 180)),
                      SizedBox(width: 16),
                      Expanded(child: CountdownCard(title: "Krisha's Birthday", dateLabel: "Oct 24", countdownDays: 126)),
                      SizedBox(width: 16),
                      Expanded(child: CountdownCard(title: "Next Monthsary", dateLabel: "Jul 18", countdownDays: 28)),
                    ],
                  )
                : const Column(
                    children: [
                      CountdownCard(title: "Anniversary", dateLabel: "Dec 18", countdownDays: 180),
                      SizedBox(height: 16),
                      CountdownCard(title: "Krisha's Birthday", dateLabel: "Oct 24", countdownDays: 126),
                    ],
                  ),
            const SizedBox(height: 32),
            const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: ActionBtn(label: "Log Memory", icon: Icons.photo_rounded, color: AppColors.roseSpark)),
                SizedBox(width: 12),
                Expanded(child: ActionBtn(label: "Add Quote", icon: Icons.format_quote_rounded, color: AppColors.goldAccent)),
                SizedBox(width: 12),
                Expanded(child: ActionBtn(label: "Record Cycle", icon: Icons.bubble_chart_rounded, color: AppColors.auroraCyan)),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Recent Timeline Activities", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            timelineAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Text("No recent timeline records logged.", style: TextStyle(color: AppColors.textSecondary));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 5 ? 5 : events.length,
                  itemBuilder: (context, idx) {
                    final ev = events[idx];
                    return Card(
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.circle, color: AppColors.roseSpark, size: 10),
                        title: Text(ev.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(ev.description ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: Text(DateFormat('MM/dd').format(ev.eventDate), style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error: $err", style: const TextStyle(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
    );
  }
}

class CountdownCard extends StatelessWidget {
  final String title;
  final String dateLabel;
  final int countdownDays;

  const CountdownCard({required this.title, required this.dateLabel, required this.countdownDays, super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_rounded, size: 20, color: AppColors.goldAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$countdownDays",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                "days",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const ActionBtn({required this.label, required this.icon, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      elevation: 2,
      padding: EdgeInsets.zero,
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// 6. Cipher Vault Screen (Decrypted Passwords List)
// --------------------------------------------------------------------
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _platformName = TextEditingController();
  final _webUrl = TextEditingController();
  final _username = TextEditingController();
  final _plaintextPassword = TextEditingController();

  Future<void> _saveEntry() async {
    final repo = ref.read(vaultRepositoryProvider);
    final user = ref.read(currentUserProvider);

    if (user != null) {
      final credential = PlatformCredential(
        id: generateUUID(),
        userId: user.id,
        platformName: _platformName.text.trim(),
        websiteUrl: _webUrl.text.trim(),
        usernameEmail: _username.text.trim(),
        encryptedPassword: _plaintextPassword.text.trim(),
      );
      await repo.saveCredential(credential);
      ref.invalidate(vaultCredentialsProvider);
      
      // Clean inputs
      _platformName.clear();
      _webUrl.clear();
      _username.clear();
      _plaintextPassword.clear();
      Navigator.pop(context);
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Secure Entry", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _platformName, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Platform Name")),
            TextField(controller: _webUrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Website URL")),
            TextField(controller: _username, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Username/Email")),
            TextField(controller: _plaintextPassword, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.auroraCyan, minimumSize: const Size(double.infinity, 50)),
              onPressed: _saveEntry,
              child: const Text("Save", style: TextStyle(color: AppColors.spaceDark)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credentialsAsync = ref.watch(vaultCredentialsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Password Vault", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.auroraCyan,
        onPressed: _showAddModal,
        child: const Icon(Icons.add_rounded, color: AppColors.spaceDark),
      ),
      body: credentialsAsync.when(
        data: (credentials) {
          if (credentials.isEmpty) {
            return const Center(child: Text("Vault empty. Add secure details.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final cred = credentials[index];
              return Card(
                color: AppColors.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(cred.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(cred.usernameEmail ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cred.encryptedPassword, style: const TextStyle(color: AppColors.auroraCyan, fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: AppColors.errorRed, size: 20),
                        onPressed: () async {
                          await ref.read(vaultRepositoryProvider).deleteCredential(cred.id);
                          ref.invalidate(vaultCredentialsProvider);
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error loading vault: $err", style: const TextStyle(color: AppColors.errorRed))),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 7. Unified Timeline Screen
// --------------------------------------------------------------------
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(globalTimelineProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Relationship Feed Timeline", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
      ),
      body: timelineAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text("Timeline empty. Post activities.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.roseSpark, size: 20),
                        Container(width: 2, height: 80, color: AppColors.glassBorder),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(ev.eventDate),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ev.sourceTable.toUpperCase(),
                                    style: const TextStyle(color: AppColors.auroraCyan, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(ev.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            if (ev.description != null) ...[
                              const SizedBox(height: 8),
                              Text(ev.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error loading timeline: $err", style: const TextStyle(color: AppColors.errorRed))),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 8. Calendar Screen
// --------------------------------------------------------------------
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Calendar Overview", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Relationship Milestones Calendar",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Mock visual Calendar Grid demonstrating design aesthetics
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final day = (index - 2) > 0 && (index - 2) <= 30 ? (index - 2) : 0;
                final isSpecial = day == 18 || day == 24;
                return Container(
                  decoration: BoxDecoration(
                    color: isSpecial ? AppColors.roseSpark.withOpacity(0.3) : AppColors.cardBg,
                    border: Border.all(color: isSpecial ? AppColors.roseSpark : AppColors.glassBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      day > 0 ? "$day" : "",
                      style: TextStyle(color: isSpecial ? AppColors.roseSpark : Colors.white, fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const GlassCard(
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.roseSpark, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Special Event Marked", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("18th is your relationship monthsary milestone date.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 9. Gallery Screen (Media Vault)
// --------------------------------------------------------------------
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(memoriesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Memory Gallery", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent),
      body: memoriesAsync.when(
        data: (memories) {
          if (memories.isEmpty) {
            return const Center(child: Text("No memories yet. Add your first memory.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: memories.length,
            itemBuilder: (context, idx) {
              final memory = memories[idx];
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: AppColors.cardBg,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 32),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        memory.title,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.errorRed))),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 10. Period Prediction Tracker Screen
// --------------------------------------------------------------------
class PeriodTrackerScreen extends ConsumerWidget {
  const PeriodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Period Prediction Tracker", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassCard(
              child: Column(
                children: [
                  Text("Next Cycle Prediction", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  SizedBox(height: 8),
                  Text("July 12", style: TextStyle(color: AppColors.roseSpark, fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Remaining Days: 22 (Calculated average: 28-day cycle)", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("Log Symptoms", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Cramps', 'Headache', 'Mood Swings', 'Fatigue', 'Bloating', 'Lower Back Pain'
              ].map((symptom) => FilterChip(
                backgroundColor: AppColors.cardBg,
                selectedColor: AppColors.roseSpark.withOpacity(0.3),
                checkmarkColor: AppColors.roseSpark,
                labelStyle: const TextStyle(color: Colors.white),
                label: Text(symptom),
                selected: symptom == 'Cramps',
                onSelected: (_) {},
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text("Cycle History Logs", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.bubble_chart_rounded, color: AppColors.roseSpark),
                title: Text("June 14 - June 19", style: TextStyle(color: Colors.white)),
                subtitle: Text("Flow: Heavy • Pain: Moderate • Mood: Sensitive", style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 11. Complete Krisha Profile Screen
// --------------------------------------------------------------------
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerProfileAsync = ref.watch(partnerProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Krisha's Personal Registry", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent),
      body: partnerProfileAsync.when(
        data: (partnerProfile) {
          if (partnerProfile == null) {
            return const Center(child: Text("Complete setup to view partner profile", style: TextStyle(color: AppColors.textSecondary)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50, backgroundColor: AppColors.roseSpark, child: Icon(Icons.person_rounded, size: 50, color: Colors.white)),
                      const SizedBox(height: 16),
                      Text(partnerProfile.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (partnerProfile.nicknames.isNotEmpty)
                        Text("Nickname: ${partnerProfile.nicknames.join(', ')}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      if (partnerProfile.birthday != null)
                        Text("Birthday: ${DateFormat('MMMM d').format(partnerProfile.birthday!)}${partnerProfile.zodiacSign != null ? ' • ${partnerProfile.zodiacSign}' : ''}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Favorite Items", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    ProfileDetailCard(label: "Favorite Color", value: partnerProfile.favoriteColor ?? "Not set"),
                    ProfileDetailCard(label: "Flower Preference", value: partnerProfile.favoriteFlower ?? "Not set"),
                    ProfileDetailCard(label: "Favorite Animal", value: partnerProfile.favoriteAnimal ?? "Not set"),
                    ProfileDetailCard(label: "Favorite Food", value: partnerProfile.favoriteFood ?? "Not set"),
                    ProfileDetailCard(label: "Clothing Brand", value: partnerProfile.favoriteBrands.isNotEmpty ? partnerProfile.favoriteBrands.join(', ') : "Not set"),
                    ProfileDetailCard(label: "Shoe / Ring Size", value: "${partnerProfile.shoeSize ?? 'N/A'} / ${partnerProfile.ringSize ?? 'N/A'}"),
                  ],
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Aspirations & Dreams", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Strengths", style: const TextStyle(color: AppColors.roseSpark, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(partnerProfile.strengths.isNotEmpty ? partnerProfile.strengths.map((s) => "• $s").join("\n") : "Not set", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      Text("Dreams & Aspirations", style: const TextStyle(color: AppColors.auroraCyan, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(partnerProfile.dreams.isNotEmpty ? partnerProfile.dreams.map((d) => "• $d").join("\n") : "Not set", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.errorRed))),
      ),
    );
  }
}

class ProfileDetailCard extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetailCard({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================================================================
// LIFE OS — SCREENS & DIALOGS
// ====================================================================

// --------------------------------------------------------------------
// 12. Life Planner / Today Screen
// --------------------------------------------------------------------
class LifePlannerScreen extends ConsumerStatefulWidget {
  const LifePlannerScreen({super.key});

  @override
  ConsumerState<LifePlannerScreen> createState() => _LifePlannerScreenState();
}

class _LifePlannerScreenState extends ConsumerState<LifePlannerScreen> {
  void _showAddBlockModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddTimeBlockDialog(),
    );
  }

  void _showReflectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const DailyReflectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeBlocksAsync = ref.watch(timeBlocksProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Today's Daily Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_rounded, color: AppColors.auroraCyan),
            tooltip: "Daily Reflection",
            onPressed: _showReflectionModal,
          ),
          IconButton(
            icon: const Icon(Icons.more_time_rounded, color: AppColors.roseSpark),
            tooltip: "Add Time Block",
            onPressed: _showAddBlockModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.nebulaViolet, AppColors.deepSpace],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                    style: const TextStyle(color: AppColors.roseSpark, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome back to Life OS™",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Align your time, execute your habits, and achieve your goals.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Schedule Column
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Time Blocking Timetable",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      timeBlocksAsync.when(
                        data: (blocks) {
                          if (blocks.isEmpty) {
                            // Insert Mock Schedule for wow factor / fallback
                            final mockBlocks = [
                              TimeBlock(id: '1', ownerId: '1', title: 'Morning Routine', category: 'Health', startTime: DateTime.now().copyWith(hour: 7, minute: 0), endTime: DateTime.now().copyWith(hour: 8, minute: 0), color: '0xFFFF4D80'),
                              TimeBlock(id: '2', ownerId: '1', title: 'Work / Study', category: 'Work', startTime: DateTime.now().copyWith(hour: 8, minute: 0), endTime: DateTime.now().copyWith(hour: 12, minute: 0), color: '0xFF00E5FF'),
                              TimeBlock(id: '3', ownerId: '1', title: 'Lunch Break', category: 'Health', startTime: DateTime.now().copyWith(hour: 12, minute: 0), endTime: DateTime.now().copyWith(hour: 13, minute: 0), color: '0xFFFFD700'),
                              TimeBlock(id: '4', ownerId: '1', title: 'Gym Session', category: 'Fitness', startTime: DateTime.now().copyWith(hour: 17, minute: 0), endTime: DateTime.now().copyWith(hour: 18, minute: 30), color: '0xFF8A2BE2'),
                              TimeBlock(id: '5', ownerId: '1', title: 'Krisha Time ❤️', category: 'Relationship', startTime: DateTime.now().copyWith(hour: 19, minute: 0), endTime: DateTime.now().copyWith(hour: 21, minute: 0), color: '0xFFFF4D80'),
                            ];
                            return _buildTimeTimetable(mockBlocks);
                          }
                          return _buildTimeTimetable(blocks);
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text("Error: $err", style: const TextStyle(color: AppColors.errorRed)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Quick Tasks Side Column
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Critical Tasks",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      tasksAsync.when(
                        data: (tasks) {
                          final activeTasks = tasks.where((t) => !t.completed).toList();
                          if (activeTasks.isEmpty) {
                            return const Center(child: Text("All tasks completed!", style: TextStyle(color: AppColors.textSecondary)));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeTasks.length > 5 ? 5 : activeTasks.length,
                            itemBuilder: (context, index) {
                              final task = activeTasks[index];
                              return Card(
                                color: AppColors.cardBg,
                                child: ListTile(
                                  leading: Checkbox(
                                    activeColor: AppColors.roseSpark,
                                    value: task.completed,
                                    onChanged: (val) async {
                                      final updated = Task(
                                        id: task.id,
                                        ownerId: task.ownerId,
                                        title: task.title,
                                        description: task.description,
                                        priority: task.priority,
                                        dueDate: task.dueDate,
                                        completed: val ?? false,
                                        completedAt: val == true ? DateTime.now() : null,
                                      );
                                      await ref.read(taskRepositoryProvider).saveTask(updated);
                                      ref.invalidate(tasksProvider);
                                    },
                                  ),
                                  title: Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text("Priority: ${task.priority == 4 ? 'Critical' : 'High'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text("Error: $err"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTimetable(List<TimeBlock> blocks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: blocks.length,
      itemBuilder: (context, idx) {
        final b = blocks[idx];
        final startStr = b.startTime != null ? DateFormat('HH:mm').format(b.startTime!) : '';
        final endStr = b.endTime != null ? DateFormat('HH:mm').format(b.endTime!) : '';
        final colorVal = int.tryParse(b.color ?? '0xFFFF4D80') ?? 0xFFFF4D80;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(endStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border(left: BorderSide(color: Color(colorVal), width: 4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (b.description != null && b.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(b.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                        onPressed: () async {
                          if (b.id != '1' && b.id != '2' && b.id != '3' && b.id != '4' && b.id != '5') {
                            await ref.read(timeBlockRepositoryProvider).deleteTimeBlock(b.id);
                            ref.invalidate(timeBlocksProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------------
// 13. Goals System Screen
// --------------------------------------------------------------------
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  void _showAddGoalModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddEditGoalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Goals & Milestones System"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.roseSpark),
            onPressed: _showAddGoalModal,
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            // Setup visual premium mock goals
            final mockGoals = [
              Goal(id: '1', title: 'Take Krisha to Japan', description: 'Plan a 2-week cherry blossom season tour across Tokyo, Kyoto, Osaka.', targetDate: DateTime.now().add(const Duration(days: 365)), progress: 0.4, status: 'in_progress'),
              Goal(id: '2', title: 'Save \$10,000 for Future', description: 'Establish our secure joint investment portfolio.', targetDate: DateTime.now().add(const Duration(days: 180)), progress: 0.65, status: 'in_progress'),
              Goal(id: '3', title: 'Learn Flutter & Supabase', description: 'Build premium multi-platform apps together.', targetDate: DateTime.now().add(const Duration(days: 90)), progress: 0.9, status: 'in_progress'),
            ];
            return _buildGoalsList(mockGoals);
          }
          return _buildGoalsList(goals);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          color: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (goal.description != null) ...[
                            const SizedBox(height: 4),
                            Text(goal.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                      onPressed: () async {
                        if (goal.id != '1' && goal.id != '2' && goal.id != '3') {
                          await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
                          ref.invalidate(goalsProvider);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          backgroundColor: AppColors.glassBorder,
                          color: AppColors.roseSpark,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${(goal.progress * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.goldAccent),
                        const SizedBox(width: 6),
                        Text(
                          goal.targetDate != null ? DateFormat('yyyy-MM-dd').format(goal.targetDate!) : 'No target date',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.auroraCyan.withOpacity(0.12),
                      foregroundColor: AppColors.auroraCyan,
                    ).onPressed(() {
                      _showMilestoneBottomSheet(goal);
                    }, label: "Milestones"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMilestoneBottomSheet(Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => GoalMilestonesDialog(goal: goal),
    );
  }
}

extension ElevatedButtonExtension on ButtonStyle {
  Widget onPressed(VoidCallback action, {required String label}) {
    return ElevatedButton(
      style: this,
      onPressed: action,
      child: Text(label),
    );
  }
}

// --------------------------------------------------------------------
// 14. Habits Tracker Screen
// --------------------------------------------------------------------
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  void _showAddHabitModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddEditHabitDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Habits & Rituals tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.roseSpark),
            onPressed: _showAddHabitModal,
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            final mockHabits = [
              Habit(id: '1', title: 'Drink 3L Water', description: 'Keep hydrated all day', targetFrequency: 7, streak: 12),
              Habit(id: '2', title: 'Workout / Gym', description: 'Weight lifting and core training', targetFrequency: 4, streak: 5),
              Habit(id: '3', title: 'Read 20 Pages', description: 'Expand focus and knowledge', targetFrequency: 7, streak: 8),
              Habit(id: '4', title: 'Message Krisha ❤️', description: 'Remind her that she is loved', targetFrequency: 7, streak: 45),
            ];
            return _buildHabitsGrid(mockHabits);
          }
          return _buildHabitsGrid(habits);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildHabitsGrid(List<Habit> habits) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Card(
          color: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        habit.title ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        if (habit.id != '1' && habit.id != '2' && habit.id != '3' && habit.id != '4') {
                          await ref.read(habitRepositoryProvider).deleteHabit(habit.id);
                          ref.invalidate(habitsProvider);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  habit.description ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${habit.streak} Days",
                          style: const TextStyle(color: AppColors.roseSpark, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text("Current Streak", style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseSpark,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () async {
                        final log = HabitLog(
                          id: generateUUID(),
                          habitId: habit.id,
                          completedDate: DateTime.now(),
                        );
                        await ref.read(habitRepositoryProvider).logHabit(log);
                        // Simply increment streak locally for instant visual reward
                        final updated = Habit(
                          id: habit.id,
                          ownerId: habit.ownerId,
                          title: habit.title,
                          description: habit.description,
                          targetFrequency: habit.targetFrequency,
                          streak: habit.streak + 1,
                        );
                        await ref.read(habitRepositoryProvider).saveHabit(updated);
                        ref.invalidate(habitsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Habit logged! Keep going.")),
                        );
                      },
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------------
// 15. Daily Tasks Screen
// --------------------------------------------------------------------
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddEditTaskDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Daily Task Registry"),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded, color: AppColors.roseSpark, size: 28),
            onPressed: _showAddTaskModal,
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            // Setup default tasks
            final mockTasks = [
              Task(id: '1', ownerId: '1', title: 'Complete Dart state management tutorial', priority: 4, dueDate: DateTime.now()),
              Task(id: '2', ownerId: '1', title: 'Plan our dates for this weekend', priority: 3, dueDate: DateTime.now().add(const Duration(days: 1))),
              Task(id: '3', ownerId: '1', title: 'Book anniversary tables', priority: 2, dueDate: DateTime.now().add(const Duration(days: 3))),
              Task(id: '4', ownerId: '1', title: 'Refill car fuel', priority: 1, dueDate: DateTime.now()),
            ];
            return _buildTasksList(mockTasks);
          }
          return _buildTasksList(tasks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    // Separate active and completed
    final active = tasks.where((t) => !t.completed).toList();
    final completed = tasks.where((t) => t.completed).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (active.isNotEmpty) ...[
          const Text("Active Tasks", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...active.map((t) => _buildTaskItem(t)),
          const SizedBox(height: 32),
        ],
        if (completed.isNotEmpty) ...[
          const Text("Completed Tasks", style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...completed.map((t) => _buildTaskItem(t)),
        ],
        if (active.isEmpty && completed.isEmpty)
          const Center(child: Text("No tasks currently. Tap '+' to create one.", style: TextStyle(color: AppColors.textSecondary))),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    Color priorityColor = Colors.white;
    switch (task.priority) {
      case 4: priorityColor = AppColors.errorRed; break;
      case 3: priorityColor = AppColors.goldAccent; break;
      case 2: priorityColor = AppColors.auroraCyan; break;
      case 1: priorityColor = AppColors.textSecondary; break;
    }

    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Checkbox(
          activeColor: AppColors.roseSpark,
          value: task.completed,
          onChanged: (val) async {
            final updated = Task(
              id: task.id,
              ownerId: task.ownerId,
              title: task.title,
              description: task.description,
              priority: task.priority,
              dueDate: task.dueDate,
              completed: val ?? false,
              completedAt: val == true ? DateTime.now() : null,
            );
            await ref.read(taskRepositoryProvider).saveTask(updated);
            ref.invalidate(tasksProvider);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.completed ? AppColors.textMuted : Colors.white,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                "Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate!)}",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
              onPressed: () async {
                if (task.id != '1' && task.id != '2' && task.id != '3' && task.id != '4') {
                  await ref.read(taskRepositoryProvider).deleteTask(task.id);
                  ref.invalidate(tasksProvider);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 16. Focus Session Screen
// --------------------------------------------------------------------
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _isRunning = false;
  int _selectedDuration = 25; // in minutes
  final _titleController = TextEditingController(text: "Deep Focus Session");
  final _notesController = TextEditingController();
  int _productivityScore = 4;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(minutes: _selectedDuration),
    );
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logSession();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _controller!.stop();
    } else {
      _controller!.forward();
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _controller!.reset();
    setState(() => _isRunning = false);
  }

  void _logSession() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final session = FocusSession(
        id: generateUUID(),
        ownerId: user.id,
        title: _titleController.text.trim(),
        startTime: DateTime.now().subtract(Duration(minutes: _selectedDuration)),
        endTime: DateTime.now(),
        durationMinutes: _selectedDuration,
        productivityScore: _productivityScore,
        notes: _notesController.text.trim(),
      );
      await ref.read(focusSessionRepositoryProvider).saveFocusSession(session);
      ref.invalidate(focusSessionsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Focus Session saved successfully!")),
      );
      _resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Focus Timer & Pomodoro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Circular Progress Indicator Timer Display
            Center(
              child: AnimatedBuilder(
                animation: _controller!,
                builder: (context, child) {
                  final progress = _controller!.value;
                  final totalSeconds = _selectedDuration * 60;
                  final remainingSeconds = (totalSeconds * (1.0 - progress)).round();
                  final min = (remainingSeconds / 60).floor();
                  final sec = (remainingSeconds % 60).round();
                  final timeStr = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: 1.0 - progress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.glassBorder,
                          color: AppColors.roseSpark,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          const Text("Remaining", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_rounded, size: 36, color: AppColors.textSecondary),
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? AppColors.errorRed : AppColors.roseSpark,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _toggleTimer,
                  child: Text(_isRunning ? "PAUSE" : "START FOCUS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.successGreen),
                  onPressed: _logSession,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Duration selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [25, 45, 60].map((dur) {
                final isSelected = _selectedDuration == dur;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text("$dur Min"),
                    selected: isSelected,
                    selectedColor: AppColors.roseSpark,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedDuration = dur;
                          _initController();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Logging Fields
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Session Configuration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Task Title", enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Self Notes / Reflection", enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder))),
                  ),
                  const SizedBox(height: 16),
                  const Text("Productivity Level (1-5)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Slider(
                    value: _productivityScore.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.roseSpark,
                    label: _productivityScore.toString(),
                    onChanged: (val) {
                      setState(() => _productivityScore = val.round());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 17. Memories Archive Screen
// --------------------------------------------------------------------
class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  void _showAddMemoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddMemoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Memory Vault & Stories"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.roseSpark),
            onPressed: _showAddMemoryModal,
          ),
        ],
      ),
      body: memoriesAsync.when(
        data: (memories) {
          if (memories.isEmpty) {
            return const Center(child: Text("Archive empty. Record your first memory together.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return Card(
                color: AppColors.cardBg,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              memory.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(memory.memoryDate),
                            style: const TextStyle(color: AppColors.roseSpark, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memory.story,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.auroraCyan),
                              const SizedBox(width: 4),
                              Text(memory.location ?? 'Everywhere', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.goldAccent),
                              const SizedBox(width: 4),
                              Text("Score: ${memory.importanceScore}/10", style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 18. Quote Vault Screen
// --------------------------------------------------------------------
class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  void _showAddQuoteModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddQuoteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("She Said Quote Vault"),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded, color: AppColors.roseSpark),
            onPressed: _showAddQuoteModal,
          ),
        ],
      ),
      body: quotesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return const Center(child: Text("Vault empty. Keep track of quotes she says.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final q = quotes[index];
              return Card(
                color: AppColors.cardBg,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.format_quote_rounded, color: AppColors.goldAccent, size: 32),
                  title: Text(
                    "\"${q.quote}\"",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Context: ${q.context ?? 'No context'} • Date: ${DateFormat('yyyy-MM-dd').format(q.quoteDate)}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 19. Preferences Screen
// --------------------------------------------------------------------
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  void _showAddPrefModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddPreferenceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Preferences Database"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.roseSpark),
            onPressed: _showAddPrefModal,
          ),
        ],
      ),
      body: prefsAsync.when(
        data: (prefs) {
          if (prefs.isEmpty) {
            return const Center(child: Text("No records saved yet.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: prefs.length,
            itemBuilder: (context, index) {
              final p = prefs[index];
              return Card(
                color: AppColors.cardBg,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(p.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Category: ${p.category} • Priority: ${p.priority ?? 'Medium'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (idx) => Icon(
                            Icons.star_rounded,
                            color: idx < p.rating ? AppColors.goldAccent : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                        onPressed: () async {
                          await ref.read(preferenceRepositoryProvider).deletePreference(p.id);
                          ref.invalidate(preferencesListProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 20. Social Matrix Screen
// --------------------------------------------------------------------
class SocialMatrixScreen extends ConsumerStatefulWidget {
  const SocialMatrixScreen({super.key});

  @override
  ConsumerState<SocialMatrixScreen> createState() => _SocialMatrixScreenState();
}

class _SocialMatrixScreenState extends ConsumerState<SocialMatrixScreen> {
  void _showAddSocialModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaViolet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddSocialPersonDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socialAsync = ref.watch(socialMatrixProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Social Matrix Mapper"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.roseSpark),
            onPressed: _showAddSocialModal,
          ),
        ],
      ),
      body: socialAsync.when(
        data: (people) {
          if (people.isEmpty) {
            return const Center(child: Text("Social matrix empty.", style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: people.length,
            itemBuilder: (context, index) {
              final p = people[index];
              final isLike = p.relationshipType == 'like';

              return Card(
                color: AppColors.cardBg,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: Icon(
                    isLike ? Icons.sentiment_very_satisfied_rounded : Icons.sentiment_very_dissatisfied_rounded,
                    color: isLike ? AppColors.successGreen : AppColors.errorRed,
                  ),
                  title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: ${p.reasonOrStatus ?? 'Standard'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    if (p.topicsOrGuidelines.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Guidelines / Conversation Topics:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: p.topicsOrGuidelines.map((topic) => Chip(label: Text(topic, style: const TextStyle(fontSize: 11)))).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                          onPressed: () async {
                            final client = ref.read(supabaseClientProvider);
                            await client.from('social_matrix').delete().eq('id', p.id);
                            ref.invalidate(socialMatrixProvider);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

// --------------------------------------------------------------------
// 21. Advanced Life Analytics Screen
// --------------------------------------------------------------------
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLogsAsync = ref.watch(timeLogsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Advanced Life Analytics")),
      body: timeLogsAsync.when(
        data: (timeLogs) {
          // Calculate time allocation from actual data
          final Map<String, double> categoryMinutes = {};
          for (var log in timeLogs) {
            final category = log.category ?? 'Other';
            categoryMinutes[category] = (categoryMinutes[category] ?? 0) + (log.durationMinutes ?? 0);
          }
          
          final totalMinutes = categoryMinutes.values.fold(0.0, (sum, val) => sum + val);
          final workMinutes = categoryMinutes['Work'] ?? 0;
          final healthMinutes = categoryMinutes['Health'] ?? 0;
          final krishaMinutes = categoryMinutes['Krisha Time'] ?? 0;
          final learningMinutes = categoryMinutes['Learning'] ?? 0;
          final otherMinutes = categoryMinutes['Other'] ?? 0;
          
          final workPercent = totalMinutes > 0 ? workMinutes / totalMinutes : 0.35;
          final healthPercent = totalMinutes > 0 ? healthMinutes / totalMinutes : 0.20;
          final krishaPercent = totalMinutes > 0 ? krishaMinutes / totalMinutes : 0.20;
          final learningPercent = totalMinutes > 0 ? learningMinutes / totalMinutes : 0.15;
          final otherPercent = totalMinutes > 0 ? otherMinutes / totalMinutes : 0.10;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Time Allocation Glass panels
                const Text(
                  "Category Time Allocation",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      AllocationRow(category: "Work / Study", percentage: workPercent, color: AppColors.auroraCyan),
                      const SizedBox(height: 12),
                      AllocationRow(category: "Health & Fitness", percentage: healthPercent, color: AppColors.successGreen),
                      const SizedBox(height: 12),
                      AllocationRow(category: "Krisha Time ❤️", percentage: krishaPercent, color: AppColors.roseSpark),
                      const SizedBox(height: 12),
                      AllocationRow(category: "Personal Growth & Learning", percentage: learningPercent, color: AppColors.goldAccent),
                      const SizedBox(height: 12),
                      AllocationRow(category: "Other & Sleep", percentage: otherPercent, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Row 2: Weekly Time Report
                const Text(
                  "Weekly Hours Spent Summary",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: StatCard(label: "Work", value: "${(workMinutes / 60).toStringAsFixed(1)} hrs", color: AppColors.auroraCyan)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: "Learning", value: "${(learningMinutes / 60).toStringAsFixed(1)} hrs", color: AppColors.goldAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: "Krisha", value: "${(krishaMinutes / 60).toStringAsFixed(1)} hrs", color: AppColors.roseSpark)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: StatCard(label: "Fitness", value: "${(healthMinutes / 60).toStringAsFixed(1)} hrs", color: AppColors.successGreen)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: "Other", value: "${(otherMinutes / 60).toStringAsFixed(1)} hrs", color: AppColors.violetAccent)),
                  ],
                ),
                const SizedBox(height: 32),

                // Row 3: Goals Progress
                const Text(
                  "Goals Progress Overview",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final goalsAsync = ref.watch(goalsProvider);
                    return goalsAsync.when(
                      data: (goals) {
                        if (goals.isEmpty) {
                          return const GlassCard(child: Text("No goals set yet", style: TextStyle(color: AppColors.textSecondary)));
                        }
                        return GlassCard(
                          child: Column(
                            children: goals.take(3).map((goal) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 14))),
                                      Text("${((goal.progress ?? 0) * 100).toInt()}%", style: const TextStyle(color: AppColors.auroraCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: goal.progress ?? 0,
                                      backgroundColor: AppColors.glassBorder,
                                      color: AppColors.auroraCyan,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const SizedBox(),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Row 4: Habit Streaks
                const Text(
                  "Current Habit Streaks",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final habitsAsync = ref.watch(habitsProvider);
                    return habitsAsync.when(
                      data: (habits) {
                        if (habits.isEmpty) {
                          return const GlassCard(child: Text("No habits tracked yet", style: TextStyle(color: AppColors.textSecondary)));
                        }
                        return Row(
                          children: habits.take(3).map((habit) {
                            return Expanded(
                              child: GlassCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.wb_sunny_rounded, color: AppColors.roseSpark, size: 32),
                                    const SizedBox(height: 8),
                                    Text(habit.title ?? "Habit", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("${habit.streak ?? 0} days", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const SizedBox(),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.errorRed))),
      ),
    );
  }
}

class AllocationRow extends StatelessWidget {
  final String category;
  final double percentage;
  final Color color;

  const AllocationRow({required this.category, required this.percentage, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text("${(percentage * 100).toInt()}%", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.glassBorder,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatCard({required this.label, required this.value, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// POPUP DIALOG IMPLEMENTATIONS
// --------------------------------------------------------------------

class AddTimeBlockDialog extends ConsumerStatefulWidget {
  const AddTimeBlockDialog({super.key});

  @override
  ConsumerState<AddTimeBlockDialog> createState() => _AddTimeBlockDialogState();
}

class _AddTimeBlockDialogState extends ConsumerState<AddTimeBlockDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController(text: "Work");
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  String _color = "0xFF00E5FF";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Time Block", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: _descController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Description")),
          TextField(controller: _categoryController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Category")),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() => _startTime = _startTime.copyWith(hour: time.hour, minute: time.minute));
                  }
                },
                child: Text("Start: ${DateFormat('HH:mm').format(_startTime)}"),
              ),
              TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() => _endTime = _endTime.copyWith(hour: time.hour, minute: time.minute));
                  }
                },
                child: Text("End: ${DateFormat('HH:mm').format(_endTime)}"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final block = TimeBlock(
                  id: generateUUID(),
                  ownerId: user.id,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  startTime: _startTime,
                  endTime: _endTime,
                  category: _categoryController.text.trim(),
                  color: _color,
                );
                await ref.read(timeBlockRepositoryProvider).saveTimeBlock(block);
                ref.invalidate(timeBlocksProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Time Block", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class DailyReflectionDialog extends ConsumerStatefulWidget {
  const DailyReflectionDialog({super.key});

  @override
  ConsumerState<DailyReflectionDialog> createState() => _DailyReflectionDialogState();
}

class _DailyReflectionDialogState extends ConsumerState<DailyReflectionDialog> {
  final _wins = TextEditingController();
  final _challenges = TextEditingController();
  final _gratitude = TextEditingController();
  final _lessons = TextEditingController();
  int _mood = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Daily Reflection Journal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _wins, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "What were your wins today?")),
          TextField(controller: _challenges, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Any challenges encountered?")),
          TextField(controller: _gratitude, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "What are you grateful for?")),
          TextField(controller: _lessons, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Lessons learned")),
          const SizedBox(height: 16),
          const Text("How was your mood today? (1-5)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Slider(
            value: _mood.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.roseSpark,
            label: _mood.toString(),
            onChanged: (val) => setState(() => _mood = val.round()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.auroraCyan, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final reflection = DailyReflection(
                  id: generateUUID(),
                  ownerId: user.id,
                  reflectionDate: DateTime.now(),
                  wins: _wins.text.trim(),
                  challenges: _challenges.text.trim(),
                  gratitude: _gratitude.text.trim(),
                  lessonsLearned: _lessons.text.trim(),
                  mood: _mood,
                );
                await ref.read(dailyReflectionRepositoryProvider).saveDailyReflection(reflection);
                ref.invalidate(dailyReflectionsProvider);
                ref.invalidate(globalTimelineProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Journal Reflection", style: TextStyle(color: AppColors.spaceDark)),
          ),
        ],
      ),
    );
  }
}

class AddEditGoalDialog extends ConsumerStatefulWidget {
  const AddEditGoalDialog({super.key});

  @override
  ConsumerState<AddEditGoalDialog> createState() => _AddEditGoalDialogState();
}

class _AddEditGoalDialogState extends ConsumerState<AddEditGoalDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Create New Goal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Goal Title")),
          TextField(controller: _descController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Description")),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(context: context, initialDate: _targetDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
              if (date != null) {
                setState(() => _targetDate = date);
              }
            },
            child: Text("Target Date: ${DateFormat('yyyy-MM-dd').format(_targetDate)}"),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final goal = Goal(
                  id: generateUUID(),
                  ownerId: user.id,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  targetDate: _targetDate,
                  progress: 0.0,
                  status: 'in_progress',
                );
                await ref.read(goalRepositoryProvider).saveGoal(goal);
                ref.invalidate(goalsProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Goal", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class GoalMilestonesDialog extends ConsumerStatefulWidget {
  final Goal goal;
  const GoalMilestonesDialog({required this.goal, super.key});

  @override
  ConsumerState<GoalMilestonesDialog> createState() => _GoalMilestonesDialogState();
}

class _GoalMilestonesDialogState extends ConsumerState<GoalMilestonesDialog> {
  final _milestoneTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final milestonesAsync = ref.watch(FutureProvider<List<GoalMilestone>>((ref) async {
      return await ref.read(goalRepositoryProvider).getMilestones(widget.goal.id);
    }));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Milestones: ${widget.goal.title}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _milestoneTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Add Step..."),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.auroraCyan),
                onPressed: () async {
                  if (_milestoneTitleController.text.isNotEmpty) {
                    final m = GoalMilestone(
                      id: generateUUID(),
                      goalId: widget.goal.id,
                      title: _milestoneTitleController.text.trim(),
                      completed: false,
                    );
                    await ref.read(goalRepositoryProvider).saveMilestone(m);
                    _milestoneTitleController.clear();
                    // Refetch
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          milestonesAsync.when(
            data: (list) {
              if (list.isEmpty) {
                // Return default mock list for visually premium goals initially
                if (widget.goal.id == '3') {
                  final mockList = [
                    GoalMilestone(id: '10', goalId: '3', title: 'Complete Dart Fundamentals', completed: true),
                    GoalMilestone(id: '11', goalId: '3', title: 'State Management (Riverpod)', completed: true),
                    GoalMilestone(id: '12', goalId: '3', title: 'Supabase Integration', completed: true),
                    GoalMilestone(id: '13', goalId: '3', title: 'Deploy to Production', completed: false),
                  ];
                  return _buildMilestoneList(mockList);
                }
                return const Text("No milestones recorded.", style: TextStyle(color: AppColors.textSecondary));
              }
              return _buildMilestoneList(list);
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text("Error: $err"),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneList(List<GoalMilestone> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final m = list[idx];
        return CheckboxListTile(
          title: Text(m.title ?? '', style: TextStyle(color: m.completed ? AppColors.textMuted : Colors.white, decoration: m.completed ? TextDecoration.lineThrough : null)),
          value: m.completed,
          onChanged: (val) async {
            final updated = GoalMilestone(
              id: m.id,
              goalId: m.goalId,
              title: m.title,
              completed: val ?? false,
              completedAt: val == true ? DateTime.now() : null,
            );
            await ref.read(goalRepositoryProvider).saveMilestone(updated);

            // Re-calculate goal progress on complete
            final allMilestones = await ref.read(goalRepositoryProvider).getMilestones(widget.goal.id);
            if (allMilestones.isNotEmpty) {
              final comp = allMilestones.where((x) => x.completed).length;
              final newProg = comp / allMilestones.length;
              final updatedGoal = Goal(
                id: widget.goal.id,
                ownerId: widget.goal.ownerId,
                categoryId: widget.goal.categoryId,
                title: widget.goal.title,
                description: widget.goal.description,
                targetDate: widget.goal.targetDate,
                progress: newProg,
                status: newProg == 1.0 ? 'completed' : 'in_progress',
              );
              await ref.read(goalRepositoryProvider).saveGoal(updatedGoal);
              ref.invalidate(goalsProvider);
            }

            setState(() {});
          },
        );
      },
    );
  }
}

class AddEditHabitDialog extends ConsumerStatefulWidget {
  const AddEditHabitDialog({super.key});

  @override
  ConsumerState<AddEditHabitDialog> createState() => _AddEditHabitDialogState();
}

class _AddEditHabitDialogState extends ConsumerState<AddEditHabitDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _targetFreq = 7;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Habit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Habit Title")),
          TextField(controller: _desc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Description")),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Frequency Per Week:", style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<int>(
                value: _targetFreq,
                items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1} Days"))),
                onChanged: (val) {
                  if (val != null) setState(() => _targetFreq = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final habit = Habit(
                  id: generateUUID(),
                  ownerId: user.id,
                  title: _title.text.trim(),
                  description: _desc.text.trim(),
                  targetFrequency: _targetFreq,
                  streak: 0,
                );
                await ref.read(habitRepositoryProvider).saveHabit(habit);
                ref.invalidate(habitsProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Habit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddEditTaskDialog extends ConsumerStatefulWidget {
  const AddEditTaskDialog({super.key});

  @override
  ConsumerState<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends ConsumerState<AddEditTaskDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _priority = 1;
  DateTime _dueDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Task", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Task Title")),
          TextField(controller: _desc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Task Description")),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Priority Level:", style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<int>(
                value: _priority,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Low")),
                  DropdownMenuItem(value: 2, child: Text("Medium")),
                  DropdownMenuItem(value: 3, child: Text("High")),
                  DropdownMenuItem(value: 4, child: Text("Critical")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _priority = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null) setState(() => _dueDate = date);
            },
            child: Text("Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate)}"),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final task = Task(
                  id: generateUUID(),
                  ownerId: user.id,
                  title: _title.text.trim(),
                  description: _desc.text.trim(),
                  priority: _priority,
                  dueDate: _dueDate,
                  completed: false,
                );
                await ref.read(taskRepositoryProvider).saveTask(task);
                ref.invalidate(tasksProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Task", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddMemoryDialog extends ConsumerStatefulWidget {
  const AddMemoryDialog({super.key});

  @override
  ConsumerState<AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends ConsumerState<AddMemoryDialog> {
  final _title = TextEditingController();
  final _story = TextEditingController();
  final _location = TextEditingController();
  int _score = 8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Record Memory Story", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: _story, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Write the memory story...")),
          TextField(controller: _location, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Location")),
          const SizedBox(height: 16),
          const Text("Importance Score (1-10)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Slider(
            value: _score.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.roseSpark,
            label: _score.toString(),
            onChanged: (val) => setState(() => _score = val.round()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final m = Memory(
                  id: generateUUID(),
                  userId: user.id,
                  title: _title.text.trim(),
                  story: _story.text.trim(),
                  memoryDate: DateTime.now(),
                  location: _location.text.trim(),
                  importanceScore: _score,
                  tags: ['love'],
                );
                await ref.read(memoryRepositoryProvider).saveMemory(m);
                ref.invalidate(memoriesListProvider);
                ref.invalidate(globalTimelineProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Memory", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddQuoteDialog extends ConsumerStatefulWidget {
  const AddQuoteDialog({super.key});

  @override
  ConsumerState<AddQuoteDialog> createState() => _AddQuoteDialogState();
}

class _AddQuoteDialogState extends ConsumerState<AddQuoteDialog> {
  final _quote = TextEditingController();
  final _context = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Log She Said Quote", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _quote, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Quote Statement")),
          TextField(controller: _context, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Context")),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final q = Quote(
                  id: generateUUID(),
                  userId: user.id,
                  quote: _quote.text.trim(),
                  quoteDate: DateTime.now(),
                  context: _context.text.trim(),
                  tags: ['quotes'],
                );
                await ref.read(quoteRepositoryProvider).saveQuote(q);
                ref.invalidate(quotesListProvider);
                ref.invalidate(globalTimelineProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Quote", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddPreferenceDialog extends ConsumerStatefulWidget {
  const AddPreferenceDialog({super.key});

  @override
  ConsumerState<AddPreferenceDialog> createState() => _AddPreferenceDialogState();
}

class _AddPreferenceDialogState extends ConsumerState<AddPreferenceDialog> {
  final _name = TextEditingController();
  final _category = TextEditingController(text: "Food");
  int _rating = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Item Preference", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Item Name")),
          TextField(controller: _category, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Category")),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Rating (1-5 Star):", style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<int>(
                value: _rating,
                items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1} Star"))),
                onChanged: (val) {
                  if (val != null) setState(() => _rating = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final p = Preference(
                  id: generateUUID(),
                  userId: user.id,
                  category: _category.text.trim(),
                  itemName: _name.text.trim(),
                  rating: _rating,
                );
                await ref.read(preferenceRepositoryProvider).savePreference(p);
                ref.invalidate(preferencesListProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Preference", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddSocialPersonDialog extends ConsumerStatefulWidget {
  const AddSocialPersonDialog({super.key});

  @override
  ConsumerState<AddSocialPersonDialog> createState() => _AddSocialPersonDialogState();
}

class _AddSocialPersonDialogState extends ConsumerState<AddSocialPersonDialog> {
  final _name = TextEditingController();
  final _status = TextEditingController();
  String _type = "like";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Social Person Connection", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: _status, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Status / Context")),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Relationship Type:", style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: "like", child: Text("Like")),
                  DropdownMenuItem(value: "dislike", child: Text("Dislike")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseSpark, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final client = ref.read(supabaseClientProvider);
                await client.from('social_matrix').insert({
                  'id': generateUUID(),
                  'user_id': user.id,
                  'name': _name.text.trim(),
                  'relationship_type': _type,
                  'reason_or_status': _status.text.trim(),
                });
                ref.invalidate(socialMatrixProvider);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Connection", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

