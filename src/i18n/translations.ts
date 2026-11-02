import {
  AppRouteTab,
  CategoryItem,
  ErrorCode,
  LanguageCode,
  MaterialCategory,
  MaterialUnit,
} from '../types/erp';

export interface TranslationDictionary {
  appTitle: string;
  appSubtitle: string;
  currencyLabel: string;
  languageLabel: string;
  nav: Record<AppRouteTab, string>;
  categories: Record<MaterialCategory | 'all', string>;
  units: Record<MaterialUnit, string>;
  kpis: {
    totalRevenue: string;
    totalProfit: string;
    inventoryCostValue: string;
    inventoryRetailValue: string;
    lowStockAlerts: string;
    completedSales: string;
    registeredMaterials: string;
    groundAudits: string;
  };
  shell: {
    architectureInitialized: string;
    moduleReadyDescription: string;
    syncStatusConnected: string;
    refreshState: string;
    loadingState: string;
    retryAction: string;
    quickActionsTitle: string;
    openMaterials: string;
    openPos: string;
    openStockIn: string;
    openAudit: string;
    stockCol: string;
    costCol: string;
    priceCol: string;
    minStockCol: string;
    lowStockFlag: string;
    inStockFlag: string;
  };
  catalog: {
    title: string;
    subtitle: string;
    searchPlaceholder: string;
    lowStockOnlyToggle: string;
    registerMaterialBtn: string;
    editMaterialBtn: string;
    sellActionBtn: string;
    stockInActionBtn: string;
    showingCount: string;
    emptyCatalogTitle: string;
    emptyCatalogDescription: string;
    noMatchesTitle: string;
    noMatchesDescription: string;
    resetFiltersBtn: string;
    modalCreateTitle: string;
    modalEditTitle: string;
    modalSubtitle: string;
    fieldNameLabel: string;
    fieldNamePlaceholder: string;
    fieldCategoryLabel: string;
    fieldSpecsLabel: string;
    fieldSpecsPlaceholder: string;
    fieldUnitLabel: string;
    fieldInitialStockLabel: string;
    fieldCurrentStockReadOnly: string;
    fieldMinStockLabel: string;
    fieldUnitCostLabel: string;
    fieldUnitCostReadOnly: string;
    fieldSellingPriceLabel: string;
    immutableStockNotice: string;
    lockedUnitNotice: string;
    cancelBtn: string;
    saveNewMaterialBtn: string;
    saveChangesBtn: string;
    savingBtn: string;
    materialCreatedSuccess: string;
    materialUpdatedSuccess: string;
    validationNameRequired: string;
    validationNonNegative: string;
  };
  pos: {
    title: string;
    subtitle: string;
    pickerHeading: string;
    pickerSearchPlaceholder: string;
    addBtn: string;
    inCartBtn: string;
    outOfStockLabel: string;
    availableLabel: string;
    cartHeading: string;
    clearCartBtn: string;
    emptyCartTitle: string;
    emptyCartDescription: string;
    quantitySoldLabel: string;
    unitSellingPriceLabel: string;
    lineSubtotalLabel: string;
    remainingAfterSaleLabel: string;
    removeLineBtn: string;
    customerNoteLabel: string;
    customerNotePlaceholder: string;
    totalItemsLabel: string;
    totalRevenueLabel: string;
    estimatedProfitLabel: string;
    completeSaleBtn: string;
    processingSaleBtn: string;
    saleCompletedSuccess: string;
    stockFloorBlockedMsg: string;
    invalidQuantityMsg: string;
    invalidPriceMsg: string;
    receiptTitle: string;
    receiptSubtitle: string;
    dismissReceiptBtn: string;
  };
  stockIn: {
    title: string;
    subtitle: string;
    formHeading: string;
    selectMaterialLabel: string;
    currentGroundStockLabel: string;
    currentWeightedCostLabel: string;
    quantityAddedLabel: string;
    quantityAddedPlaceholder: string;
    unitPurchaseCostLabel: string;
    unitPurchaseCostPlaceholder: string;
    supplierNoteLabel: string;
    supplierNotePlaceholder: string;
    previewHeading: string;
    previousStockLabel: string;
    newStockBalanceLabel: string;
    totalRestockCostLabel: string;
    updatedWeightedCostLabel: string;
    weightedFormulaNote: string;
    submitStockInBtn: string;
    recordingStockInBtn: string;
    stockInSuccess: string;
    invalidQuantityMsg: string;
    invalidCostMsg: string;
    recentHeading: string;
    recentSubtitle: string;
    emptyHistoryTitle: string;
    emptyHistoryDescription: string;
    qtyAddedCol: string;
    unitCostCol: string;
    totalCostCol: string;
    stockTransitionCol: string;
    supplierNoteFallback: string;
  };
  auditLog: {
    title: string;
    subtitle: string;
    tabGroundAudit: string;
    tabHistoryLedger: string;
    searchPlaceholder: string;
    auditNoteLabel: string;
    auditNotePlaceholder: string;
    countedSummaryLabel: string;
    variancesDetectedLabel: string;
    expectedStockCol: string;
    physicalCountCol: string;
    physicalCountPlaceholder: string;
    matchBtnLabel: string;
    varianceCol: string;
    untouchedLabel: string;
    exactMatchLabel: string;
    surplusLabel: string;
    shortageLabel: string;
    clearCountsBtn: string;
    commitAuditBtn: string;
    committingAuditBtn: string;
    auditCommittedSuccess: string;
    invalidPhysicalCountMsg: string;
    filterAll: string;
    filterSales: string;
    filterStockIn: string;
    filterAudits: string;
    emptyLedgerTitle: string;
    emptyLedgerDescription: string;
    saleBadgeLabel: string;
    stockInBadgeLabel: string;
    auditBadgeLabel: string;
    auditNoteFallback: string;
    saleNoteFallback: string;
  };
  dashboard: {
    lowStockHeading: string;
    lowStockSubtitle: string;
    allStockHealthyTitle: string;
    allStockHealthyDescription: string;
    restockNowBtn: string;
    sellQuickBtn: string;
    categoryBreakdownHeading: string;
    categoryBreakdownSubtitle: string;
    itemsCountLabel: string;
    recentActivityHeading: string;
    recentActivitySubtitle: string;
    viewFullLedgerBtn: string;
    noActivityYetTitle: string;
    noActivityYetDescription: string;
    activeDirectoryHeading: string;
    activeDirectorySubtitle: string;
  };
  errors: Record<ErrorCode, string>;
}

