import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';
import 'confirm_action_dialog.dart';

/// `SCR-08` — Administrator User & Category Management Modal Sheet (`FR-025`, `FR-028`, `BR-010`, `BR-012`).
class AdminManagementSheet extends ConsumerStatefulWidget {
  const AdminManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ErpColors.surfaceCard,
      builder: (_) => const SizedBox(
        height: 620,
        child: AdminManagementSheet(),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
            color: ErpColors.textPrimary,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        i18n.t('adminPanelTitle'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFFD6D3CD),
                  indicatorColor: ErpColors.accentTerracotta,
                  tabs: [
                    Tab(text: '${i18n.t('tabUsers')} (${users.length})'),
                    Tab(
                      text: '${i18n.t('tabCategories')} (${categories.length})',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Pre-Registered Users Management
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ErpColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            i18n.t('btnCreateUser'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _usernameCtrl,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldUsername'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _emailCtrl,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldEmail'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _fullNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldFullName'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<UserRole>(
                                  value: _selectedRole,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldRole'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: UserRole.staff,
                                      child: Text(i18n.t('roleStaff')),
                                    ),
                                    DropdownMenuItem(
                                      value: UserRole.admin,
                                      child: Text(i18n.t('roleAdmin')),
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
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: i18n.t('fieldPassword'),
                              isDense: true,
                              border: const OutlineInputBorder(),
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
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ErpColors.accentTerracotta,
                              foregroundColor: Colors.white,
                            ),
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
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(i18n.t('btnCreateUser')),
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
                          borderRadius: BorderRadius.circular(6),
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
                                      Text(
                                        u.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: u.role == UserRole.admin
                                              ? ErpColors.statusWarningBg
                                              : ErpColors.surfaceElevated,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          u.role.code.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${u.username} • ${u.email}',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: ErpColors.statusDanger,
                                ),
                                onPressed: () async {
                                  final res = await ConfirmActionDialog.show(
                                    context,
                                    title: i18n.t('confirmDeleteTitle'),
                                    recordName: '${u.fullName} (@${u.username})',
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ErpColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _catCodeCtrl,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldCategoryCode'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _catNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: i18n.t('fieldCategoryName'),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ErpColors.accentTerracotta,
                              foregroundColor: Colors.white,
                            ),
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
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(i18n.t('btnAddCategory')),
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
                          borderRadius: BorderRadius.circular(6),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Code: ${cat.code} • Used by $usageCount material(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
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
