import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'confirm_action_dialog.dart';

/// `SCR-08` — Redesigned Administrator User & Category Management Modal Sheet
class AdminManagementSheet extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const AdminManagementSheet({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: ErpColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AdminManagementSheet(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  ConsumerState<AdminManagementSheet> createState() =>
      _AdminManagementSheetState();
}

class _AdminManagementSheetState extends ConsumerState<AdminManagementSheet> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.staff;
  bool _obscureNewPassword = true;

  final _catCodeCtrl = TextEditingController();
  final _catNameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _catCodeCtrl.dispose();
    _catNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final users = viewState.publicUsers;
    final categories = viewState.erpState.categories;
    final currentUser = viewState.currentUser;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ErpColors.borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    i18n.t('adminPanelTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ErpColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            labelColor: ErpColors.primaryDark,
            unselectedLabelColor: ErpColors.textSecondary,
            indicatorColor: ErpColors.primary,
            tabs: [
              Tab(text: '${i18n.t('tabUsers')} (${users.length})'),
              Tab(text: '${i18n.t('tabCategories')} (${categories.length})'),
            ],
          ),
          const Divider(height: 1, color: ErpColors.borderSubtle),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Pre-Registered Users Management
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ErpColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            i18n.t('btnCreateUser'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ErpInputField(
                                  controller: _usernameCtrl,
                                  label: i18n.t('fieldUsername'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ErpInputField(
                                  controller: _emailCtrl,
                                  label: i18n.t('fieldEmail'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ErpInputField(
                                  controller: _fullNameCtrl,
                                  label: i18n.t('fieldFullName'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<UserRole>(
                                  initialValue: _selectedRole,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldRole'),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: UserRole.staff,
                                      child: Text(
                                        i18n.t('roleStaff'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: UserRole.admin,
                                      child: Text(
                                        i18n.t('roleAdmin'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedRole = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ErpInputField(
                            controller: _passwordCtrl,
                            obscureText: _obscureNewPassword,
                            label: i18n.t('fieldPassword'),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          ErpButton(
                            label: i18n.t('btnCreateUser'),
                            icon: Icons.person_add_alt_1_rounded,
                            isFullWidth: true,
                            onPressed: () async {
                              final ok = await controller.createUser(
                                CreateUserInput(
                                  username: _usernameCtrl.text,
                                  email: _emailCtrl.text,
                                  fullName: _fullNameCtrl.text,
                                  role: _selectedRole,
                                  password: _passwordCtrl.text,
                                ),
                              );
                              if (ok) {
                                _usernameCtrl.clear();
                                _emailCtrl.clear();
                                _fullNameCtrl.clear();
                                _passwordCtrl.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...users.map((u) {
                      final isSelf = currentUser?.id == u.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ErpColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ErpColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          u.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ErpStatusLabel(
                                        text: u.role.code.toUpperCase(),
                                        textColor: u.role == UserRole.admin
                                            ? ErpColors.primaryDark
                                            : ErpColors.textSecondary,
                                        backgroundColor: u.role == UserRole.admin
                                            ? ErpColors.primaryLight
                                            : ErpColors.surfaceElevated,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u.username} • ${u.email}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: ErpColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isSelf) ...[
                              TextButton(
                                onPressed: () => controller.toggleUserStatus(
                                  u.id,
                                  !u.isActive,
                                ),
                                child: Text(
                                  u.isActive
                                      ? i18n.t('btnDeactivate')
                                      : i18n.t('btnActivate'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 19,
                                  color: ErpColors.statusDanger,
                                ),
                                onPressed: () async {
                                  final res = await ConfirmActionDialog.show(
                                    context,
                                    title: i18n.t('confirmDeleteTitle'),
                                    recordName:
                                        '${u.fullName} (@${u.username})',
                                    description:
                                        'Permanently remove this authorized user account?',
                                    confirmLabel: i18n.t('btnDelete'),
                                    i18n: i18n,
                                  );
                                  if (res != null && res.confirmed) {
                                    await controller.deleteUser(u.id);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                // Tab 2: Categories Management
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ErpColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ErpInputField(
                                  controller: _catCodeCtrl,
                                  label: i18n.t('fieldCategoryCode'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ErpInputField(
                                  controller: _catNameCtrl,
                                  label: i18n.t('fieldCategoryName'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ErpButton(
                            label: i18n.t('btnAddCategory'),
                            icon: Icons.add_rounded,
                            isFullWidth: true,
                            onPressed: () async {
                              final ok = await controller.createCategory(
                                CreateCategoryInput(
                                  code: _catCodeCtrl.text,
                                  name: _catNameCtrl.text,
                                ),
                              );
                              if (ok) {
                                _catCodeCtrl.clear();
                                _catNameCtrl.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...categories.map((cat) {
                      final usageCount = viewState.erpState.materials
                          .where((m) => m.effectiveCategoryCode == cat.code)
                          .length;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ErpColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ErpColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${cat.code} • Used by $usageCount material(s)',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: ErpColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!cat.isSystem)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 19,
                                  color: usageCount > 0
                                      ? ErpColors.textMuted
                                      : ErpColors.statusDanger,
                                ),
                                onPressed: () async {
                                  if (usageCount > 0) {
                                    await controller.deleteCategory(cat.id);
                                    return;
                                  }
                                  final res = await ConfirmActionDialog.show(
                                    context,
                                    title: i18n.t('confirmDeleteTitle'),
                                    recordName: '${cat.name} (${cat.code})',
                                    description:
                                        'Permanently delete this custom material category?',
                                    confirmLabel: i18n.t('btnDelete'),
                                    i18n: i18n,
                                  );
                                  if (res != null && res.confirmed) {
                                    await controller.deleteCategory(cat.id);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
