import '../core/constants/erp_constants.dart';

/// Complete Trilingual Localization Dictionary (`en`, `am`, `om`)
/// for the EFA Construction & Finishing Material Store Mobile ERP.
class ErpLocalizations {
  final AppLanguage language;

  const ErpLocalizations(this.language);

  String t(String key) {
    final map = _strings[language] ?? _strings[AppLanguage.en]!;
    return map[key] ?? _strings[AppLanguage.en]![key] ?? key;
  }

  String categoryLabel(String code, {String? customName}) {
    final clean = code.trim().toLowerCase();
    final key = 'cat_$clean';
    final map = _strings[language] ?? _strings[AppLanguage.en]!;
    if (map.containsKey(key)) {
      return map[key]!;
    }
    if (customName != null && customName.trim().isNotEmpty) {
      return customName.trim();
    }
    return code;
  }

  String unitLabel(String code) {
    final clean = MaterialUnit.fromCode(code).code;
    final key = 'unit_$clean';
    final map = _strings[language] ?? _strings[AppLanguage.en]!;
    return map[key] ?? clean;
  }

  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.en: {
      'appTitle': 'EFA',
      'appSubtitle': 'SKU-Free Inventory, Multi-Item POS & Ground Audit',

      // 5 Bottom Navigation Tabs & Sub-Tabs
      'navDashboard': 'Dashboard',
      'navMaterials': 'Materials',
      'navSales': 'Sales',
      'navInventory': 'Inventory',
      'navMore': 'More',
      'navStockIn': 'Stock-In',
      'navAudit': 'Audit',
      'navHistory': 'History',
      'navReports': 'Reports',
      'navSettings': 'Settings',
      'navUsers': 'Users & Categories',

      // Categories
      'filterAllCategories': 'All',
      'cat_rebar': 'Rebar',
      'cat_cement': 'Cement',
      'cat_tiles': 'Tiles',
      'cat_paint': 'Paint',
      'cat_hardware': 'Hardware',
      'cat_other': 'Other',

      // Units
      'unit_pcs': 'pcs',
      'unit_bars': 'bars',
      'unit_bags': 'bags',
      'unit_boxes': 'boxes',
      'unit_buckets': 'buckets',
      'unit_kg': 'kg',
      'unit_m': 'm',
      'unit_liters': 'liters',

      // Dashboard & Reports KPIs
      'kpiTodaySales': 'Today Sales',
      'kpiTransactionsCount': 'receipts',
      'kpiTodayRevenue': 'Today Revenue',
      'kpiTodayProfit': 'Today Profit',
      'kpiTotalRevenue': 'Total Revenue',
      'kpiTotalProfit': 'Gross Profit',
      'kpiMaterialsCount': 'Materials',
      'kpiRestockRequired': 'Low Stock',
      'costValuationLabel': 'Inventory Cost Value',
      'retailValuationLabel': 'Retail Stock Value',
      'profitLabel': 'Profit',
      'itemsCount': 'items',
      'viewAll': 'View All',
      'lowStockSection': 'Low-Stock Materials',
      'allStockHealthy': 'All materials are above minimum stock levels.',
      'recentSalesSection': 'Recent Sales Receipts',
      'noRecentSales': 'No sales recorded yet.',
      'reportsSectionTitle': 'Store Valuation & Profit Summary',

      // Status & Badges
      'statusInStock': 'In Stock',
      'statusLowStock': 'Low Stock',
      'statusOutStock': 'Out of Stock',
      'badgeArchived': 'Archived',
      'badgeReversed': 'Reversed',

      // Materials Catalog & Modal
      'searchMaterialsHint': 'Search material name or specification...',
      'lowStockOnlyFilter': 'Low Stock Only',
      'resetFiltersBtn': 'Reset Filters',
      'btnRegisterMaterial': 'Add Material',
      'btnEditMetadata': 'Edit Details',
      'btnSellInPos': 'Sell in POS',
      'btnRestockMaterial': 'Restock (Stock-In)',
      'fieldMaterialName': 'Material Name *',
      'fieldCategory': 'Category',
      'fieldSpecs': 'Specifications (Optional)',
      'fieldUnit': 'Single Tracking Unit',
      'fieldOpeningStock': 'Initial Ground Stock',
      'fieldMinStock': 'Min Stock Alert',
      'fieldUnitCost': 'Supplier Unit Cost (ETB)',
      'fieldSellingPrice': 'Selling Price (ETB)',
      'immutableStockNotice':
          'Ground stock & unit cost are ledger-protected. Use Stock-In, Sales, or Audit to adjust quantities.',
      'lockedUnitNotice':
          'Tracking unit is locked because transactions already exist for this material.',
      'lblStock': 'Stock',
      'lblPrice': 'Price',
      'lblCost': 'Cost',
      'lblMin': 'Min',

      // POS Sales Screen
      'posTitle': 'Customer Sale Receipt Cart',
      'posSelectMaterial': 'Select Material from Ground Stock',
      'posQuantity': 'Quantity Sold',
      'posUnitPrice': 'Unit Selling Price (ETB)',
      'posAvailable': 'Available Stock',
      'posRemainingAfterSale': 'Remaining After Sale',
      'posStockExceededWarning': 'Exceeds available ground stock!',
      'btnAddCartLine': 'Add to Sale Cart',
      'btnClearCart': 'Clear Cart',
      'posCartEmpty': 'Sale cart is empty. Add materials above to build a receipt.',
      'posCustomerNote': 'Customer / Site Note (Optional)',
      'posTotalAmount': 'Total Sale Revenue',
      'posEstimatedProfit': 'Estimated Gross Profit',
      'btnCompleteSale': 'Complete Sale & Deduct Stock',
      'posReceiptBannerTitle': 'Last Completed Sale Receipt',
      'btnDismissReceipt': 'Dismiss',

      // Stock-In Screen
      'stockInTitle': 'Supplier Delivery (Stock-In)',
      'stockInSelectMaterial': 'Select Material Receiving Stock',
      'stockInQuantityAdded': 'Incoming Quantity Added',
      'stockInUnitPurchaseCost': 'Supplier Unit Cost (ETB)',
      'stockInSupplierNote': 'Supplier / Truck / Invoice Note',
      'stockInFormulaPreview': 'Live Stock & Weighted-Average Cost Preview',
      'stockInTotalRestockCost': 'Total Restock Cost',
      'stockInRecentDeliveries': 'Recent Stock-In Deliveries',
      'btnRecordStockIn': 'Record Stock-In & Update Cost',

      // Stock Audit Screen
      'auditTitle': 'Physical Ground-Stock Audit',
      'auditSubtitle':
          'Compare expected app stock with physical counts on the ground and synchronize variances.',
      'auditExpected': 'Expected',
      'auditPhysical': 'Physical Count',
      'auditVariance': 'Variance',
      'auditMatchExpected': 'Match (=)',
      'auditClearCounts': 'Clear Counts',
      'auditCountedItems': 'Counted',
      'auditVariancesDetected': 'Variances',
      'auditUntouched': 'Not counted yet',
      'auditNoteLabel': 'Audit Reason / Yard Note (Optional)',
      'btnSubmitAudit': 'Commit Ground Audit & Sync Stock',

      // History & Ledger Screen
      'tabAll': 'All',
      'tabSales': 'Sales',
      'tabStockIn': 'Stock-In',
      'tabAudits': 'Audits',
      'searchLedgerHint': 'Search by material, note, or transaction ID...',

      // Admin, Settings & About EFA
      'languageSettingTitle': 'Application Language',
      'languageSettingSubtitle':
          'Switch between English, Amharic, and Afaan Oromo without losing active forms.',
      'adminPanelTitle': 'Users & Material Categories',
      'tabUsers': 'Users',
      'tabCategories': 'Categories',
      'companionSyncToggle': 'Companion Server Write-Through Sync',
      'btnSyncServer': 'Sync with Companion Server',
      'btnCreateUser': 'Create Authorized User',
      'fieldUsername': 'Username *',
      'fieldEmail': 'Email *',
      'fieldFullName': 'Full Name *',
      'fieldRole': 'Role',
      'fieldPassword': 'Password *',
      'roleStaff': 'Store Staff',
      'roleAdmin': 'Administrator',
      'btnDeactivate': 'Deactivate',
      'btnActivate': 'Activate',
      'fieldCategoryCode': 'Category Code *',
      'fieldCategoryName': 'Category Name *',
      'btnAddCategory': 'Add Category',

      // About EFA Section
      'aboutEfaTitle': 'About EFA',
      'developerNameLabel': 'Developer',
      'developerPhoneLabel': 'Phone',
      'appVersionLabel': 'Application Version',
      'buildNumberLabel': 'Build Number',
      'appDescriptionLabel': 'Application Description',

      // Login & Auth
      'loginTitle': 'Sign In to EFA',
      'loginSubtitle':
          'Enter your pre-registered store credentials to access inventory, POS sales, and ground audits.',
      'loginUsernameOrEmail': 'Username or Email *',
      'loginPassword': 'Password *',
      'btnSignIn': 'Sign In',
      'btnSignOut': 'Sign Out',

      // Common Actions & Dialogs
      'btnSave': 'Save Changes',
      'btnCancel': 'Cancel',
      'btnDelete': 'Delete',
      'btnArchive': 'Archive',
      'btnRestore': 'Restore',
      'btnReverse': 'Reverse',
      'targetRecordLabel': 'Target Record',
      'confirmDeleteTitle': 'Confirm Permanent Deletion',
      'confirmArchiveTitle': 'Archive Material',
      'confirmReverseTitle': 'Reverse Completed Transaction',
      'reversalReasonLabel': 'Reversal Reason (Required) *',
      'reversalReasonHint': 'e.g., Customer returned items / wrong entry',
      'reversedByLabel': 'Reversed by',
    },
    AppLanguage.am: {
      'appTitle': 'EFA',
      'appSubtitle': 'ያለ SKU የንብረት ቁጥጥር፣ የሽያጭ እና የመሬት ላይ ቆጠራ',

      // 5 Bottom Navigation Tabs & Sub-Tabs
      'navDashboard': 'ዳሽቦርድ',
      'navMaterials': 'ዕቃዎች',
      'navSales': 'ሽያጭ',
      'navInventory': 'ክምችት',
      'navMore': 'ተጨማሪ',
      'navStockIn': 'ገቢ ዕቃ',
      'navAudit': 'ቆጠራ',
      'navHistory': 'ታሪክ',
      'navReports': 'ሪፖርት',
      'navSettings': 'ቅንብሮች',
      'navUsers': 'ተጠቃሚዎች እና ምድቦች',

      // Categories
      'filterAllCategories': 'ሁሉም',
      'cat_rebar': 'ብረት',
      'cat_cement': 'ሲሚንቶ',
      'cat_tiles': 'ሴራሚክ',
      'cat_paint': 'ቀለም',
      'cat_hardware': 'ሃርድዌር',
      'cat_other': 'ሌሎች',

      // Units
      'unit_pcs': 'ፍሬ',
      'unit_bars': 'ዘንግ',
      'unit_bags': 'ከረጢት',
      'unit_boxes': 'ካርቶን',
      'unit_buckets': 'ባልዲ',
      'unit_kg': 'ኪ.ግ',
      'unit_m': 'ሜትር',
      'unit_liters': 'ሊትር',

      // Dashboard & Reports KPIs
      'kpiTodaySales': 'የዛሬ ሽያጮች',
      'kpiTransactionsCount': 'ደረሰኞች',
      'kpiTodayRevenue': 'የዛሬ ገቢ',
      'kpiTodayProfit': 'የዛሬ ትርፍ',
      'kpiTotalRevenue': 'ጠቅላላ ገቢ',
      'kpiTotalProfit': 'ጠቅላላ ትርፍ',
      'kpiMaterialsCount': 'ዕቃዎች',
      'kpiRestockRequired': 'ያነሱ ዕቃዎች',
      'costValuationLabel': 'የክምችት ግዢ ዋጋ',
      'retailValuationLabel': 'የክምችት መሸጫ ዋጋ',
      'profitLabel': 'ትርፍ',
      'itemsCount': 'ዕቃዎች',
      'viewAll': 'ሁሉንም እይ',
      'lowStockSection': 'ያነሱ ዕቃዎች ማስጠንቀቂያ',
      'allStockHealthy': 'ሁሉም የተመዘገቡ ዕቃዎች በቂ ክምችት አላቸው።',
      'recentSalesSection': 'የቅርብ ጊዜ የሽያጭ ደረሰኞች',
      'noRecentSales': 'እስካሁን የተመዘገበ ሽያጭ የለም።',
      'reportsSectionTitle': 'የመደብር ክምችት እና የትርፍ ማጠቃለያ',

      // Status & Badges
      'statusInStock': 'በክምችት አለ',
      'statusLowStock': 'ክምችት አንሷል',
      'statusOutStock': 'ክምችት አልቋል',
      'badgeArchived': 'በማህደር',
      'badgeReversed': 'ተቀልብሷል',

      // Materials Catalog & Modal
      'searchMaterialsHint': 'በዕቃ ስም ወይም መግለጫ ይፈልጉ...',
      'lowStockOnlyFilter': 'ያነሱ ዕቃዎች ብቻ',
      'resetFiltersBtn': 'ማጣሪያ አጽዳ',
      'btnRegisterMaterial': 'አዲስ ዕቃ',
      'btnEditMetadata': 'አስተካክል',
      'btnSellInPos': 'ሽያጭ (POS)',
      'btnRestockMaterial': 'ገቢ አድርግ',
      'fieldMaterialName': 'የዕቃው ስም *',
      'fieldCategory': 'ምድብ',
      'fieldSpecs': 'ዝርዝር መግለጫ (አማራጭ)',
      'fieldUnit': 'ነጠላ መለኪያ (Unit)',
      'fieldOpeningStock': 'የመጀመሪያ ቀሪ ክምችት',
      'fieldMinStock': 'ዝቅተኛ ማስጠንቀቂያ መጠን',
      'fieldUnitCost': 'የአንዱ የግዢ ዋጋ (ETB)',
      'fieldSellingPrice': 'የአንዱ መሸጫ ዋጋ (ETB)',
      'immutableStockNotice':
          'ቀሪ ክምችት እና የግዢ ዋጋ የሚቀየሩት በገቢ ዕቃ፣ በሽያጭ ወይም በቆጠራ ብቻ ነው።',
      'lockedUnitNotice': 'ለዚህ ዕቃ እንቅስቃሴ ስለተመዘገበ መለኪያውን መቀየር አይቻልም።',
      'lblStock': 'ክምችት',
      'lblPrice': 'መሸጫ',
      'lblCost': 'ግዢ',
      'lblMin': 'ዝቅተኛ',

      // POS Sales Screen
      'posTitle': 'የደንበኛ የሽያጭ ቅርጫት',
      'posSelectMaterial': 'ከመሬት ላይ ክምችት ዕቃ ይምረጡ',
      'posQuantity': 'የተሸጠ ብዛት',
      'posUnitPrice': 'የአንዱ መሸጫ ዋጋ (ETB)',
      'posAvailable': 'ያለ ክምችት',
      'posRemainingAfterSale': 'ከሽያጭ በኋላ ቀሪ',
      'posStockExceededWarning': 'በመሬት ላይ ካለው ቀሪ ክምችት ይበልጣል!',
      'btnAddCartLine': 'ወደ ቅርጫት ጨምር',
      'btnClearCart': 'ቅርጫት አጽዳ',
      'posCartEmpty': 'የሽያጭ ቅርጫቱ ባዶ ነው። ከላይ ዕቃ ይምረጡ።',
      'posCustomerNote': 'የደንበኛ / የሳይት ማስታወሻ',
      'posTotalAmount': 'ጠቅላላ የሽያጭ ገቢ',
      'posEstimatedProfit': 'ጠቅላላ ትርፍ',
      'btnCompleteSale': 'ሽያጩን አጠናቅቅ እና ከክምችት ቀንስ',
      'posReceiptBannerTitle': 'የተጠናቀቀ የሽያጭ ደረሰኝ',
      'btnDismissReceipt': 'ዝጋ',

      // Stock-In Screen
      'stockInTitle': 'ከአቅራቢ ገቢ ዕቃ መመዝገቢያ',
      'stockInSelectMaterial': 'ገቢ የሚደረገውን ዕቃ ይምረጡ',
      'stockInQuantityAdded': 'የገባው ዕቃ ብዛት',
      'stockInUnitPurchaseCost': 'የአንዱ የግዢ ዋጋ (ETB)',
      'stockInSupplierNote': 'የአቅራቢ / የመኪና ታርጋ ማስታወሻ',
      'stockInFormulaPreview': 'የአዲሱ ክምችት እና አማካይ የግዢ ዋጋ ቅድመ-እይታ',
      'stockInTotalRestockCost': 'ጠቅላላ የገቢ ወጪ',
      'stockInRecentDeliveries': 'የቅርብ ጊዜ ገቢ ዕቃዎች',
      'btnRecordStockIn': 'ገቢ ዕቃውን መዝግብ እና ክምችት አድስ',

      // Stock Audit Screen
      'auditTitle': 'የመሬት ላይ ክምችት ቆጠራ',
      'auditSubtitle': 'በሲስተሙ ያለውን ክምችት በመሬት ላይ ካለው ትክክለኛ ብዛት ጋር ያመሳክሩ።',
      'auditExpected': 'በሲስተም ያለ',
      'auditPhysical': 'የተቆጠረ ብዛት',
      'auditVariance': 'ልዩነት',
      'auditMatchExpected': 'እኩል (=)',
      'auditClearCounts': 'አጽዳ',
      'auditCountedItems': 'የተቆጠሩ',
      'auditVariancesDetected': 'ልዩነቶች',
      'auditUntouched': 'አልተቆጠረም',
      'auditNoteLabel': 'የቆጠራ ምክንያት / ማስታወሻ',
      'btnSubmitAudit': 'ቆጠራውን አጽድቅ እና ክምችት አስተካክል',

      // History & Ledger Screen
      'tabAll': 'ሁሉም',
      'tabSales': 'ሽያጮች',
      'tabStockIn': 'ገቢ ዕቃዎች',
      'tabAudits': 'ቆጠራዎች',
      'searchLedgerHint': 'በዕቃ ስም፣ ማስታወሻ ወይም መለያ ይፈልጉ...',

      // Admin, Settings & About EFA
      'languageSettingTitle': 'የመተግበሪያ ቋንቋ',
      'languageSettingSubtitle': 'በእንግሊዝኛ፣ አማርኛ እና አፋን ኦሮሞ መካከል ይቀያይሩ።',
      'adminPanelTitle': 'ተጠቃሚዎች እና የዕቃ ምድቦች',
      'tabUsers': 'ተጠቃሚዎች',
      'tabCategories': 'ምድቦች',
      'companionSyncToggle': 'ከሰርቨር ጋር ቀጥታ ማመሳከሪያ (Sync)',
      'btnSyncServer': 'ከሰርቨር ጋር አመሳክር',
      'btnCreateUser': 'አዲስ ተጠቃሚ ፍጠር',
      'fieldUsername': 'የተጠቃሚ ስም *',
      'fieldEmail': 'ኢሜይል *',
      'fieldFullName': 'ሙሉ ስም *',
      'fieldRole': 'ኃላፊነት',
      'fieldPassword': 'የይለፍ ቃል *',
      'roleStaff': 'የመደብር ሰራተኛ',
      'roleAdmin': 'አስተዳዳሪ (Admin)',
      'btnDeactivate': 'አግድ',
      'btnActivate': 'አንቃ',
      'fieldCategoryCode': 'የምድብ ኮድ *',
      'fieldCategoryName': 'የምድብ ስም *',
      'btnAddCategory': 'ምድብ ጨምር',

      // About EFA Section
      'aboutEfaTitle': 'ስለ EFA',
      'developerNameLabel': 'አልሚ (Developer)',
      'developerPhoneLabel': 'ስልክ',
      'appVersionLabel': 'የመተግበሪያ ስሪት (Version)',
      'buildNumberLabel': 'የግንባታ ቁጥር (Build)',
      'appDescriptionLabel': 'የመተግበሪያ መግለጫ',

      // Login & Auth
      'loginTitle': 'ወደ EFA ይግቡ',
      'loginSubtitle': 'የንብረት ቁጥጥር፣ ሽያጭ እና ቆጠራ ለመጠቀም የተመዘገበ መለያዎን ያስገቡ።',
      'loginUsernameOrEmail': 'የተጠቃሚ ስም ወይም ኢሜይል *',
      'loginPassword': 'የይለፍ ቃል *',
      'btnSignIn': 'ግባ',
      'btnSignOut': 'ውጣ',

      // Common Actions & Dialogs
      'btnSave': 'አስቀምጥ',
      'btnCancel': 'ሰርዝ',
      'btnDelete': 'ሰርዝ',
      'btnArchive': 'በማህደር አስቀምጥ',
      'btnRestore': 'መልስ',
      'btnReverse': 'ቀልብስ',
      'targetRecordLabel': 'የተመረጠው መዝገብ',
      'confirmDeleteTitle': 'እስከመጨረሻው መሰረዝን ያረጋግጡ',
      'confirmArchiveTitle': 'ዕቃውን በማህደር አስቀምጥ',
      'confirmReverseTitle': 'እንቅስቃሴውን ቀልብስ (Reverse)',
      'reversalReasonLabel': 'የመቀልበሻ ምክንያት (የግድ) *',
      'reversalReasonHint': 'ምሳሌ፦ ደንበኛው ዕቃውን መልሷል / በስህተት የተመዘገበ',
      'reversedByLabel': 'የተቀለበሰው በ',
    },
    AppLanguage.om: {
      'appTitle': 'EFA',
      'appSubtitle': 'To\'annoo Kuusaa SKU-Malee, POS & Lakkoofsa Lafaa',

      // 5 Bottom Navigation Tabs & Sub-Tabs
      'navDashboard': 'Daashboordii',
      'navMaterials': 'Meeshaalee',
      'navSales': 'Gurgurtaa',
      'navInventory': 'Kuusaa',
      'navMore': 'Dabalata',
      'navStockIn': 'Galii Kuusaa',
      'navAudit': 'Lakkoofsa',
      'navHistory': 'Seenaa',
      'navReports': 'Gabaasa',
      'navSettings': 'Qindaa\'ina',
      'navUsers': 'Fayyadamtoota & Ramaddii',

      // Categories
      'filterAllCategories': 'Hunda',
      'cat_rebar': 'Sibiila',
      'cat_cement': 'Simintoo',
      'cat_tiles': 'Seeraamikii',
      'cat_paint': 'Halluu',
      'cat_hardware': 'Haardweerii',
      'cat_other': 'Biroo',

      // Units
      'unit_pcs': 'pcs',
      'unit_bars': 'ulee',
      'unit_bags': 'kiisii',
      'unit_boxes': 'saanduqa',
      'unit_buckets': 'baaldii',
      'unit_kg': 'kg',
      'unit_m': 'm',
      'unit_liters': 'liitira',

      // Dashboard & Reports KPIs
      'kpiTodaySales': 'Gurgurtaa Har\'aa',
      'kpiTransactionsCount': 'nagahee',
      'kpiTodayRevenue': 'Galii Har\'aa',
      'kpiTodayProfit': 'Bu\'aa Har\'aa',
      'kpiTotalRevenue': 'Galii Waliigalaa',
      'kpiTotalProfit': 'Bu\'aa Waliigalaa',
      'kpiMaterialsCount': 'Meeshaalee',
      'kpiRestockRequired': 'Kuusaa Xiqqaa',
      'costValuationLabel': 'Gatii Bittaa Kuusaa',
      'retailValuationLabel': 'Gatii Gurgurtaa Kuusaa',
      'profitLabel': 'Bu\'aa',
      'itemsCount': 'meeshaalee',
      'viewAll': 'Hunda Ilaali',
      'lowStockSection': 'Meeshaalee Kuusaan Xiqqaate',
      'allStockHealthy': 'Meeshaaleen hundi daangaa xiqqaa ol jiru.',
      'recentSalesSection': 'Nagaheewwan Gurgurtaa Dhihoo',
      'noRecentSales': 'Gurgurtaan galmaa\'e hin jiru.',
      'reportsSectionTitle': 'Gabaasa Gatii Kuusaa fi Bu\'aa',

      // Status & Badges
      'statusInStock': 'Kuusaa Jira',
      'statusLowStock': 'Kuusaa Xiqqaa',
      'statusOutStock': 'Dhumeera',
      'badgeArchived': 'Kuufame',
      'badgeReversed': 'Deebi\'eera',

      // Materials Catalog & Modal
      'searchMaterialsHint': 'Maqaa meeshaa ykn ibsaan barbaadi...',
      'lowStockOnlyFilter': 'Kan Xiqqaatan Qofa',
      'resetFiltersBtn': 'Calaltuu Haqi',
      'btnRegisterMaterial': 'Meeshaa Dabali',
      'btnEditMetadata': 'Sirreessi',
      'btnSellInPos': 'Gurguri (POS)',
      'btnRestockMaterial': 'Galii Kuusaa',
      'fieldMaterialName': 'Maqaa Meeshaa *',
      'fieldCategory': 'Ramaddii',
      'fieldSpecs': 'Ibsa Dabalataa',
      'fieldUnit': 'Safartuu Tokko (Unit)',
      'fieldOpeningStock': 'Kuusaa Lafaa Jalqabaa',
      'fieldMinStock': 'Daangaa Akeekkachiisa Xiqqaa',
      'fieldUnitCost': 'Gatii Bittaa Tokkoo (ETB)',
      'fieldSellingPrice': 'Gatii Gurgurtaa Tokkoo (ETB)',
      'immutableStockNotice':
          'Kuusaan lafaa fi gatiin bittaa Galii Kuusaa, Gurgurtaa ykn Lakkoofsaan qofa jijjiirama.',
      'lockedUnitNotice':
          'Meeshaa kanaaf galmeen waan jiruuf safartuun isaa hin jijjiiramu.',
      'lblStock': 'Kuusaa',
      'lblPrice': 'Gurgurtaa',
      'lblCost': 'Bittaa',
      'lblMin': 'Xiqqaa',

      // POS Sales Screen
      'posTitle': 'Guuboo Nagahee Gurgurtaa',
      'posSelectMaterial': 'Kuusaa Lafaa Keessaa Meeshaa Filadhu',
      'posQuantity': 'Baay\'ina Gurguramu',
      'posUnitPrice': 'Gatii Gurgurtaa Tokkoo (ETB)',
      'posAvailable': 'Kuusaa Jiru',
      'posRemainingAfterSale': 'Gurgurtaa Booda Hafe',
      'posStockExceededWarning': 'Kuusaa lafa jiru caala!',
      'btnAddCartLine': 'Gara Guubootti Dabali',
      'btnClearCart': 'Guuboo Qulqulleessi',
      'posCartEmpty': 'Guuboon gurgurtaa duwwaadha. Meeshaalee olitti filadhu.',
      'posCustomerNote': 'Maqaa Maamilaa / Saayitii',
      'posTotalAmount': 'Galii Gurgurtaa Waliigalaa',
      'posEstimatedProfit': 'Bu\'aa Tilmaamame',
      'btnCompleteSale': 'Gurgurtaa Xumuri & Kuusaa Hir\'isi',
      'posReceiptBannerTitle': 'Nagahee Gurgurtaa Xumurame',
      'btnDismissReceipt': 'Cufi',

      // Stock-In Screen
      'stockInTitle': 'Galii Meeshaalee Dhiyeessituu (Stock-In)',
      'stockInSelectMaterial': 'Meeshaa Galii Argatu Filadhu',
      'stockInQuantityAdded': 'Baay\'ina Haaraa Gale',
      'stockInUnitPurchaseCost': 'Gatii Bittaa Tokkoo (ETB)',
      'stockInSupplierNote': 'Yaadannoo Dhiyeessituu / Konkolaataa',
      'stockInFormulaPreview': 'Tilmaama Kuusaa Haaraa & Gatii Giddu-galeessaa',
      'stockInTotalRestockCost': 'Gatii Bittaa Waliigalaa',
      'stockInRecentDeliveries': 'Galii Kuusaa Dhiyoo',
      'btnRecordStockIn': 'Galii Kuusaa Galmeessi',

      // Stock Audit Screen
      'auditTitle': 'Lakkoofsa Kuusaa Lafaa Dhugaa',
      'auditSubtitle':
          'Kuusaa appii fi meeshaalee lafa jiran lakkaa\'uun 100% wal-simsiisi.',
      'auditExpected': 'Appii Keessa',
      'auditPhysical': 'Lafa Irratti',
      'auditVariance': 'Garaagarummaa',
      'auditMatchExpected': 'Wal-qixa (=)',
      'auditClearCounts': 'Haqi',
      'auditCountedItems': 'Lakkaa\'aman',
      'auditVariancesDetected': 'Garaagarummaa',
      'auditUntouched': 'Hin lakkaa\'amne',
      'auditNoteLabel': 'Sababa Lakkoofsaa / Yaadannoo',
      'btnSubmitAudit': 'Lakkoofsa Mirkaneessi & Kuusaa Sirreessi',

      // History & Ledger Screen
      'tabAll': 'Hunda',
      'tabSales': 'Gurgurtaa',
      'tabStockIn': 'Galii Kuusaa',
      'tabAudits': 'Lakkoofsa',
      'searchLedgerHint': 'Maqaa meeshaa, yaadannoo ykn ID-dhaan barbaadi...',

      // Admin, Settings & About EFA
      'languageSettingTitle': 'Afaan Appii',
      'languageSettingSubtitle':
          'Ingiliffa, Amaariffa fi Afaan Oromoo gidduutti jijjiiri.',
      'adminPanelTitle': 'Fayyadamtoota & Ramaddii Meeshaalee',
      'tabUsers': 'Fayyadamtoota',
      'tabCategories': 'Ramaddii',
      'companionSyncToggle': 'Wal-simannaa Server (Sync)',
      'btnSyncServer': 'Server Waliin Wal-simsiisi',
      'btnCreateUser': 'Fayyadamaa Haaraa Uumi',
      'fieldUsername': 'Maqaa Fayyadamaa *',
      'fieldEmail': 'Imeelii *',
      'fieldFullName': 'Maqaa Guutuu *',
      'fieldRole': 'Gahee',
      'fieldPassword': 'Jecha Darbii *',
      'roleStaff': 'Hojjetaa Kuusaa',
      'roleAdmin': 'Bulchaa (Admin)',
      'btnDeactivate': 'Dhorki',
      'btnActivate': 'Bani',
      'fieldCategoryCode': 'Koodii Ramaddii *',
      'fieldCategoryName': 'Maqaa Ramaddii *',
      'btnAddCategory': 'Ramaddii Dabali',

      // About EFA Section
      'aboutEfaTitle': 'Waa\'ee EFA',
      'developerNameLabel': 'Misoomsaa (Developer)',
      'developerPhoneLabel': 'Bilbila',
      'appVersionLabel': 'Gosa Appii (Version)',
      'buildNumberLabel': 'Lakkoofsa Ijaarsaa (Build)',
      'appDescriptionLabel': 'Ibsa Appii',

      // Login & Auth
      'loginTitle': 'Gara EFA Seeni',
      'loginSubtitle':
          'Kuusaa, gurgurtaa POS fi lakkoofsa lafaa fayyadamuuf eenyummeessaa keessan galchaa.',
      'loginUsernameOrEmail': 'Maqaa Fayyadamaa ykn Imeelii *',
      'loginPassword': 'Jecha Darbii *',
      'btnSignIn': 'Seeni',
      'btnSignOut': 'Ba\'i',

      // Common Actions & Dialogs
      'btnSave': 'Olkaa\'i',
      'btnCancel': 'Dhiisi',
      'btnDelete': 'Haqi',
      'btnArchive': 'Kuusi',
      'btnRestore': 'Deebisi',
      'btnReverse': 'Deebisi',
      'targetRecordLabel': 'Galmee Filatame',
      'confirmDeleteTitle': 'Haquu Mirkaneessi',
      'confirmArchiveTitle': 'Meeshaa Kuusi (Archive)',
      'confirmReverseTitle': 'Galmee Xumurame Deebisi (Reverse)',
      'reversalReasonLabel': 'Sababa Deebisuu (Dirqama) *',
      'reversalReasonHint': 'Fkn: Maamilli meeshaa deebise / dogoggora',
      'reversedByLabel': 'Kan deebise',
    },
  };
}
