import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  createInitialErpState,
  materialHasTransactions,
  round2,
} from '../domain/inventoryEngine';
import { TRANSLATIONS, TranslationDictionary } from '../i18n/translations';
import {
  erpApiClient,
  getStoredAuthToken,
  setStoredAuthToken,
} from '../services/apiClient';
import {
  AppRouteTab,
  CategoryItem,
  CreateAuditInput,
  CreateCategoryInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateStockInInput,
  CreateUserInput,
  DraftPosCartItem,
  ErpState,
  LanguageCode,
  LoginInput,
  Material,
  PublicUser,
  SaleTransaction,
  StockAuditRecord,
  StockInRecord,
  UpdateMaterialInput,
} from '../types/erp';
import { AppDomainError } from '../utils/errors';

interface ErpContextValue {
  // Auth & User State
  currentUser: PublicUser | null;
  isAuthChecking: boolean;
  login: (input: LoginInput) => Promise<PublicUser>;
  logout: () => Promise<void>;
  users: PublicUser[];
  loadUsers: () => Promise<PublicUser[]>;
  createUser: (input: CreateUserInput) => Promise<PublicUser>;
  updateUserStatus: (userId: string, isActive: boolean) => Promise<PublicUser>;
  deleteUser: (userId: string) => Promise<void>;
  // Store State & Navigation
  state: ErpState;
  activeTab: AppRouteTab;
  setActiveTab: (tab: AppRouteTab) => void;
  language: LanguageCode;
  setLanguage: (lang: LanguageCode) => void;
  t: TranslationDictionary;
  isLoading: boolean;
  error: AppDomainError | null;
  clearError: () => void;
  successMessage: string | null;
  clearSuccessMessage: () => void;
  refreshState: () => Promise<void>;
  // Material & Category Actions
  createMaterial: (input: CreateMaterialInput) => Promise<Material>;
  updateMaterial: (id: string, input: UpdateMaterialInput) => Promise<Material>;
  deleteMaterial: (id: string) => Promise<void>;
  setMaterialArchived: (id: string, isArchived: boolean) => Promise<Material>;
  hasTransactionsForMaterial: (materialId: string) => boolean;
  createCategory: (input: CreateCategoryInput) => Promise<CategoryItem>;
  deleteCategory: (categoryId: string) => Promise<void>;
  // POS Cart State & Actions
  posCart: DraftPosCartItem[];
  posCustomerNote: string;
  setPosCustomerNote: (note: string) => void;
  addToPosCart: (materialId: string) => void;
  updatePosCartQuantity: (materialId: string, quantityInput: string) => void;
  updatePosCartUnitPrice: (materialId: string, unitPriceInput: string) => void;
  removeFromPosCart: (materialId: string) => void;
  clearPosCart: () => void;
  submitPosSale: () => Promise<SaleTransaction>;
  reverseSale: (saleId: string, reason: string) => Promise<SaleTransaction>;
  lastCompletedSale: SaleTransaction | null;
  clearLastCompletedSale: () => void;
  // Stock-In State & Actions
  selectedStockInMaterialId: string;
  setSelectedStockInMaterialId: (materialId: string) => void;
  openStockInForMaterial: (materialId: string) => void;
  submitStockIn: (input: CreateStockInInput) => Promise<StockInRecord>;
  reverseStockIn: (stockInId: string, reason: string) => Promise<StockInRecord>;
  // Ground-Stock Audit Actions
  submitStockAudit: (input: CreateAuditInput) => Promise<StockAuditRecord>;
  reverseAudit: (auditId: string, reason: string) => Promise<StockAuditRecord>;
}

const ErpContext = createContext<ErpContextValue | null>(null);

