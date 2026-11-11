import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/services/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/wordmark.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _demoUsed = false;
  StreamSubscription<AuthState>? _authSub;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDemoState();
    if (Env.hasSupabase) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.signedIn) {
          _afterAuth();
        }
      });
    }
  }

  Future<void> _loadDemoState() async {
    final used = await Prefs.demoUsed();
    if (mounted) setState(() => _demoUsed = used);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterAuth() async {
    final role = await resolveCurrentRole();
    ref.read(appRoleProvider.notifier).setRole(role);
    ref.read(currentUserProvider.notifier).setUser(await resolveCurrentUser());
    final savedMode = await Prefs.savedMode();
    if (savedMode != null) {
      ref.read(appModeProvider.notifier).setMode(savedMode);
    }
    final onboardingDone = await Prefs.onboardingDone();
    if (!mounted) return;
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (role == AppRole.therapist) {
      context.go(AppRoutes.therapist);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (Env.hasSupabase) {
      try {
        final client = Supabase.instance.client;
        if (_isLogin) {
          await client.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          final result = await client.auth.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            data: {'full_name': _nameController.text.trim()},
          );
          if (result.session == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Akun dibuat. Cek email untuk konfirmasi, lalu masuk.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
        await _afterAuth();
      } catch (e) {
        if (!mounted) return;
        _showError(_isLogin ? 'Gagal masuk: $e' : 'Gagal mendaftar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _afterAuth();
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (!Env.hasSupabase) {
      _showError(
        'Login Google butuh Supabase. Isi SUPABASE_URL & SUPABASE_ANON_KEY dulu.',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.formly://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) _showError('Gagal login Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoLogin() async {
    if (_demoUsed) {
      _showError('Mode demo hanya bisa dicoba sekali. Silakan masuk/daftar.');
      return;
    }
    await Prefs.markDemoUsed();
    if (!mounted) return;
    setState(() => _demoUsed = true);
    ref.read(appRoleProvider.notifier).setRole(AppRole.self);
    context.go(AppRoutes.onboarding);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Wordmark(fontSize: 36),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Selamat datang kembali'
                      : 'Mulai perjalanan latihanmu',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 26),
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Masuk' : 'Daftar Akun',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nama Lengkap',
                            hint: 'cth: Raka Pratama',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'nama@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!v.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Kata Sandi',
                          hint: 'Minimal 6 karakter',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.mutedForeground,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        GlassButton(
                          label: _isLogin ? 'Masuk' : 'Daftar',
                          loading: _isLoading,
                          size: GlassButtonSize.large,
                          expand: true,
                          onPressed: _handleSubmit,
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _GoogleButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text.rich(
                            TextSpan(
                              text: _isLogin
                                  ? 'Belum punya akun? '
                                  : 'Sudah punya akun? ',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin ? 'Daftar' : 'Masuk',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _demoUsed ? null : _handleDemoLogin,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: Text(
                    _demoUsed
                        ? 'Mode demo sudah dipakai'
                        : 'Masuk Mode Demo (sekali coba)',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedForeground,
                    disabledForegroundColor: AppColors.mutedForeground
                        .withValues(alpha: 0.4),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 14.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: AppColors.mutedForeground,
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: AppColors.mutedForeground,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleMark(),
                SizedBox(width: 10),
                Text(
                  'Lanjutkan dengan Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
