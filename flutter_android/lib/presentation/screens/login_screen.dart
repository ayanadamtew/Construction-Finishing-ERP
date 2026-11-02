import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../l10n/erp_localizations.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-00` — Redesigned Pre-Registered User Login Screen
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
        backgroundColor: ErpColors.surfaceCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ErpColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.architecture_rounded,
                size: 18,
                color: ErpColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    i18n.t('appTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  Text(
                    i18n.t('appSubtitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: ErpColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: i18n.t('languageSettingTitle'),
            onSelected: controller.setLanguage,
            itemBuilder: (_) => AppLanguage.values
                .map(
                  (lang) => PopupMenuItem(
                    value: lang,
                    child: Text('${lang.shortBadge} — ${lang.nativeName}'),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ErpColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 15,
                      color: ErpColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      viewState.language.shortBadge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ErpColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ErpColors.borderSubtle),
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
                          color: ErpColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: ErpColors.primaryDark,
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
                                fontSize: 16.5,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: ErpColors.statusDanger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _localError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ErpInputField(
                    controller: _usernameCtrl,
                    label: i18n.t('loginUsernameOrEmail'),
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  ErpInputField(
                    controller: _passwordCtrl,
                    label: i18n.t('loginPassword'),
                    prefixIcon: Icons.key_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitLogin(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                        color: ErpColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  ErpButton(
                    label: i18n.t('btnSignIn'),
                    icon: Icons.login_rounded,
                    variant: ErpButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: _isSubmitting ? null : _submitLogin,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ErpColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: ErpColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            i18n.t('loginNoPublicSignupNotice'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: ErpColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