export const ErpProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [currentUser, setCurrentUser] = useState<PublicUser | null>(null);
  const [isAuthChecking, setIsAuthChecking] = useState<boolean>(true);
  const [users, setUsers] = useState<PublicUser[]>([]);

  const [state, setState] = useState<ErpState>(() => createInitialErpState());
  const [activeTab, setActiveTab] = useState<AppRouteTab>('dashboard');
  const [language, setLanguage] = useState<LanguageCode>('en');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<AppDomainError | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const [posCart, setPosCart] = useState<DraftPosCartItem[]>([]);
  const [posCustomerNote, setPosCustomerNote] = useState<string>('');
  const [lastCompletedSale, setLastCompletedSale] =
    useState<SaleTransaction | null>(null);

  const [selectedStockInMaterialId, setSelectedStockInMaterialId] =
    useState<string>('');

  const t = TRANSLATIONS[language];

  const handlePossibleAuthExpiry = useCallback((err: unknown) => {
    if (
      err instanceof AppDomainError &&
      (err.code === 'UNAUTHORIZED' || err.code === 'ACCOUNT_DEACTIVATED')
    ) {
      setStoredAuthToken(null);
      setCurrentUser(null);
    }
  }, []);

  const refreshState = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const remoteState = await erpApiClient.fetchStoreState();
      setState(remoteState);
      const activeMaterials = remoteState.materials.filter(
        (m) => !m.isArchived
      );
      if (activeMaterials.length > 0) {
        setSelectedStockInMaterialId((prev) =>
          prev && activeMaterials.some((m) => m.id === prev)
            ? prev
            : activeMaterials[0].id
        );
      }
    } catch (err) {
      handlePossibleAuthExpiry(err);
      const domainErr =
        err instanceof AppDomainError
          ? err
          : new AppDomainError(
              'INTERNAL_ERROR',
              err instanceof Error ? err.message : 'Failed to load store state.'
            );
      setError(domainErr);
    } finally {
      setIsLoading(false);
    }
  }, [handlePossibleAuthExpiry]);

  // Restore session on startup if a token is stored in localStorage
  useEffect(() => {
    let isMounted = true;
    const restoreSession = async () => {
      const token = getStoredAuthToken();
      if (!token) {
        if (isMounted) setIsAuthChecking(false);
        return;
      }
      try {
        const { user } = await erpApiClient.fetchCurrentUser();
        if (!isMounted) return;
        setCurrentUser(user);
        await refreshState();
      } catch {
        setStoredAuthToken(null);
        if (isMounted) setCurrentUser(null);
      } finally {
        if (isMounted) setIsAuthChecking(false);
      }
    };
    void restoreSession();
    return () => {
      isMounted = false;
    };
  }, [refreshState]);

  const login = useCallback(
    async (input: LoginInput): Promise<PublicUser> => {
      setError(null);
      const response = await erpApiClient.login(input);
      setCurrentUser(response.user);
      await refreshState();
      return response.user;
    },
    [refreshState]
  );

  const logout = useCallback(async (): Promise<void> => {
    await erpApiClient.logout();
    setCurrentUser(null);
    setUsers([]);
    setPosCart([]);
    setPosCustomerNote('');
    setLastCompletedSale(null);
    setError(null);
    setSuccessMessage(null);
  }, []);

  const loadUsers = useCallback(async (): Promise<PublicUser[]> => {
    const res = await erpApiClient.fetchUsers();
    setUsers(res.users);
    return res.users;
  }, []);

  const createUser = useCallback(
    async (input: CreateUserInput): Promise<PublicUser> => {
      setError(null);
      const res = await erpApiClient.createUser(input);
      setUsers(res.users);
      setSuccessMessage(
        `Authorized user "${res.user.username}" created (${res.user.role}).`
      );
      return res.user;
    },
    []
  );

  const updateUserStatus = useCallback(
    async (userId: string, isActive: boolean): Promise<PublicUser> => {
      setError(null);
      const res = await erpApiClient.updateUserStatus(userId, isActive);
      setUsers(res.users);
      setSuccessMessage(
        `User "${res.user.username}" ${isActive ? 'activated' : 'deactivated'}.`
      );
      return res.user;
    },
    []
  );

  const deleteUser = useCallback(async (userId: string): Promise<void> => {
    setError(null);
    const res = await erpApiClient.deleteUser(userId);
    setUsers(res.users);
    setSuccessMessage('Authorized user account removed.');
  }, []);

  const clearError = useCallback(() => setError(null), []);
  const clearSuccessMessage = useCallback(() => setSuccessMessage(null), []);
  const clearLastCompletedSale = useCallback(
    () => setLastCompletedSale(null),
    []
  );

  const createMaterial = useCallback(
    async (input: CreateMaterialInput): Promise<Material> => {
      setError(null);
      const response = await erpApiClient.createMaterial(input);
      setState((prev) => ({
        ...prev,
        materials: response.materials,
        summary: response.summary,
      }));
      setSelectedStockInMaterialId((prev) => prev || response.material.id);
      setSuccessMessage(t.catalog.materialCreatedSuccess);
      return response.material;
    },
    [t.catalog.materialCreatedSuccess]
  );

  const updateMaterial = useCallback(
    async (
      materialId: string,
      input: UpdateMaterialInput
    ): Promise<Material> => {
      setError(null);
      const response = await erpApiClient.updateMaterial(materialId, input);
      setState((prev) => ({
        ...prev,
        materials: response.materials,
        summary: response.summary,
      }));
      setSuccessMessage(t.catalog.materialUpdatedSuccess);
      return response.material;
    },
    [t.catalog.materialUpdatedSuccess]
  );

  const deleteMaterialAction = useCallback(
    async (materialId: string): Promise<void> => {
      setError(null);
      const target = state.materials.find((m) => m.id === materialId);
      const response = await erpApiClient.deleteMaterial(materialId);
      setState((prev) => ({
        ...prev,
        materials: response.materials,
        summary: response.summary,
      }));
      setPosCart((prev) =>
        prev.filter((item) => item.materialId !== materialId)
      );
      setSuccessMessage(
        target
          ? `Material "${target.name}" permanently deleted.`
          : 'Material permanently deleted.'
      );
    },
    [state.materials]
  );

  const setMaterialArchived = useCallback(
    async (materialId: string, isArchived: boolean): Promise<Material> => {
      setError(null);
      const response = await erpApiClient.setMaterialArchived(
        materialId,
        isArchived
      );
      setState((prev) => ({
        ...prev,
        materials: response.materials,
        summary: response.summary,
      }));
      if (isArchived) {
        setPosCart((prev) =>
          prev.filter((item) => item.materialId !== materialId)
        );
      }
      setSuccessMessage(
        isArchived
          ? `Material "${response.material.name}" archived. Historical records remain intact.`
          : `Material "${response.material.name}" restored to active catalog.`
      );
      return response.material;
    },
    []
  );

  const createCategoryAction = useCallback(
    async (input: CreateCategoryInput): Promise<CategoryItem> => {
      setError(null);
      const response = await erpApiClient.createCategory(input);
      setState((prev) => ({
        ...prev,
        categories: response.categories,
      }));
      setSuccessMessage(`Category "${response.category?.name}" added.`);
      return response.category!;
    },
    []
  );

  const deleteCategoryAction = useCallback(
    async (categoryId: string): Promise<void> => {
      setError(null);
      const response = await erpApiClient.deleteCategory(categoryId);
      setState((prev) => ({
        ...prev,
        categories: response.categories,
      }));
      setSuccessMessage(`Unused category "${categoryId}" deleted.`);
    },
    []
  );

  const hasTransactionsForMaterial = useCallback(
    (materialId: string): boolean => {
      return materialHasTransactions(state, materialId);
    },
    [state]
  );

  const addToPosCart = useCallback(
    (materialId: string) => {
      const material = state.materials.find((m) => m.id === materialId);
      if (!material || material.isArchived || material.currentStock <= 0)
        return;

      setPosCart((prev) => {
        const existingIndex = prev.findIndex(
          (item) => item.materialId === materialId
        );
        if (existingIndex >= 0) {
          const updated = [...prev];
          const currentQty = Number(updated[existingIndex].quantityInput) || 0;
          const nextQty = round2(currentQty + 1);
          updated[existingIndex] = {
            ...updated[existingIndex],
            quantityInput: String(nextQty),
          };
          return updated;
        }
        return [
          ...prev,
          {
            materialId: material.id,
            quantityInput: '1',
            unitPriceInput: String(material.defaultSellingPrice),
          },
        ];
      });
    },
    [state.materials]
  );

  const updatePosCartQuantity = useCallback(
    (materialId: string, quantityInput: string) => {
      setPosCart((prev) =>
        prev.map((item) =>
          item.materialId === materialId ? { ...item, quantityInput } : item
        )
      );
    },
    []
  );

  const updatePosCartUnitPrice = useCallback(
    (materialId: string, unitPriceInput: string) => {
      setPosCart((prev) =>
        prev.map((item) =>
          item.materialId === materialId ? { ...item, unitPriceInput } : item
        )
      );
    },
    []
  );

  const removeFromPosCart = useCallback((materialId: string) => {
    setPosCart((prev) => prev.filter((item) => item.materialId !== materialId));
  }, []);

  const clearPosCart = useCallback(() => {
    setPosCart([]);
    setPosCustomerNote('');
  }, []);

  const submitPosSale = useCallback(async (): Promise<SaleTransaction> => {
    setError(null);
    const payload: CreateSaleInput = {
      customerNote: posCustomerNote.trim(),
      items: posCart.map((line) => ({
        materialId: line.materialId,
        quantity: Number(line.quantityInput),
        unitSellingPrice: Number(line.unitPriceInput),
      })),
    };

    try {
      const response = await erpApiClient.createSale(payload);
      setState((prev) => ({
        ...prev,
        materials: response.materials,
        sales: [response.sale, ...prev.sales],
        summary: response.summary,
      }));
      setPosCart([]);
      setPosCustomerNote('');
      setLastCompletedSale(response.sale);
      setSuccessMessage(t.pos.saleCompletedSuccess);
      return response.sale;
    } catch (err) {
      handlePossibleAuthExpiry(err);
      const domainErr =
        err instanceof AppDomainError
          ? err
          : new AppDomainError(
              'INTERNAL_ERROR',
              err instanceof Error ? err.message : 'Failed to complete sale.'
            );
      setError(domainErr);
      throw domainErr;
    }
  }, [
    posCart,
    posCustomerNote,
    t.pos.saleCompletedSuccess,
    handlePossibleAuthExpiry,
  ]);

  const reverseSale = useCallback(
    async (saleId: string, reason: string): Promise<SaleTransaction> => {
      setError(null);
      try {
        const response = await erpApiClient.reverseSale(saleId, reason);
        setState((prev) => ({
          ...prev,
          materials: response.materials,
          sales: response.sales,
          summary: response.summary,
        }));
        if (lastCompletedSale?.id === saleId) {
          setLastCompletedSale(response.sale);
        }
        setSuccessMessage(
          `Sale ${saleId} reversed and ground stock quantities restored.`
        );
        return response.sale;
      } catch (err) {
        handlePossibleAuthExpiry(err);
        const domainErr =
          err instanceof AppDomainError
            ? err
            : new AppDomainError(
                'INTERNAL_ERROR',
                err instanceof Error ? err.message : 'Failed to reverse sale.'
              );
        setError(domainErr);
        throw domainErr;
      }
    },
    [lastCompletedSale?.id, handlePossibleAuthExpiry]
  );

  const openStockInForMaterial = useCallback((materialId: string) => {
    setSelectedStockInMaterialId(materialId);
    setActiveTab('stock-in');
  }, []);

  const submitStockIn = useCallback(
    async (input: CreateStockInInput): Promise<StockInRecord> => {
      setError(null);
      try {
        const response = await erpApiClient.createStockIn(input);
        setState((prev) => ({
          ...prev,
          materials: response.materials,
          stockIns: [response.stockIn, ...prev.stockIns],
          summary: response.summary,
        }));
        setSuccessMessage(t.stockIn.stockInSuccess);
        return response.stockIn;
      } catch (err) {
        handlePossibleAuthExpiry(err);
        const domainErr =
          err instanceof AppDomainError
            ? err
            : new AppDomainError(
                'INTERNAL_ERROR',
                err instanceof Error
                  ? err.message
                  : 'Failed to record stock-in delivery.'
              );
        setError(domainErr);
        throw domainErr;
      }
    },
    [t.stockIn.stockInSuccess, handlePossibleAuthExpiry]
  );

  const reverseStockIn = useCallback(
    async (stockInId: string, reason: string): Promise<StockInRecord> => {
      setError(null);
      try {
        const response = await erpApiClient.reverseStockIn(stockInId, reason);
        setState((prev) => ({
          ...prev,
          materials: response.materials,
          stockIns: response.stockIns,
          summary: response.summary,
        }));
        setSuccessMessage(
          `Stock-In ${stockInId} reversed and ground stock updated.`
        );
        return response.stockIn;
      } catch (err) {
        handlePossibleAuthExpiry(err);
        const domainErr =
          err instanceof AppDomainError
            ? err
            : new AppDomainError(
                'INTERNAL_ERROR',
                err instanceof Error
                  ? err.message
                  : 'Failed to reverse stock-in.'
              );
        setError(domainErr);
        throw domainErr;
      }
    },
    [handlePossibleAuthExpiry]
  );

  const submitStockAudit = useCallback(
    async (input: CreateAuditInput): Promise<StockAuditRecord> => {
      setError(null);
      try {
        const response = await erpApiClient.createAudit(input);
        setState((prev) => ({
          ...prev,
          materials: response.materials,
          audits: [response.audit, ...prev.audits],
          summary: response.summary,
        }));
        setSuccessMessage(t.auditLog.auditCommittedSuccess);
        return response.audit;
      } catch (err) {
        handlePossibleAuthExpiry(err);
        const domainErr =
          err instanceof AppDomainError
            ? err
            : new AppDomainError(
                'INTERNAL_ERROR',
                err instanceof Error
                  ? err.message
                  : 'Failed to commit ground-stock audit.'
              );
        setError(domainErr);
        throw domainErr;
      }
    },
    [t.auditLog.auditCommittedSuccess, handlePossibleAuthExpiry]
  );

  const reverseAudit = useCallback(
    async (auditId: string, reason: string): Promise<StockAuditRecord> => {
      setError(null);
      try {
        const response = await erpApiClient.reverseAudit(auditId, reason);
        setState((prev) => ({
          ...prev,
          materials: response.materials,
          audits: response.audits,
          summary: response.summary,
        }));
        setSuccessMessage(
          `Ground-stock audit ${auditId} reversed and stock levels restored.`
        );
        return response.audit;
      } catch (err) {
        handlePossibleAuthExpiry(err);
        const domainErr =
          err instanceof AppDomainError
            ? err
            : new AppDomainError(
                'INTERNAL_ERROR',
                err instanceof Error ? err.message : 'Failed to reverse audit.'
              );
        setError(domainErr);
        throw domainErr;
      }
    },
    [handlePossibleAuthExpiry]
  );

  const value = useMemo<ErpContextValue>(
    () => ({
      currentUser,
      isAuthChecking,
      login,
      logout,
      users,
      loadUsers,
      createUser,
      updateUserStatus,
      deleteUser,
      state,
      activeTab,
      setActiveTab,
      language,
      setLanguage,
      t,
      isLoading,
      error,
      clearError,
      successMessage,
      clearSuccessMessage,
      refreshState,
      createMaterial,
      updateMaterial,
      deleteMaterial: deleteMaterialAction,
      setMaterialArchived,
      hasTransactionsForMaterial,
      createCategory: createCategoryAction,
      deleteCategory: deleteCategoryAction,
      posCart,
      posCustomerNote,
      setPosCustomerNote,
      addToPosCart,
      updatePosCartQuantity,
      updatePosCartUnitPrice,
      removeFromPosCart,
      clearPosCart,
      submitPosSale,
      reverseSale,
      lastCompletedSale,
      clearLastCompletedSale,
      selectedStockInMaterialId,
      setSelectedStockInMaterialId,
      openStockInForMaterial,
      submitStockIn,
      reverseStockIn,
      submitStockAudit,
      reverseAudit,
    }),
    [
      currentUser,
      isAuthChecking,
      login,
      logout,
      users,
      loadUsers,
      createUser,
      updateUserStatus,
      deleteUser,
      state,
      activeTab,
      language,
      t,
      isLoading,
      error,
      clearError,
      successMessage,
      clearSuccessMessage,
      refreshState,
      createMaterial,
      updateMaterial,
      deleteMaterialAction,
      setMaterialArchived,
      hasTransactionsForMaterial,
      createCategoryAction,
      deleteCategoryAction,
      posCart,
      posCustomerNote,
      addToPosCart,
      updatePosCartQuantity,
      updatePosCartUnitPrice,
      removeFromPosCart,
      clearPosCart,
      submitPosSale,
      reverseSale,
      lastCompletedSale,
      clearLastCompletedSale,
      selectedStockInMaterialId,
      openStockInForMaterial,
      submitStockIn,
      reverseStockIn,
      submitStockAudit,
      reverseAudit,
    ]
  );

  return <ErpContext.Provider value={value}>{children}</ErpContext.Provider>;
};

export function useErpStore(): ErpContextValue {
  const context = useContext(ErpContext);
  if (!context) {
    throw new Error('useErpStore must be used inside an ErpProvider');
  }
  return context;
}