export const TRANSLATIONS: Record<LanguageCode, TranslationDictionary> = {
  en: {
    appTitle: 'EFA',
    appSubtitle: 'SKU-Free Store Inventory, Multi-Item POS & Ground Audit',
    currencyLabel: 'ETB',
    languageLabel: 'Language',
    nav: {
      dashboard: 'Dashboard',
      materials: 'Materials',
      pos: 'POS Sale',
      'stock-in': 'Stock-In',
      'audit-log': 'Audit & Log',
    },
    categories: {
      all: 'All Materials',
      rebar: 'Rebar',
      cement: 'Cement',
      tiles: 'Tiles',
      paint: 'Paint',
      hardware: 'Hardware',
      other: 'Other',
    },
    units: {
      pcs: 'pcs',
      bars: 'bars',
      bags: 'bags',
      boxes: 'boxes',
      buckets: 'buckets',
      kg: 'kg',
      m: 'm',
      liters: 'liters',
    },
    kpis: {
      totalRevenue: 'Total Sales Revenue',
      totalProfit: 'Gross Profit',
      inventoryCostValue: 'Inventory Cost Value',
      inventoryRetailValue: 'Retail Stock Value',
      lowStockAlerts: 'Low-Stock Items',
      completedSales: 'Completed Sales',
      registeredMaterials: 'Registered Materials',
      groundAudits: 'Ground Audits',
    },
    shell: {
      architectureInitialized: 'Store Overview & Active Catalog',
      moduleReadyDescription:
        'SKU-free material tracking with single units, ETB pricing, and 100% ground-stock synchronization.',
      syncStatusConnected: '100% Ground-Stock Sync Ready',
      refreshState: 'Sync Store',
      loadingState: 'Loading store inventory state...',
      retryAction: 'Retry Connection',
      quickActionsTitle: 'Store Operations',
      openMaterials: 'View Material Catalog',
      openPos: 'Open Multi-Item POS',
      openStockIn: 'Record Stock-In',
      openAudit: 'Ground-Stock Audit',
      stockCol: 'Remaining Stock',
      costCol: 'Supplier Cost',
      priceCol: 'Selling Price',
      minStockCol: 'Min Alert',
      lowStockFlag: 'Low Stock',
      inStockFlag: 'Available',
    },
    catalog: {
      title: 'Material Catalog & Stock Directory',
      subtitle:
        'Register and manage construction and finishing materials using a single tracking unit—no SKU codes or warehouse bin locations required.',
      searchPlaceholder: 'Search by material name, diameter, grade, or size...',
      lowStockOnlyToggle: 'Low Stock Only',
      registerMaterialBtn: 'Register Material',
      editMaterialBtn: 'Edit',
      sellActionBtn: 'Sell',
      stockInActionBtn: 'Stock-In',
      showingCount: 'Showing materials',
      emptyCatalogTitle: 'No materials registered yet',
      emptyCatalogDescription:
        'Register your first construction or finishing material to start tracking stock and sales.',
      noMatchesTitle: 'No materials match your filter',
      noMatchesDescription:
        'Try clearing your search text or switching the material category filter.',
      resetFiltersBtn: 'Reset Filters',
      modalCreateTitle: 'Register New Material',
      modalEditTitle: 'Edit Material Details',
      modalSubtitle:
        'Single tracking unit per item. No SKU or bin location needed.',
      fieldNameLabel: 'Material Name',
      fieldNamePlaceholder: 'e.g., Deformed Rebar 12mm or Dangote Cement 50kg',
      fieldCategoryLabel: 'Category',
      fieldSpecsLabel: 'Specifications (Optional)',
      fieldSpecsPlaceholder: 'e.g., Ø12mm · Grade 60 · 12m length',
      fieldUnitLabel: 'Single Tracking Unit',
      fieldInitialStockLabel: 'Initial Ground Stock',
      fieldCurrentStockReadOnly: 'Current Ground Stock (Read-Only)',
      fieldMinStockLabel: 'Low-Stock Alert Threshold',
      fieldUnitCostLabel: 'Supplier Unit Purchase Cost (ETB)',
      fieldUnitCostReadOnly: 'Current Supplier Unit Cost (ETB)',
      fieldSellingPriceLabel: 'Default Unit Selling Price (ETB)',
      immutableStockNotice:
        'To maintain 100% ledger accuracy, stock and supplier cost after registration are updated strictly through POS Sales, Stock-In, or Ground-Stock Audit.',
      lockedUnitNotice:
        'Tracking unit is locked because transactions already exist for this material.',
      cancelBtn: 'Cancel',
      saveNewMaterialBtn: 'Register Material',
      saveChangesBtn: 'Save Changes',
      savingBtn: 'Saving...',
      materialCreatedSuccess: 'Material registered in catalog.',
      materialUpdatedSuccess: 'Material details updated.',
      validationNameRequired: 'Please enter a material name (1–120 characters).',
      validationNonNegative: 'Values must be valid numbers greater than or equal to 0.',
    },
    pos: {
      title: 'Multi-Item Point-of-Sale (POS)',
      subtitle:
        'Select materials, confirm unit selling prices in ETB, and deduct sold quantities automatically. Sales exceeding available stock are strictly blocked.',
      pickerHeading: '1. Select Materials from Ground Stock',
      pickerSearchPlaceholder: 'Filter materials to add to sale...',
      addBtn: 'Add to Sale',
      inCartBtn: '+1 in Cart',
      outOfStockLabel: 'Out of Stock',
      availableLabel: 'Available',
      cartHeading: '2. Customer Sale Receipt Cart',
      clearCartBtn: 'Clear Cart',
      emptyCartTitle: 'Sale cart is empty',
      emptyCartDescription:
        'Select one or more construction materials from the list to build a multi-item customer sale receipt.',
      quantitySoldLabel: 'Quantity Sold',
      unitSellingPriceLabel: 'Unit Selling Price (ETB)',
      lineSubtotalLabel: 'Line Subtotal',
      remainingAfterSaleLabel: 'Remaining Stock After Sale',
      removeLineBtn: 'Remove item',
      customerNoteLabel: 'Customer / Site Note (Optional)',
      customerNotePlaceholder: 'e.g., Buyer name, project site, or plate number',
      totalItemsLabel: 'Line Items',
      totalRevenueLabel: 'Total Sale Revenue',
      estimatedProfitLabel: 'Gross Profit',
      completeSaleBtn: 'Complete Sale & Deduct Stock',
      processingSaleBtn: 'Recording Sale...',
      saleCompletedSuccess: 'Sale recorded and inventory stock deducted.',
      stockFloorBlockedMsg:
        'Exceeds available ground stock — sale blocked until quantity is reduced or stock is added.',
      invalidQuantityMsg: 'Enter a valid quantity greater than 0.',
      invalidPriceMsg: 'Enter a valid unit selling price (0 or higher).',
      receiptTitle: 'Last Completed Sale Receipt',
      receiptSubtitle: 'Stock balances have been automatically deducted.',
      dismissReceiptBtn: 'Dismiss Receipt',
    },
    stockIn: {
      title: 'Stock-In (Supplier Restocking & Costing)',
      subtitle:
        'Record incoming supplier deliveries, enter the supplier unit purchase cost in ETB, and automatically update ground stock and weighted-average unit cost.',
      formHeading: '1. Record Incoming Supplier Delivery',
      selectMaterialLabel: 'Select Material to Restock',
      currentGroundStockLabel: 'Current Ground Stock',
      currentWeightedCostLabel: 'Current Unit Cost',
      quantityAddedLabel: 'Incoming Quantity Added',
      quantityAddedPlaceholder: 'e.g., 100',
      unitPurchaseCostLabel: 'Supplier Unit Purchase Cost (ETB)',
      unitPurchaseCostPlaceholder: 'e.g., 1380',
      supplierNoteLabel: 'Supplier / Delivery Note (Optional)',
      supplierNotePlaceholder: 'e.g., Factory delivery, invoice #104, truck plate',
      previewHeading: 'Live Stock & Weighted-Average Cost Preview',
      previousStockLabel: 'Previous Ground Stock',
      newStockBalanceLabel: 'New Ground Stock Balance',
      totalRestockCostLabel: 'Total Restock Purchase Cost',
      updatedWeightedCostLabel: 'Updated Weighted-Average Unit Cost',
      weightedFormulaNote:
        'Weighted-average cost blends existing ground stock valuation with the new supplier delivery cost.',
      submitStockInBtn: 'Record Stock-In & Update Inventory',
      recordingStockInBtn: 'Recording Delivery...',
      stockInSuccess:
        'Stock-In recorded. Ground stock and weighted-average unit cost updated.',
      invalidQuantityMsg: 'Incoming quantity added must be greater than 0.',
      invalidCostMsg: 'Supplier unit purchase cost must be 0 or higher.',
      recentHeading: '2. Recent Stock-In Deliveries',
      recentSubtitle: 'Chronological ledger of supplier deliveries and cost updates.',
      emptyHistoryTitle: 'No supplier deliveries recorded yet',
      emptyHistoryDescription:
        'Use the Stock-In form to record incoming rebar, cement, tiles, paint, or hardware deliveries.',
      qtyAddedCol: 'Quantity Added',
      unitCostCol: 'Purchase Cost',
      totalCostCol: 'Total Cost',
      stockTransitionCol: 'Stock Balance',
      supplierNoteFallback: 'Standard supplier delivery',
    },
    auditLog: {
      title: 'Physical Ground-Stock Audit & Transaction Ledger',
      subtitle:
        'Compare expected app stock against physical counts on the ground, inspect exact variances, and maintain 100% synchronization with a permanent audit trail.',
      tabGroundAudit: 'Ground-Stock Audit',
      tabHistoryLedger: 'Transaction & Audit Ledger',
      searchPlaceholder: 'Filter materials or ledger notes...',
      auditNoteLabel: 'Audit Reason / Yard Note (Optional)',
      auditNotePlaceholder:
        'e.g., Saturday yard count — 2 paint buckets damaged in storage',
      countedSummaryLabel: 'Items Counted',
      variancesDetectedLabel: 'Variances Detected',
      expectedStockCol: 'Expected App Stock',
      physicalCountCol: 'Physical Ground Count',
      physicalCountPlaceholder: 'Enter ground count',
      matchBtnLabel: 'Match (=)',
      varianceCol: 'Live Variance',
      untouchedLabel: 'Not counted in this batch',
      exactMatchLabel: 'Exact Match',
      surplusLabel: 'Surplus',
      shortageLabel: 'Shortage',
      clearCountsBtn: 'Clear Entered Counts',
      commitAuditBtn: 'Commit Ground Audit & Sync Stock',
      committingAuditBtn: 'Synchronizing Ground Stock...',
      auditCommittedSuccess:
        'Ground-stock audit committed. App stock is now 100% synchronized with physical counts.',
      invalidPhysicalCountMsg: 'Physical count must be 0 or higher.',
      filterAll: 'All Records',
      filterSales: 'POS Sales',
      filterStockIn: 'Stock-In Deliveries',
      filterAudits: 'Ground Audits',
      emptyLedgerTitle: 'No ledger entries match your filter',
      emptyLedgerDescription:
        'Completed POS sales, supplier Stock-In deliveries, and physical ground-stock audits appear here in chronological order.',
      saleBadgeLabel: 'POS Sale',
      stockInBadgeLabel: 'Stock-In',
      auditBadgeLabel: 'Ground Audit',
      auditNoteFallback: 'Physical ground-stock reconciliation',
      saleNoteFallback: 'Walk-in counter sale',
    },
    dashboard: {
      lowStockHeading: 'Low-Stock & Restock Attention',
      lowStockSubtitle:
        'Materials at or below their minimum stock threshold. Click Restock to log a supplier delivery.',
      allStockHealthyTitle: 'All registered materials are above minimum stock levels',
      allStockHealthyDescription:
        'No urgent restocking required. Ground stock levels are above configured alert thresholds.',
      restockNowBtn: 'Restock Now',
      sellQuickBtn: 'Sell',
      categoryBreakdownHeading: 'Inventory Valuation by Category',
      categoryBreakdownSubtitle:
        'Current ground stock cost and retail value grouped by material category.',
      itemsCountLabel: 'materials',
      recentActivityHeading: 'Recent Store Activity',
      recentActivitySubtitle:
        'Latest 5 POS sales, Stock-In deliveries, and ground-stock audits.',
      viewFullLedgerBtn: 'View Full Ledger',
      noActivityYetTitle: 'No transactions recorded in this session yet',
      noActivityYetDescription:
        'Completed POS sales, supplier Stock-In deliveries, and ground audits appear here automatically.',
      activeDirectoryHeading: 'Active Ground-Stock Directory',
      activeDirectorySubtitle:
        'Quick overview of all registered construction and finishing materials.',
    },
    errors: {
      VALIDATION_ERROR: 'Please check the highlighted input fields and try again.',
      INSUFFICIENT_STOCK: 'Requested sale quantity exceeds available stock on the ground.',
      IMMUTABLE_FIELD_VIOLATION: 'Stock balance and locked units can only be modified through transactions.',
      MATERIAL_NOT_FOUND: 'The requested material was not found in the store catalog.',
      RECORD_NOT_FOUND: 'The requested record was not found.',
      UNAUTHORIZED: 'Your session is missing or expired. Please log in with your pre-registered credentials.',
      INVALID_CREDENTIALS: 'Incorrect username or password. Please verify your pre-registered credentials.',
      ACCOUNT_DEACTIVATED: 'This user account has been deactivated by an administrator.',
      FORBIDDEN: 'Administrator privileges are required for this action.',
      MATERIAL_HAS_HISTORY: 'Cannot permanently delete a material that has transaction history. Archive it instead.',
      MATERIAL_ARCHIVED: 'This material is archived and cannot be used in new transactions until restored.',
      CATEGORY_IN_USE: 'Cannot delete a category that is currently used by existing materials.',
      ALREADY_REVERSED: 'This transaction has already been reversed.',
      INSUFFICIENT_STOCK_FOR_REVERSAL: 'Cannot reverse this record because current ground stock is lower than the quantity to deduct.',
      LAST_ADMIN_PROTECTION: 'Cannot delete or deactivate the last active administrator account.',
      DELETION_PROHIBITED: 'Completed ledger transactions cannot be permanently deleted. Use the reversal workflow instead.',
      DUPLICATE_RECORD: 'A record with this identifier already exists.',
      INTERNAL_ERROR: 'Unable to communicate with the store server. Please retry.',
    },
  },
  am: {
    appTitle: 'EFA',
    appSubtitle: 'ያለ SKU የንብረት ቁጥጥር፣ የሽያጭ እና የመሬት ላይ ቆጠራ ሲስተም',
    currencyLabel: 'ብር (ETB)',
    languageLabel: 'ቋንቋ',
    nav: {
      dashboard: 'ዳሽቦርድ',
      materials: 'ዕቃዎች',
      pos: 'ሽያጭ (POS)',
      'stock-in': 'ገቢ ዕቃ',
      'audit-log': 'ቆጠራ እና ታሪክ',
    },
    categories: {
      all: 'ሁሉም ዕቃዎች',
      rebar: 'ብረት (Rebar)',
      cement: 'ሲሚንቶ',
      tiles: 'ሴራሚክ / ታይልስ',
      paint: 'ቀለም',
      hardware: 'ሃርድዌር',
      other: 'ሌሎች',
    },
    units: {
      pcs: 'ፍሬ',
      bars: 'ዘንግ',
      bags: 'ከረጢት',
      boxes: 'ካርቶን',
      buckets: 'ባልዲ',
      kg: 'ኪ.ግ',
      m: 'ሜትር',
      liters: 'ሊትር',
    },
    kpis: {
      totalRevenue: 'ጠቅላላ የሽያጭ ገቢ',
      totalProfit: 'ጠቅላላ ትርፍ',
      inventoryCostValue: 'የክምችት ግዢ ዋጋ',
      inventoryRetailValue: 'የክምችት መሸጫ ዋጋ',
      lowStockAlerts: 'ያነሱ ዕቃዎች',
      completedSales: 'የተፈጸሙ ሽያጮች',
      registeredMaterials: 'የተመዘገቡ ዕቃዎች',
      groundAudits: 'የመሬት ላይ ቆጠራዎች',
    },
    shell: {
      architectureInitialized: 'የመደብር አጠቃላይ እይታ እና የዕቃዎች ዝርዝር',
      moduleReadyDescription:
        'ያለ SKU በነጠላ መለኪያ የሚሰራ የንብረት ቁጥጥር፣ የETB ዋጋ እና 100% የመሬት ላይ ቆጠራ።',
      syncStatusConnected: 'ከመሬት ላይ ክምችት ጋር የተናበበ',
      refreshState: 'አድስ',
      loadingState: 'የመደብሩን መረጃ በመጫን ላይ...',
      retryAction: 'እንደገና ሞክር',
      quickActionsTitle: 'ፈጣን ተግባራት',
      openMaterials: 'የዕቃዎች ዝርዝር ክፈት',
      openPos: 'ሽያጭ መዝግብ (POS)',
      openStockIn: 'ገቢ ዕቃ መዝግብ',
      openAudit: 'የመሬት ላይ ቆጠራ',
      stockCol: 'ቀሪ ክምችት',
      costCol: 'የግዢ ዋጋ',
      priceCol: 'መሸጫ ዋጋ',
      minStockCol: 'ዝቅተኛ መጠን',
      lowStockFlag: 'ክምችት አንሷል',
      inStockFlag: 'በክምችት አለ',
    },
    catalog: {
      title: 'የዕቃዎች ዝርዝር እና የክምችት መዝገብ',
      subtitle:
        'የኮንስትራክሽን እና ፊኒሺንግ ዕቃዎችን ያለ SKU ወይም የመጋዘን ኮድ በነጠላ መለኪያ ይመዝግቡ እና ያስተዳድሩ።',
      searchPlaceholder: 'በዕቃ ስም፣ ውፍረት (mm)፣ ደረጃ ወይም መጠን ይፈልጉ...',
      lowStockOnlyToggle: 'ያነሱ ዕቃዎች ብቻ',
      registerMaterialBtn: 'አዲስ ዕቃ መዝግብ',
      editMaterialBtn: 'አስተካክል',
      sellActionBtn: 'ሽያጭ',
      stockInActionBtn: 'ገቢ',
      showingCount: 'ዕቃዎች በመታየት ላይ',
      emptyCatalogTitle: 'ምንም የተመዘገበ ዕቃ የለም',
      emptyCatalogDescription: 'የመጀመሪያውን የኮንስትራክሽን ዕቃ በመመዝገብ ስራ ይጀምሩ።',
      noMatchesTitle: 'ከፍለጋው ጋር የሚዛመድ ዕቃ አልተገኘም',
      noMatchesDescription: 'የፍለጋ ቃሉን ያጽዱ ወይም የምድብ ማጣሪያውን ይቀይሩ።',
      resetFiltersBtn: 'ማጣሪያዎችን አጽዳ',
      modalCreateTitle: 'አዲስ ዕቃ መመዝገቢያ',
      modalEditTitle: 'የዕቃ መረጃ ማስተካከያ',
      modalSubtitle: 'ለእያንዳንዱ ዕቃ አንድ መለኪያ ብቻ፤ የSKU ኮድ አያስፈልግም።',
      fieldNameLabel: 'የዕቃው ስም',
      fieldNamePlaceholder: 'ምሳሌ፦ ባለ 12mm ብረት ወይም ዳንጎቴ ሲሚንቶ 50kg',
      fieldCategoryLabel: 'ምድብ (Category)',
      fieldSpecsLabel: 'ዝርዝር መግለጫ (አማራጭ)',
      fieldSpecsPlaceholder: 'ምሳሌ፦ Ø12mm · Grade 60 · 12m',
      fieldUnitLabel: 'መለኪያ (Unit)',
      fieldInitialStockLabel: 'የመጀመሪያ ቀሪ ክምችት',
      fieldCurrentStockReadOnly: 'አሁን ያለ ቀሪ ክምችት (የማይቀየር)',
      fieldMinStockLabel: 'የዝቅተኛ ክምችት ማስጠንቀቂያ መጠን',
      fieldUnitCostLabel: 'የአንዱ የግዢ ዋጋ (ETB)',
      fieldUnitCostReadOnly: 'አሁን ያለ የግዢ ዋጋ (ETB)',
      fieldSellingPriceLabel: 'መደበኛ የአንዱ መሸጫ ዋጋ (ETB)',
      immutableStockNotice:
        'ትክክለኛ የሂሳብ እና የክምችት ቁጥጥር እንዲኖር፣ ቀሪ ክምችት የሚቀየረው በሽያጭ (POS)፣ በገቢ ዕቃ ወይም በመሬት ላይ ቆጠራ ብቻ ነው።',
      lockedUnitNotice: 'ለዚህ ዕቃ እንቅስቃሴ ስለተመዘገበ መለኪያውን መቀየር አይቻልም።',
      cancelBtn: 'ሰርዝ',
      saveNewMaterialBtn: 'ዕቃውን መዝግብ',
      saveChangesBtn: 'ለውጦችን አስቀምጥ',
      savingBtn: 'በማስቀመጥ ላይ...',
      materialCreatedSuccess: 'አዲሱ ዕቃ በትክክል ተመዝግቧል።',
      materialUpdatedSuccess: 'የዕቃው መረጃ ተስተካክሏል።',
      validationNameRequired: 'እባክዎ የዕቃውን ስም ያስገቡ (1–120 ፊደላት)።',
      validationNonNegative: 'ቁጥሮቹ ከ 0 ወይም ከዚያ በላይ መሆን አለባቸው።',
    },
    pos: {
      title: 'የብዙ ዕቃዎች ሽያጭ መመዝገቢያ (POS)',
      subtitle:
        'የተሸጡ ዕቃዎችን ይምረጡ፣ የአንዱን መሸጫ ዋጋ (ETB) ያስገቡ፤ ሲስተሙ ጠቅላላ ገቢውን አስልቶ ከቀሪ ክምችት ላይ ይቀንሳል። ከክምችት በላይ መሸጥ በጥብቅ የተከለከለ ነው።',
      pickerHeading: '1. ከመሬት ላይ ክምችት ዕቃ ይምረጡ',
      pickerSearchPlaceholder: 'ለሽያጭ የሚሆን ዕቃ ይፈልጉ...',
      addBtn: 'ወደ ሽያጭ ጨምር',
      inCartBtn: '+1 ጨምር',
      outOfStockLabel: 'ክምችት አልቋል',
      availableLabel: 'አለ',
      cartHeading: '2. የደንበኛ የሽያጭ ቅርጫት',
      clearCartBtn: 'ቅርጫት አጽዳ',
      emptyCartTitle: 'የሽያጭ ቅርጫቱ ባዶ ነው',
      emptyCartDescription:
        'ሽያጭ ለመመዝገብ ከዝርዝሩ ውስጥ አንድ ወይም ከዚያ በላይ የኮንስትራክሽን ዕቃዎችን ይምረጡ።',
      quantitySoldLabel: 'የተሸጠ ብዛት',
      unitSellingPriceLabel: 'የአንዱ መሸጫ ዋጋ (ETB)',
      lineSubtotalLabel: 'ንዑስ ድምር',
      remainingAfterSaleLabel: 'ከሽያጭ በኋላ ቀሪ ክምችት',
      removeLineBtn: 'ዕቃውን አስወግድ',
      customerNoteLabel: 'የደንበኛ ስም / ማስታወሻ (አማራጭ)',
      customerNotePlaceholder: 'ምሳሌ፦ የገዢ ስም፣ የሳይት ቦታ ወይም የመኪና ታርጋ',
      totalItemsLabel: 'የዕቃ ዓይነቶች',
      totalRevenueLabel: 'ጠቅላላ የሽያጭ ገቢ',
      estimatedProfitLabel: 'ትርፍ',
      completeSaleBtn: 'ሽያጩን አጠናቅቅ እና ከክምችት ቀንስ',
      processingSaleBtn: 'በመመዝገብ ላይ...',
      saleCompletedSuccess: 'ሽያጩ ተመዝግቦ ከቀሪ ክምችት ላይ ተቀንሷል።',
      stockFloorBlockedMsg:
        'በመሬት ላይ ካለው ቀሪ ክምችት ይበልጣል — መጠኑ እስኪቀንስ ድረስ ሽያጩ ታግዷል።',
      invalidQuantityMsg: 'ከ 0 በላይ የሆነ ትክክለኛ ብዛት ያስገቡ።',
      invalidPriceMsg: 'ትክክለኛ የመሸጫ ዋጋ ያስገቡ (0 ወይም ከዚያ በላይ)።',
      receiptTitle: 'የተጠናቀቀ የሽያጭ ደረሰኝ ማጠቃለያ',
      receiptSubtitle: 'የተሸጡት መጠኖች ከቀሪ ክምችት ላይ ተቀንሰዋል።',
      dismissReceiptBtn: 'ዝጋ',
    },
    stockIn: {
      title: 'ገቢ ዕቃ መመዝገቢያ (Stock-In)',
      subtitle:
        'ከአቅራቢ የገቡ ዕቃዎችን ብዛት እና የአንዱን የግዢ ዋጋ (ETB) ይመዝግቡ፤ ቀሪ ክምችት እና አማካይ የግዢ ዋጋ ወዲያውኑ ይስተካከላል።',
      formHeading: '1. አዲስ ገቢ ዕቃ መዝግብ',
      selectMaterialLabel: 'ገቢ የሚደረገውን ዕቃ ይምረጡ',
      currentGroundStockLabel: 'አሁን ያለ ቀሪ ክምችት',
      currentWeightedCostLabel: 'አሁን ያለ የግዢ ዋጋ',
      quantityAddedLabel: 'የገባው ዕቃ ብዛት',
      quantityAddedPlaceholder: 'ምሳሌ፦ 100',
      unitPurchaseCostLabel: 'የአንዱ የግዢ ዋጋ (ETB)',
      unitPurchaseCostPlaceholder: 'ምሳሌ፦ 1380',
      supplierNoteLabel: 'የአቅራቢ ስም / ማስታወሻ (አማራጭ)',
      supplierNotePlaceholder: 'ምሳሌ፦ ከፋብሪካ የገባ፣ ደረሰኝ ቁጥር 104',
      previewHeading: 'የአዲሱ ክምችት እና አማካይ የግዢ ዋጋ ቅድመ-እይታ',
      previousStockLabel: 'የነበረ ቀሪ ክምችት',
      newStockBalanceLabel: 'አዲስ ጠቅላላ ቀሪ ክምችት',
      totalRestockCostLabel: 'ጠቅላላ የገቢ ዕቃ ግዢ ዋጋ',
      updatedWeightedCostLabel: 'አዲስ አማካይ የአንዱ ግዢ ዋጋ',
      weightedFormulaNote:
        'አማካይ የግዢ ዋጋ (Weighted-Average) የነበረውን ክምችት ከአዲሱ ገቢ ዋጋ ጋር በማመጣጠን ይሰላል።',
      submitStockInBtn: 'ገቢ ዕቃውን መዝግብ እና ክምችት ጨምር',
      recordingStockInBtn: 'በመመዝገብ ላይ...',
      stockInSuccess: 'ገቢ ዕቃው ተመዝግቦ ቀሪ ክምችት እና አማካይ የግዢ ዋጋ ተስተካክሏል።',
      invalidQuantityMsg: 'የገባው ብዛት ከ 0 በላይ መሆን አለበት።',
      invalidCostMsg: 'የአንዱ የግዢ ዋጋ 0 ወይም ከዚያ በላይ መሆን አለበት።',
      recentHeading: '2. የቅርብ ጊዜ ገቢ ዕቃዎች ታሪክ',
      recentSubtitle: 'የተመዘገቡ የአቅራቢ ገቢ ዕቃዎች እና የዋጋ ዝርዝር።',
      emptyHistoryTitle: 'እስካሁን የተመዘገበ ገቢ ዕቃ የለም',
      emptyHistoryDescription:
        'አዲስ የገቡ የኮንስትራክሽን ዕቃዎችን ለመመዝገብ የገቢ ዕቃ ቅጹን ይጠቀሙ።',
      qtyAddedCol: 'የገባ ብዛት',
      unitCostCol: 'የአንዱ ዋጋ',
      totalCostCol: 'ጠቅላላ ወጪ',
      stockTransitionCol: 'የክምችት ለውጥ',
      supplierNoteFallback: 'መደበኛ የአቅራቢ ገቢ',
    },
    auditLog: {
      title: 'የመሬት ላይ ቆጠራ እና የእንቅስቃሴ ታሪክ',
      subtitle:
        'በሲስተሙ ላይ የሚታየውን ቀሪ ክምችት በመሬት ላይ ካለው ትክክለኛ ብዛት ጋር ያመሳክሩ፣ ልዩነቱን ይመልከቱ እና 100% እንዲናበብ ያድርጉ።',
      tabGroundAudit: 'የመሬት ላይ ቆጠራ',
      tabHistoryLedger: 'የእንቅስቃሴ ታሪክ መዝገብ',
      searchPlaceholder: 'ዕቃዎችን ወይም ማስታወሻዎችን ይፈልጉ...',
      auditNoteLabel: 'የቆጠራ ምክንያት / ማስታወሻ (አማራጭ)',
      auditNotePlaceholder:
        'ምሳሌ፦ የቅዳሜ የመጋዘን ቆጠራ — 2 ባልዲ ቀለም ተጎድቷል',
      countedSummaryLabel: 'የተቆጠሩ ዕቃዎች',
      variancesDetectedLabel: 'ልዩነት የታየባቸው',
      expectedStockCol: 'በሲስተም ያለ ክምችት',
      physicalCountCol: 'በመሬት ላይ የተቆጠረ',
      physicalCountPlaceholder: 'የተቆጠረ ብዛት',
      matchBtnLabel: 'እኩል (=)',
      varianceCol: 'ልዩነት (Variance)',
      untouchedLabel: 'በዚህ ቆጠራ አልተካተተም',
      exactMatchLabel: 'ልዩነት የለም',
      surplusLabel: 'ጭማሪ (Surplus)',
      shortageLabel: 'ጉድለት (Shortage)',
      clearCountsBtn: 'የተሞሉትን አጽዳ',
      commitAuditBtn: 'ቆጠራውን አጽድቅ እና ክምችት አስተካክል',
      committingAuditBtn: 'በማስተካከል ላይ...',
      auditCommittedSuccess:
        'የመሬት ላይ ቆጠራው ተመዝግቧል። የሲስተሙ ክምችት ከመሬት ላይ ቆጠራ ጋር 100% ተናብቧል።',
      invalidPhysicalCountMsg: 'የተቆጠረው ብዛት 0 ወይም ከዚያ በላይ መሆን አለበት።',
      filterAll: 'ሁሉም ታሪክ',
      filterSales: 'ሽያጮች (POS)',
      filterStockIn: 'ገቢ ዕቃዎች',
      filterAudits: 'የመሬት ላይ ቆጠራዎች',
      emptyLedgerTitle: 'ምንም የተመዘገበ የእንቅስቃሴ ታሪክ የለም',
      emptyLedgerDescription:
        'የተፈጸሙ ሽያጮች፣ ገቢ ዕቃዎች እና የመሬት ላይ ቆጠራዎች በቅደም ተከተል እዚህ ይታያሉ።',
      saleBadgeLabel: 'ሽያጭ (POS)',
      stockInBadgeLabel: 'ገቢ ዕቃ',
      auditBadgeLabel: 'የመሬት ላይ ቆጠራ',
      auditNoteFallback: 'መደበኛ የመሬት ላይ ቆጠራ ማስተካከያ',
      saleNoteFallback: 'የመደብር ላይ ሽያጭ',
    },
    dashboard: {
      lowStockHeading: 'ያነሱ ዕቃዎች እና የገቢ ማስጠንቀቂያ',
      lowStockSubtitle:
        'ከዝቅተኛው የማስጠንቀቂያ መጠን በታች የሆኑ ዕቃዎች። አዲስ ገቢ ለመመዝገብ ገቢ አድርግ የሚለውን ይጫኑ።',
      allStockHealthyTitle: 'ሁሉም የተመዘገቡ ዕቃዎች በቂ ቀሪ ክምችት አላቸው',
      allStockHealthyDescription:
        'በአሁኑ ሰዓት አስቸኳይ ገቢ የሚፈልግ ዕቃ የለም።',
      restockNowBtn: 'ገቢ አድርግ',
      sellQuickBtn: 'ሽያጭ',
      categoryBreakdownHeading: 'የክምችት ዋጋ በምድብ (Category)',
      categoryBreakdownSubtitle:
        'በመሬት ላይ ያለው ክምችት የግዢ እና የመሸጫ ዋጋ በየምድቡ።',
      itemsCountLabel: 'ዕቃዎች',
      recentActivityHeading: 'የቅርብ ጊዜ የመደብር እንቅስቃሴዎች',
      recentActivitySubtitle:
        'የመጨረሻዎቹ 5 ሽያጮች፣ ገቢ ዕቃዎች እና የመሬት ላይ ቆጠራዎች።',
      viewFullLedgerBtn: 'ሙሉ ታሪክ እይ',
      noActivityYetTitle: 'እስካሁን የተመዘገበ እንቅስቃሴ የለም',
      noActivityYetDescription:
        'ሽያጮች፣ ገቢ ዕቃዎች እና የመሬት ላይ ቆጠራዎች ሲመዘገቡ እዚህ ይታያሉ።',
      activeDirectoryHeading: 'የመሬት ላይ ክምችት ዝርዝር',
      activeDirectorySubtitle:
        'የሁሉም የተመዘገቡ የኮንስትራክሽን እና ፊኒሺንግ ዕቃዎች ፈጣን እይታ።',
    },
    errors: {
      VALIDATION_ERROR: 'እባክዎ የተሞሉትን መረጃዎች ትክክለኛነት ያረጋግጡ።',
      INSUFFICIENT_STOCK: 'የተጠየቀው መጠን በመጋዘን ካለው ቀሪ ክምችት ይበልጣል፤ ሽያጩ ታግዷል።',
      IMMUTABLE_FIELD_VIOLATION: 'ቀሪ ክምችት የሚቀየረው በሽያጭ፣ በገቢ ወይም በቆጠራ ብቻ ነው።',
      MATERIAL_NOT_FOUND: 'የተጠየቀው ዕቃ በዝርዝሩ ውስጥ አልተገኘም።',
      RECORD_NOT_FOUND: 'የተጠየቀው መዝገብ አልተገኘም።',
      UNAUTHORIZED: 'እባክዎ በቅድሚያ በተመዘገበ መለያዎ ይግቡ።',
      INVALID_CREDENTIALS: 'የተሳሳተ የተጠቃሚ ስም ወይም የይለፍ ቃል።',
      ACCOUNT_DEACTIVATED: 'ይህ የተጠቃሚ መለያ ታግዷል።',
      FORBIDDEN: 'ይህን ተግባር ለማከናወን የአስተዳዳሪ (Admin) ፈቃድ ያስፈልጋል።',
      MATERIAL_HAS_HISTORY: 'የእንቅስቃሴ ታሪክ ያለውን ዕቃ እስከመጨረሻው መሰረዝ አይቻልም፤ በምትኩ በማህደር (Archive) ያስቀምጡት።',
      MATERIAL_ARCHIVED: 'ይህ ዕቃ በማህደር ውስጥ ስለሆነ ለአዲስ እንቅስቃሴ መዋል አይችልም።',
      CATEGORY_IN_USE: 'በዕቃዎች ጥቅም ላይ የዋለ ምድብን መሰረዝ አይቻልም።',
      ALREADY_REVERSED: 'ይህ እንቅስቃሴ ከዚህ ቀደም ተቀልብሷል (Reversed)።',
      INSUFFICIENT_STOCK_FOR_REVERSAL: 'አሁን ያለው ቀሪ ክምችት ስለማይበቃ ይህን እንቅስቃሴ መቀልበስ አይቻልም።',
      LAST_ADMIN_PROTECTION: 'የመጨረሻውን ንቁ የአስተዳዳሪ መለያ መሰረዝ ወይም ማገድ አይቻልም።',
      DELETION_PROHIBITED: 'የተጠናቀቁ የሂሳብ መዝገቦችን መሰረዝ ክልክል ነው፤ የመቀልበሻ (Reversal) ስርዓቱን ይጠቀሙ።',
      DUPLICATE_RECORD: 'በዚህ ስም የተመዘገበ መረጃ ቀድሞውኑ አለ።',
      INTERNAL_ERROR: 'ከሰርቨሩ ጋር መገናኘት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
    },
  },
  om: {
    appTitle: 'EFA',
    appSubtitle: 'To’annoo Kuusaa SKU-Maleessa, Gurgurtaa POS fi Lakkoofsa Lafaa',
    currencyLabel: 'ETB',
    languageLabel: 'Afaan',
    nav: {
      dashboard: 'Daashboordii',
      materials: 'Meeshaalee',
      pos: 'Gurgurtaa POS',
      'stock-in': 'Galii Kuusaa',
      'audit-log': 'Lakkoofsa & Seenaa',
    },
    categories: {
      all: 'Meeshaalee Hunda',
      rebar: 'Sibiila (Rebar)',
      cement: 'Simintoo',
      tiles: 'Seeramikii / Taayilsii',
      paint: 'Halluu (Paint)',
      hardware: 'Haardweerii',
      other: 'Kan Biroo',
    },
    units: {
      pcs: 'tokko',
      bars: 'ulee',
      bags: 'kiisii',
      boxes: 'kaartoonii',
      buckets: 'baaldii',
      kg: 'kg',
      m: 'm',
      liters: 'liitira',
    },
    kpis: {
      totalRevenue: 'Galii Gurgurtaa Waliigalaa',
      totalProfit: 'Bu’aa Waliigalaa',
      inventoryCostValue: 'Gatii Bittaa Kuusaa',
      inventoryRetailValue: 'Gatii Gurgurtaa Kuusaa',
      lowStockAlerts: 'Meeshaalee Xiqqaatan',
      completedSales: 'Gurgurtaa Xumurame',
      registeredMaterials: 'Meeshaalee Galmaa’an',
      groundAudits: 'Lakkoofsa Lafaa',
    },
    shell: {
      architectureInitialized: 'Ilaalcha Waliigalaa fi Tarree Meeshaalee',
      moduleReadyDescription:
        'To’annoo meeshaalee safartuu tokkoon, gatii ETB fi wal-simannaa kuusaa lafaa 100%.',
      syncStatusConnected: 'Kuusaa Lafaa Waliin 100% Wal-Simata',
      refreshState: 'Haaromsuu',
      loadingState: 'Odeeffannoo kuusaa fe’aa jira...',
      retryAction: 'Irra Deebi’ii Yaali',
      quickActionsTitle: 'Hojiiwwan Ariifachiisoo',
      openMaterials: 'Tarree Meeshaalee Ilaali',
      openPos: 'Gurgurtaa POS Bani',
      openStockIn: 'Galii Kuusaa Galmeessi',
      openAudit: 'Lakkoofsa Lafaa Gaggeessi',
      stockCol: 'Kuusaa Hafe',
      costCol: 'Gatii Bittaa',
      priceCol: 'Gatii Gurgurtaa',
      minStockCol: 'Daangaa Xiqqaa',
      lowStockFlag: 'Kuusaan Xiqqaateera',
      inStockFlag: 'Ni Argama',
    },
    catalog: {
      title: 'Galmee Meeshaalee fi Kuusaa',
      subtitle:
        'Meeshaalee ijaarsaa fi xumuraa safartuu tokkoon galmeessaa—koodii SKU ykn bakka kuusaa hin barbaachisu.',
      searchPlaceholder: 'Maqaa meeshaa, furdina (mm), sadarkaa ykn hammaan barbaadi...',
      lowStockOnlyToggle: 'Kan Xiqqaatan Qofa',
      registerMaterialBtn: 'Meeshaa Haaraa Galmeessi',
      editMaterialBtn: 'Sirreessi',
      sellActionBtn: 'Gurguri',
      stockInActionBtn: 'Galii',
      showingCount: 'Meeshaalee mul’atan',
      emptyCatalogTitle: 'Meeshaan galmaa’e hin jiru',
      emptyCatalogDescription:
        'Meeshaa ijaarsaa jalqabaa galmeessuun to’annoo kuusaa fi gurgurtaa eegalaa.',
      noMatchesTitle: 'Meeshaan barbaacha keessan wal-simatu hin argamne',
      noMatchesDescription: 'Barreeffama barbaachaa haqi ykn ramaddii jijjiiri.',
      resetFiltersBtn: 'Calaltuu Haqi',
      modalCreateTitle: 'Meeshaa Haaraa Galmeessi',
      modalEditTitle: 'Odeeffannoo Meeshaa Sirreessi',
      modalSubtitle: 'Safartuu tokko qofa; koodiin SKU hin barbaachisu.',
      fieldNameLabel: 'Maqaa Meeshaa',
      fieldNamePlaceholder: 'Fkn: Sibiila Rebar 12mm ykn Simintoo Dangote 50kg',
      fieldCategoryLabel: 'Ramaddii (Category)',
      fieldSpecsLabel: 'Ibsa Dabalataa (Dirqama Miti)',
      fieldSpecsPlaceholder: 'Fkn: Ø12mm · Grade 60 · 12m',
      fieldUnitLabel: 'Safartuu Tokko (Unit)',
      fieldInitialStockLabel: 'Kuusaa Lafaa Jalqabaa',
      fieldCurrentStockReadOnly: 'Kuusaa Amma Jiru (Hin Jijjiiramu)',
      fieldMinStockLabel: 'Daangaa Akeekkachiisa Kuusaa Xiqqaa',
      fieldUnitCostLabel: 'Gatii Bittaa Tokkoo (ETB)',
      fieldUnitCostReadOnly: 'Gatii Bittaa Ammaa (ETB)',
      fieldSellingPriceLabel: 'Gatii Gurgurtaa Idilee Tokkoo (ETB)',
      immutableStockNotice:
        'Sirrummaa herregaa eeguuf, kuusaan hafe gurgurtaa POS, galii kuusaa ykn lakkoofsa lafaatiin qofa jijjiirama.',
      lockedUnitNotice:
        'Meeshaa kanaaf galmeen waan jiruuf safartuun isaa hin jijjiiramu.',
      cancelBtn: 'Dhiisi',
      saveNewMaterialBtn: 'Meeshaa Galmeessi',
      saveChangesBtn: 'Jijjiirama Olkaa’i',
      savingBtn: 'Olkaa’aa jira...',
      materialCreatedSuccess: 'Meeshaan haaraan galmaa’eera.',
      materialUpdatedSuccess: 'Odeeffannoon meeshaa haaromfameera.',
      validationNameRequired: 'Maaloo maqaa meeshaa galchaa (qubee 1–120).',
      validationNonNegative: 'Lakkoofsi 0 ykn isaa ol ta’uu qaba.',
    },
    pos: {
      title: 'Gurgurtaa Meeshaalee Hedduu (POS)',
      subtitle:
        'Meeshaalee filadhaa, gatii gurgurtaa tokkoo (ETB) mirkaneessaa; siistamni galii waliigalaa herreeguun kuusaa irraa hir’isa. Kuusaa jiru ol gurguruun dhorkaadha.',
      pickerHeading: '1. Kuusaa Lafaa Keessaa Meeshaa Filadhu',
      pickerSearchPlaceholder: 'Meeshaa gurguramu barbaadi...',
      addBtn: 'Gurgurtaatti Dabali',
      inCartBtn: '+1 Dabali',
      outOfStockLabel: 'Kuusaan Dhumeera',
      availableLabel: 'Ni Jiru',
      cartHeading: '2. Guuboo Nagahee Gurgurtaa Maamilaa',
      clearCartBtn: 'Guuboo Qulqulleessi',
      emptyCartTitle: 'Guuboon gurgurtaa duwwaadha',
      emptyCartDescription:
        'Gurgurtaa galmeessuuf tarree meeshaalee keessaa tokko ykn isaa ol filadhaa.',
      quantitySoldLabel: 'Baay’ina Gurgurame',
      unitSellingPriceLabel: 'Gatii Gurgurtaa Tokkoo (ETB)',
      lineSubtotalLabel: 'Ida’ama Tarree',
      remainingAfterSaleLabel: 'Gurgurtaa Booda Kuusaa Hafe',
      removeLineBtn: 'Meeshaa haqi',
      customerNoteLabel: 'Maqaa Maamilaa / Yaadachiisa (Dirqama Miti)',
      customerNotePlaceholder: 'Fkn: Maqaa bitataa, bakka ijaarsaa ykn gabatee konkolaataa',
      totalItemsLabel: 'Gosa Meeshaalee',
      totalRevenueLabel: 'Galii Gurgurtaa Waliigalaa',
      estimatedProfitLabel: 'Bu’aa',
      completeSaleBtn: 'Gurgurtaa Xumuri & Kuusaa Hir’isi',
      processingSaleBtn: 'Galmeessaa jira...',
      saleCompletedSuccess: 'Gurgurtaan galmaa’ee kuusaan hir’ifameera.',
      stockFloorBlockedMsg:
        'Kuusaa lafa jiru caala — hanga baay’inni hir’ifamutti gurgurtaan dhorkameera.',
      invalidQuantityMsg: 'Baay’ina sirrii 0 ol ta’e galchi.',
      invalidPriceMsg: 'Gatii gurgurtaa sirrii galchi (0 ykn isaa ol).',
      receiptTitle: 'Nagahee Gurgurtaa Xumurame',
      receiptSubtitle: 'Baay’inni gurgurame kuusaa irraa hir’ifameera.',
      dismissReceiptBtn: 'Cufi',
    },
    stockIn: {
      title: 'Galii Kuusaa (Dhiyeessituu & Gatii Bittaa)',
      subtitle:
        'Meeshaalee dhiyeessituu irraa galan, baay’inaa fi gatii bittaa tokkoo (ETB) galmeessaa; kuusaan lafaa fi gatiin bittaa giddu-galeessaa battalumatti haaromfama.',
      formHeading: '1. Galii Meeshaa Haaraa Galmeessi',
      selectMaterialLabel: 'Meeshaa Galii Ta’u Filadhu',
      currentGroundStockLabel: 'Kuusaa Lafaa Ammaa',
      currentWeightedCostLabel: 'Gatii Bittaa Ammaa',
      quantityAddedLabel: 'Baay’ina Dabalame',
      quantityAddedPlaceholder: 'Fkn: 100',
      unitPurchaseCostLabel: 'Gatii Bittaa Tokkoo (ETB)',
      unitPurchaseCostPlaceholder: 'Fkn: 1380',
      supplierNoteLabel: 'Maqaa Dhiyeessituu / Yaadachiisa (Dirqama Miti)',
      supplierNotePlaceholder: 'Fkn: Warshaa irraa kan gale, nagahee #104',
      previewHeading: 'Durargii Kuusaa Haaraa fi Gatii Bittaa Giddu-Galeessaa',
      previousStockLabel: 'Kuusaa Duraan Jiru',
      newStockBalanceLabel: 'Kuusaa Lafaa Haaraa',
      totalRestockCostLabel: 'Gatii Bittaa Waliigalaa',
      updatedWeightedCostLabel: 'Gatii Bittaa Giddu-Galeessaa Haaraa',
      weightedFormulaNote:
        'Gatiin bittaa giddu-galeessaa kuusaa duraanii fi gatii dhiyeessii haaraa walitti madaaluun herreegama.',
      submitStockInBtn: 'Galii Kuusaa Galmeessi & Dabali',
      recordingStockInBtn: 'Galmeessaa jira...',
      stockInSuccess:
        'Galiin kuusaa galmaa’eera. Kuusaan lafaa fi gatiin bittaa haaromfameera.',
      invalidQuantityMsg: 'Baay’inni dabalame 0 ol ta’uu qaba.',
      invalidCostMsg: 'Gatiin bittaa tokkoo 0 ykn isaa ol ta’uu qaba.',
      recentHeading: '2. Seenaa Galii Kuusaa Dhiyoo',
      recentSubtitle: 'Tarree galii meeshaalee dhiyeessituu fi jijjiirama gatii.',
      emptyHistoryTitle: 'Galiin kuusaa galmaa’e hin jiru',
      emptyHistoryDescription:
        'Meeshaalee ijaarsaa haaraa galan galmeessuuf unka galii kuusaa fayyadamaa.',
      qtyAddedCol: 'Baay’ina Gale',
      unitCostCol: 'Gatii Tokkoo',
      totalCostCol: 'Gatii Waliigalaa',
      stockTransitionCol: 'Jijjiirama Kuusaa',
      supplierNoteFallback: 'Dhiyeessii idilee',
    },
    auditLog: {
      title: 'Lakkoofsa Kuusaa Lafaa fi Galmee Seenaa',
      subtitle:
        'Kuusaa appii keessatti mul’atu lakkoofsa qabatamaa lafa jiru waliin wal-bira qabaa, garaagarummaa ilaalaa, 100% wal-simsiisaa.',
      tabGroundAudit: 'Lakkoofsa Kuusaa Lafaa',
      tabHistoryLedger: 'Galmee Seenaa Daldalaa',
      searchPlaceholder: 'Meeshaalee ykn yaadachiisa barbaadi...',
      auditNoteLabel: 'Sababa Lakkoofsa / Yaadachiisa (Dirqama Miti)',
      auditNotePlaceholder:
        'Fkn: Lakkoofsa Sanbataa — baaldii halluu 2 miidhameera',
      countedSummaryLabel: 'Meeshaalee Lakkaa’aman',
      variancesDetectedLabel: 'Garaagarummaa Mul’ate',
      expectedStockCol: 'Kuusaa Appii Keessaa',
      physicalCountCol: 'Lakkoofsa Lafaa Qabatamaa',
      physicalCountPlaceholder: 'Lakkoofsa lafaa galchi',
      matchBtnLabel: 'Wal-qixa (=)',
      varianceCol: 'Garaagarummaa',
      untouchedLabel: 'Lakkoofsa kana keessatti hin hammatamne',
      exactMatchLabel: 'Wal-qixa (Garaagarummaa Hin Qabu)',
      surplusLabel: 'Dabalata (Surplus)',
      shortageLabel: 'Hir’ina (Shortage)',
      clearCountsBtn: 'Lakkoofsa Haqi',
      commitAuditBtn: 'Lakkoofsa Lafaa Mirkaneessi & Kuusaa Wal-Simsiisi',
      committingAuditBtn: 'Wal-simsiisaa jira...',
      auditCommittedSuccess:
        'Lakkoofsi lafaa mirkanaa’eera. Kuusaan appii amma lakkoofsa lafaa waliin 100% wal-simata.',
      invalidPhysicalCountMsg: 'Lakkoofsi lafaa 0 ykn isaa ol ta’uu qaba.',
      filterAll: 'Galmee Hunda',
      filterSales: 'Gurgurtaa POS',
      filterStockIn: 'Galii Kuusaa',
      filterAudits: 'Lakkoofsa Lafaa',
      emptyLedgerTitle: 'Galmeen seenaa hin argamne',
      emptyLedgerDescription:
        'Gurgurtaan POS, galiin kuusaa fi lakkoofsi lafaa tartiiba yerootiin asitti mul’atu.',
      saleBadgeLabel: 'Gurgurtaa POS',
      stockInBadgeLabel: 'Galii Kuusaa',
      auditBadgeLabel: 'Lakkoofsa Lafaa',
      auditNoteFallback: 'Wal-simsiisa lakkoofsa kuusaa lafaa',
      saleNoteFallback: 'Gurgurtaa idilee',
    },
    dashboard: {
      lowStockHeading: 'Meeshaalee Kuusaan Xiqqaate & Galii Barbaadan',
      lowStockSubtitle:
        'Meeshaalee daangaa xiqqaa gadi ta’an. Dhiyeessii haaraa galmeessuuf Galii Dabali cuqaasaa.',
      allStockHealthyTitle: 'Meeshaaleen galmaa’an hundi kuusaa gahaa qabu',
      allStockHealthyDescription:
        'Yeroo ammaa meeshaan galii ariifachiisaa barbaadu hin jiru.',
      restockNowBtn: 'Galii Dabali',
      sellQuickBtn: 'Gurguri',
      categoryBreakdownHeading: 'Gatii Kuusaa Ramaddiin (Category)',
      categoryBreakdownSubtitle:
        'Gatii bittaa fi gurgurtaa kuusaa lafa jiruu ramaddii meeshaatiin.',
      itemsCountLabel: 'meeshaalee',
      recentActivityHeading: 'Sochii Daldalaa Dhiyoo',
      recentActivitySubtitle:
        'Gurgurtaa POS, galii kuusaa fi lakkoofsa lafaa 5n dhiyoo.',
      viewFullLedgerBtn: 'Galmee Guutuu Ilaali',
      noActivityYetTitle: 'Sochiin galmaa’e hin jiru',
      noActivityYetDescription:
        'Gurgurtaan POS, galiin kuusaa fi lakkoofsi lafaa yeroo raawwataman asitti mul’atu.',
      activeDirectoryHeading: 'Tarree Kuusaa Lafaa',
      activeDirectorySubtitle:
        'Ilaalcha ariifachiisaa meeshaalee ijaarsaa fi xumuraa hunda.',
    },
    errors: {
      VALIDATION_ERROR: 'Maaloo odeeffannoo guutame sirrii ta’uu mirkaneessaa.',
      INSUFFICIENT_STOCK: 'Baay’inni gaafatame kuusaa lafa jiru caala; gurgurtaan dhorkameera.',
      IMMUTABLE_FIELD_VIOLATION: 'Kuusaan hafe gurgurtaa, galii ykn lakkoofsa lafaatiin qofa jijjiirama.',
      MATERIAL_NOT_FOUND: 'Meeshaan gaafatame tarree keessatti hin argamne.',
      RECORD_NOT_FOUND: 'Galmeen gaafatame hin argamne.',
      UNAUTHORIZED: 'Maaloo eenyummeessaa galmaa’een seenaa.',
      INVALID_CREDENTIALS: 'Maqaa fayyadamaa ykn jecha darbii dogoggoraa.',
      ACCOUNT_DEACTIVATED: 'Herregni fayyadamaa kun uggurameera.',
      FORBIDDEN: 'Hojii kanaaf aangoo bulchaa (Admin) barbaachisa.',
      MATERIAL_HAS_HISTORY: 'Meeshaa seenaa daldalaa qabu haquun hin danda’amu; kuusaa seenaa (Archive) keessa kaa’aa.',
      MATERIAL_ARCHIVED: 'Meeshaan kun kuusaa seenaa keessa waan jiruuf daldala haaraaf hin oolu.',
      CATEGORY_IN_USE: 'Ramaddii meeshaaleen itti fayyadamaa jiran haquun hin danda’amu.',
      ALREADY_REVERSED: 'Daldalli kun duraan deebi’eera (Reversed).',
      INSUFFICIENT_STOCK_FOR_REVERSAL: 'Kuusaan amma jiru waan hinuma gahaniif galmee kana deebisuun hin danda’amu.',
      LAST_ADMIN_PROTECTION: 'Bulchaa (Admin) isa dhumaa haquun ykn ugguruun hin danda’amu.',
      DELETION_PROHIBITED: 'Galmee daldalaa xumurame haquun dhorkaadha; sirna deebisuu (Reversal) fayyadamaa.',
      DUPLICATE_RECORD: 'Galmeen maqaa kanaan duraan jira.',
      INTERNAL_ERROR: 'Sarvarii waliin walqunnamuun hin danda’amne. Irra deebi’ii yaali.',
    },
  },
};

export function getCategoryLabel(
  t: TranslationDictionary,
  categoryId: string,
  customCategories?: CategoryItem[]
): string {
  const known = (t.categories as Record<string, string | undefined>)[categoryId];
  if (known) return known;
  const custom = customCategories?.find((c) => c.id === categoryId);
  return custom ? custom.name : categoryId;
}

/**
 * Formats monetary values in Ethiopian Birr (ETB) rounded to 2 decimal places
 * per SRS FR-023 and NFR-003.
 */
export function formatETB(amount: number): string {
  const safeAmount = Number.isFinite(amount) ? amount : 0;
  return `ETB ${safeAmount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

/**
 * Formats stock quantities cleanly (integers without trailing .00, decimals up to 2 places).
 */
export function formatQuantity(quantity: number): string {
  if (!Number.isFinite(quantity)) return '0';
  return Number.isInteger(quantity)
    ? quantity.toLocaleString('en-US')
    : quantity.toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
}

