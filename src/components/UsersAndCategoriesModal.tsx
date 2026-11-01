import React, { useEffect, useState } from 'react';
import {
  AlertTriangle,
  Eye,
  EyeOff,
  FolderPlus,
  Shield,
  Trash2,
  UserCheck,
  UserPlus,
  UserX,
  X,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { getCategoryLabel } from '../i18n/translations';
import { CategoryItem, PublicUser, UserRole } from '../types/erp';
import { AppDomainError } from '../utils/errors';
import { ConfirmDialog } from './ConfirmDialog';

interface UsersAndCategoriesModalProps {
  isOpen: boolean;
  initialSection?: 'users' | 'categories';
  onClose: () => void;
}

export const UsersAndCategoriesModal: React.FC<
  UsersAndCategoriesModalProps
> = ({ isOpen, initialSection = 'users', onClose }) => {
  const {
    currentUser,
    users,
    loadUsers,
    createUser,
    updateUserStatus,
    deleteUser,
    state,
    t,
    createCategory,
    deleteCategory,
  } = useErpStore();

  const isAdmin = currentUser?.role === 'admin';
  const [section, setSection] = useState<'users' | 'categories'>(
    isAdmin ? initialSection : 'categories'
  );

  // Create User Form State
  const [newUsername, setNewUsername] = useState<string>('');
  const [newDisplayName, setNewDisplayName] = useState<string>('');
  const [newPassword, setNewPassword] = useState<string>('');
  const [showNewPassword, setShowNewPassword] = useState<boolean>(false);
  const [newRole, setNewRole] = useState<UserRole>('staff');

  // Create Category Form State
  const [newCategoryName, setNewCategoryName] = useState<string>('');

  const [modalError, setModalError] = useState<string | null>(null);
  const [isBusy, setIsBusy] = useState<boolean>(false);

  // Confirmation Dialog State
  const [userToDelete, setUserToDelete] = useState<PublicUser | null>(null);
  const [userToToggle, setUserToToggle] = useState<PublicUser | null>(null);
  const [categoryToDelete, setCategoryToDelete] = useState<CategoryItem | null>(
    null
  );

  useEffect(() => {
    if (!isOpen) return;
    setModalError(null);
    setSection(isAdmin ? initialSection : 'categories');
    if (isAdmin) {
      void loadUsers().catch((err) => {
        setModalError(
          err instanceof Error ? err.message : 'Failed to load user accounts.'
        );
      });
    }
  }, [isOpen, isAdmin, initialSection, loadUsers]);

  if (!isOpen) return null;

  const categories = state.categories ?? [];
  const activeAdminCount = users.filter(
    (u) => u.role === 'admin' && u.isActive
  ).length;

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setModalError(null);
    setIsBusy(true);
    try {
      await createUser({
        username: newUsername,
        displayName: newDisplayName,
        password: newPassword,
        role: newRole,
      });
      setNewUsername('');
      setNewDisplayName('');
      setNewPassword('');
      setNewRole('staff');
    } catch (err) {
      setModalError(
        err instanceof AppDomainError
          ? err.message
          : err instanceof Error
            ? err.message
            : 'Failed to create user.'
      );
    } finally {
      setIsBusy(false);
    }
  };

  const handleCreateCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    setModalError(null);
    setIsBusy(true);
    try {
      await createCategory({ name: newCategoryName });
      setNewCategoryName('');
    } catch (err) {
      setModalError(
        err instanceof AppDomainError
          ? err.message
          : err instanceof Error
            ? err.message
            : 'Failed to create category.'
      );
    } finally {
      setIsBusy(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-[#14171A]/50 p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="users-categories-modal-title"
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg flex flex-col shadow-lg"
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#ECEAE3] flex items-center justify-between gap-3 sticky top-0 bg-[#FFFFFF] z-10">
          <div>
            <h2
              id="users-categories-modal-title"
              className="text-lg font-bold text-[#14171A]"
            >
              Store Administration & Categories
            </h2>
            <p className="text-xs text-[#4A5056]">
              Manage pre-registered user accounts and material categories.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close modal"
            className="min-h-[36px] min-w-[36px] rounded-md flex items-center justify-center text-[#4A5056] hover:bg-[#F6F5F1]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Section Tabs */}
        <div className="px-5 pt-3 border-b border-[#ECEAE3] bg-[#F6F5F1] flex items-center gap-2">
          {isAdmin && (
            <button
              type="button"
              onClick={() => {
                setSection('users');
                setModalError(null);
              }}
              className={`px-3.5 py-2 text-xs font-semibold border-b-2 transition-colors flex items-center gap-1.5 ${
                section === 'users'
                  ? 'border-[#B84A14] text-[#B84A14]'
                  : 'border-transparent text-[#4A5056] hover:text-[#14171A]'
              }`}
            >
              <Shield className="w-3.5 h-3.5" />
              <span>Authorized Users ({users.length})</span>
            </button>
          )}
          <button
            type="button"
            onClick={() => {
              setSection('categories');
              setModalError(null);
            }}
            className={`px-3.5 py-2 text-xs font-semibold border-b-2 transition-colors flex items-center gap-1.5 ${
              section === 'categories'
                ? 'border-[#B84A14] text-[#B84A14]'
                : 'border-transparent text-[#4A5056] hover:text-[#14171A]'
            }`}
          >
            <FolderPlus className="w-3.5 h-3.5" />
            <span>Material Categories ({categories.length})</span>
          </button>
        </div>

        <div className="p-5 space-y-5">
          {modalError && (
            <div
              role="alert"
              className="rounded-md border border-[#B91C1C]/30 bg-[#FEF2F2] p-3 text-xs text-[#B91C1C] flex items-start gap-2"
            >
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{modalError}</span>
            </div>
          )}

          {section === 'users' && isAdmin ? (
            <div className="space-y-5">
              {/* Register Pre-Registered User Form */}
              <form
                onSubmit={(e) => void handleCreateUser(e)}
                className="p-4 rounded-md bg-[#F6F5F1] border border-[#DCD9D0] space-y-3"
              >
                <h3 className="text-xs font-bold uppercase tracking-wider text-[#14171A] flex items-center gap-1.5">
                  <UserPlus className="w-3.5 h-3.5 text-[#B84A14]" />
                  <span>Provision Pre-Registered User Account</span>
                </h3>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label
                      htmlFor="admin-new-username"
                      className="block text-xs font-semibold text-[#14171A] mb-1"
                    >
                      Username / Email *
                    </label>
                    <input
                      id="admin-new-username"
                      type="text"
                      required
                      value={newUsername}
                      onChange={(e) => setNewUsername(e.target.value)}
                      placeholder="e.g., cashier1"
                      className="w-full min-h-[38px] px-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor="admin-new-display-name"
                      className="block text-xs font-semibold text-[#14171A] mb-1"
                    >
                      Display Name
                    </label>
                    <input
                      id="admin-new-display-name"
                      type="text"
                      value={newDisplayName}
                      onChange={(e) => setNewDisplayName(e.target.value)}
                      placeholder="e.g., Abebe (Counter POS)"
                      className="w-full min-h-[38px] px-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor="admin-new-password"
                      className="block text-xs font-semibold text-[#14171A] mb-1"
                    >
                      Initial Password (min 6 chars) *
                    </label>
                    <div className="relative">
                      <input
                        id="admin-new-password"
                        type={showNewPassword ? 'text' : 'password'}
                        required
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        placeholder="Strong password"
                        className="w-full min-h-[38px] pl-3 pr-9 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md"
                      />
                      <button
                        type="button"
                        onClick={() => setShowNewPassword((p) => !p)}
                        aria-label={
                          showNewPassword ? 'Hide password' : 'Show password'
                        }
                        className="absolute right-1.5 top-1/2 -translate-y-1/2 p-1 text-[#4A5056]"
                      >
                        {showNewPassword ? (
                          <EyeOff className="w-3.5 h-3.5" />
                        ) : (
                          <Eye className="w-3.5 h-3.5" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div>
                    <label
                      htmlFor="admin-new-role"
                      className="block text-xs font-semibold text-[#14171A] mb-1"
                    >
                      Role *
                    </label>
                    <select
                      id="admin-new-role"
                      value={newRole}
                      onChange={(e) => setNewRole(e.target.value as UserRole)}
                      className="w-full min-h-[38px] px-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md"
                    >
                      <option value="staff">Staff (POS, Stock-In, Audit)</option>
                      <option value="admin">Administrator (Full Access)</option>
                    </select>
                  </div>
                </div>

                <div className="flex justify-end">
                  <button
                    type="submit"
                    disabled={isBusy}
                    className="min-h-[38px] px-4 py-1.5 text-xs font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] disabled:opacity-50"
                  >
                    Create Authorized User
                  </button>
                </div>
              </form>

              {/* Users List */}
              <div className="border border-[#DCD9D0] rounded-md divide-y divide-[#ECEAE3]">
                {users.map((u) => {
                  const isLastActiveAdmin =
                    u.role === 'admin' && u.isActive && activeAdminCount <= 1;

                  return (
                    <div
                      key={u.id}
                      className="p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                    >
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-bold text-[#14171A]">
                            {u.displayName}
                          </span>
                          <span className="text-xs font-mono-tabular text-[#6E757C]">
                            (@{u.username})
                          </span>
                          <span className="text-[11px] font-semibold uppercase text-[#B84A14]">
                            · {u.role}
                          </span>
                          <span
                            className={`text-[11px] font-semibold ${
                              u.isActive ? 'text-[#166534]' : 'text-[#B91C1C]'
                            }`}
                          >
                            · {u.isActive ? 'Active' : 'Deactivated'}
                          </span>
                        </div>
                        {isLastActiveAdmin && (
                          <p className="text-[11px] text-[#6E757C] mt-0.5">
                            Protected: Last active administrator account cannot
                            be deactivated or deleted.
                          </p>
                        )}
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        <button
                          type="button"
                          onClick={() => setUserToToggle(u)}
                          className="min-h-[34px] px-2.5 py-1 text-xs font-medium rounded border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1"
                        >
                          {u.isActive ? (
                            <>
                              <UserX className="w-3.5 h-3.5 text-[#9A3412]" />
                              <span>Deactivate</span>
                            </>
                          ) : (
                            <>
                              <UserCheck className="w-3.5 h-3.5 text-[#166534]" />
                              <span>Activate</span>
                            </>
                          )}
                        </button>

                        <button
                          type="button"
                          onClick={() => setUserToDelete(u)}
                          aria-label={`Delete user ${u.username}`}
                          className="min-h-[34px] px-2.5 py-1 text-xs font-medium rounded border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] flex items-center gap-1"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          <span>Delete</span>
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            /* Categories Management Section */
            <div className="space-y-5">
              <form
                onSubmit={(e) => void handleCreateCategory(e)}
                className="p-4 rounded-md bg-[#F6F5F1] border border-[#DCD9D0] flex flex-col sm:flex-row gap-3 sm:items-end"
              >
                <div className="flex-1">
                  <label
                    htmlFor="new-category-name-input"
                    className="block text-xs font-semibold text-[#14171A] mb-1"
                  >
                    New Category Name *
                  </label>
                  <input
                    id="new-category-name-input"
                    type="text"
                    required
                    value={newCategoryName}
                    onChange={(e) => setNewCategoryName(e.target.value)}
                    placeholder="e.g., Plumbing, Electrical, Sanitaryware"
                    className="w-full min-h-[38px] px-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md"
                  />
                </div>
                <button
                  type="submit"
                  disabled={isBusy}
                  className="min-h-[38px] px-4 py-1.5 text-xs font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E]"
                >
                  Add Category
                </button>
              </form>

              <div className="border border-[#DCD9D0] rounded-md divide-y divide-[#ECEAE3]">
                {categories.map((cat) => {
                  const usedCount = state.materials.filter(
                    (m) => m.category === cat.id
                  ).length;

                  return (
                    <div
                      key={cat.id}
                      className="p-3.5 flex items-center justify-between gap-3"
                    >
                      <div>
                        <span className="text-sm font-semibold text-[#14171A]">
                          {getCategoryLabel(t, cat.id, categories)}
                        </span>
                        <span className="text-xs font-mono-tabular text-[#6E757C] ml-2">
                          ({usedCount} {t.dashboard.itemsCountLabel})
                        </span>
                      </div>

                      <button
                        type="button"
                        onClick={() => setCategoryToDelete(cat)}
                        aria-label={`Delete category ${cat.name}`}
                        className="min-h-[34px] px-2.5 py-1 text-xs font-medium rounded border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] flex items-center gap-1"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Delete</span>
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Confirm User Status Toggle */}
      <ConfirmDialog
        isOpen={userToToggle !== null}
        title={
          userToToggle?.isActive
            ? 'Deactivate Authorized User'
            : 'Activate Authorized User'
        }
        recordName={
          userToToggle
            ? `${userToToggle.displayName} (@${userToToggle.username})`
            : ''
        }
        description={
          userToToggle?.isActive
            ? 'Deactivating this user will immediately revoke their active sessions and prevent them from signing in.'
            : 'Activating this user will allow them to sign in with their pre-registered credentials.'
        }
        prohibitedExplanation={
          userToToggle &&
          userToToggle.role === 'admin' &&
          userToToggle.isActive &&
          activeAdminCount <= 1
            ? 'Note: Deactivating the last active administrator account is prohibited.'
            : undefined
        }
        confirmLabel={userToToggle?.isActive ? 'Deactivate User' : 'Activate User'}
        variant={userToToggle?.isActive ? 'warning' : 'primary'}
        onConfirm={async () => {
          if (!userToToggle) return;
          await updateUserStatus(userToToggle.id, !userToToggle.isActive);
        }}
        onClose={() => setUserToToggle(null)}
      />

      {/* Confirm User Delete */}
      <ConfirmDialog
        isOpen={userToDelete !== null}
        title="Delete Authorized User Account"
        recordName={
          userToDelete
            ? `${userToDelete.displayName} (@${userToDelete.username})`
            : ''
        }
        description="Are you sure you want to permanently remove this user account?"
        prohibitedExplanation={
          userToDelete &&
          userToDelete.role === 'admin' &&
          userToDelete.isActive &&
          activeAdminCount <= 1
            ? 'Deletion Prohibited: Cannot delete the last active administrator account.'
            : undefined
        }
        confirmLabel="Delete User"
        variant="danger"
        onConfirm={async () => {
          if (!userToDelete) return;
          await deleteUser(userToDelete.id);
        }}
        onClose={() => setUserToDelete(null)}
      />

      {/* Confirm Category Delete */}
      <ConfirmDialog
        isOpen={categoryToDelete !== null}
        title="Delete Material Category"
        recordName={categoryToDelete ? categoryToDelete.name : ''}
        description="Categories can only be deleted when no existing materials are assigned to them."
        prohibitedExplanation={
          categoryToDelete &&
          state.materials.some((m) => m.category === categoryToDelete.id)
            ? `Deletion Prohibited: This category is currently used by ${
                state.materials.filter((m) => m.category === categoryToDelete.id)
                  .length
              } material(s). Reassign or remove those materials first.`
            : undefined
        }
        confirmLabel="Delete Category"
        variant="danger"
        onConfirm={async () => {
          if (!categoryToDelete) return;
          await deleteCategory(categoryToDelete.id);
        }}
        onClose={() => setCategoryToDelete(null)}
      />
    </div>
  );
};
