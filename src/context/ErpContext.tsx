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
import { erpApiClient } from '../services/apiClient';
import {
  AppRouteTab,
  CreateAuditInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateStockInInput,
  DraftPosCartItem,
  ErpState,
  LanguageCode,
  Material,
  SaleTransaction,
  StockAuditRecord,
  StockInRecord,
  UpdateMaterialInput,
} from '../types/erp';
import { AppDomainError } from '../utils/errors';

interface ErpContextValue {
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
  createMaterial: (input: CreateMaterialInput) => Promise<Material>;
  updateMaterial: (id: string, input: UpdateMaterialInput) => Promise<Material>;
  hasTransactionsForMaterial: (materialId: string) => boolean;
  // POS Cart State & Actions (TASK-002: FR-006..FR-012)
  posCart: DraftPosCartItem[];
  posCustomerNote: string;
  setPosCustomerNote: (note: string) => void;
  addToPosCart: (materialId: string) => void;
  updatePosCartQuantity: (materialId: string, quantityInput: string) => void;
  updatePosCartUnitPrice: (materialId: string, unitPriceInput: string) => void;
  removeFromPosCart: (materialId: string) => void;
  clearPosCart: () => void;
  submitPosSale: () => Promise<SaleTransaction>;
  lastCompletedSale: SaleTransaction | null;
  clearLastCompletedSale: () => void;
  // Stock-In State & Actions (TASK-003: FR-013..FR-015)
  selectedStockInMaterialId: string;
  setSelectedStockInMaterialId: (materialId: string) => void;
  openStockInForMaterial: (materialId: string) => void;
  submitStockIn: (input: CreateStockInInput) => Promise<StockInRecord>;
  // Ground-Stock Audit Action (TASK-004: FR-016..FR-019)
  submitStockAudit: (input: CreateAuditInput) => Promise<StockAuditRecord>;
}

const ErpContext = createContext<ErpContextValue | null>(null);

export const ErpProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [state, setState] = useState<ErpState>(() => createInitialErpState());
  const [activeTab, setActiveTab] = useState<AppRouteTab>('dashboard');
  const [language, setLanguage] = useState<LanguageCode>('en');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<AppDomainError | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Persistent Draft POS Cart State (preserved across tab and language switches)
  const [posCart, setPosCart] = useState<DraftPosCartItem[]>([]);
  const [posCustomerNote, setPosCustomerNote] = useState<string>('');
  const [lastCompletedSale, setLastCompletedSale] =
    useState<SaleTransaction | null>(null);

  // Selected Material for Stock-In Workbench (TASK-003)
  const [selectedStockInMaterialId, setSelectedStockInMaterialId] =
    useState<string>('');

  const t = TRANSLATIONS[language];

  const refreshState = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const remoteState = await erpApiClient.fetchStoreState();
      setState(remoteState);
      if (remoteState.materials.length > 0) {
        setSelectedStockInMaterialId((prev) =>
          prev && remoteState.materials.some((m) => m.id === prev)
            ? prev
            : remoteState.materials[0].id
        );
      }
    } catch (err) {
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
  }, []);

  useEffect(() => {
    void refreshState();
  }, [refreshState]);

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

  const hasTransactionsForMaterial = useCallback(
    (materialId: string): boolean => {
      return materialHasTransactions(state, materialId);
    },
    [state]
  );

  // FR-007 & FR-008: Add material to POS cart or merge/increment quantity if already present
  const addToPosCart = useCallback(
    (materialId: string) => {
      const material = state.materials.find((m) => m.id === materialId);
      if (!material || material.currentStock <= 0) return;

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
  }, [posCart, posCustomerNote, t.pos.saleCompletedSuccess]);

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
    [t.stockIn.stockInSuccess]
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
    [t.auditLog.auditCommittedSuccess]
  );

  const value = useMemo<ErpContextValue>(
    () => ({
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
      hasTransactionsForMaterial,
      posCart,
      posCustomerNote,
      setPosCustomerNote,
      addToPosCart,
      updatePosCartQuantity,
      updatePosCartUnitPrice,
      removeFromPosCart,
      clearPosCart,
      submitPosSale,
      lastCompletedSale,
      clearLastCompletedSale,
      selectedStockInMaterialId,
      setSelectedStockInMaterialId,
      openStockInForMaterial,
      submitStockIn,
      submitStockAudit,
    }),
    [
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
      hasTransactionsForMaterial,
      posCart,
      posCustomerNote,
      addToPosCart,
      updatePosCartQuantity,
      updatePosCartUnitPrice,
      removeFromPosCart,
      clearPosCart,
      submitPosSale,
      lastCompletedSale,
      clearLastCompletedSale,
      selectedStockInMaterialId,
      openStockInForMaterial,
      submitStockIn,
      submitStockAudit,
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
