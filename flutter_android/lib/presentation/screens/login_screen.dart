import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../l10n/erp_localizations.dart';
import '../providers/erp_providers.dart';

/// `SCR-00` — Pre-Registered User Login Screen (`FR-021`–`FR-025`, `BR-009`).
/// Strictly enforces pre-registered credentials with NO public sign-up option.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _localError;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final usernameOrEmail = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'Please enter both username/email and password.';
      });
      return;
    }

    setState(() {
      _localError = null;
      _isSubmitting = true;
    });

    final controller = ref.read(erpControllerProvider.notifier);
    final ok = await controller.login(usernameOrEmail, password);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (!ok) {
        final err = ref.read(erpControllerProvider).bannerMessage;
        setState(() {
          _localError = err ?? 'Invalid username/email or password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;

    return Scaffold(
      backgroundColor: ErpColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: ErpColors.textPrimary,
        foregroundColor: Colors.white,
        title: Text(
          i18n.t('appTitle'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: AppLanguage.values.map((lang) {
                final active = viewState.language == lang;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => controller.setLanguage(lang),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? ErpColors.accentTerracotta
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: active
                              ? ErpColors.accentTerracotta
                              : const Color(0xFF57534E),
                        ),
                      ),
                      child: Text(
                        lang.shortBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ErpColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ErpColors.borderStrong),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ErpColors.accentTerracotta,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i18n.t('loginTitle'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ErpColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i18n.t('loginSubtitle'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ErpColors.statusDangerBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.statusDanger),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: ErpColors.statusDanger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _localError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _usernameCtrl,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: i18n.t('loginUsernameOrEmail'),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitLogin(),
                    decoration: InputDecoration(
                      labelText: i18n.t('loginPassword'),
                      prefixIcon: const Icon(Icons.key_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ErpColors.accentTerracotta,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _isSubmitting ? null : _submitLogin,
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(
                      i18n.t('btnSignIn'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
