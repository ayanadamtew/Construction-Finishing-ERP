# UI/UX Design System & Screen Specification (`UI_UX_SPEC.md`)

**Project:** Construction & Finishing Material Store Mobile ERP & Inventory Management System  
**Document Version:** 1.0  
**Source of Truth References:** `PROJECT_RULES.md`, `docs/PRODUCT_BRIEF.md`, `docs/SRS.md`, `docs/ARCHITECTURE.md`, `docs/DATABASE_DESIGN.md`, `docs/API_CONTRACT.md`

---

## 1. Design Philosophy & Domain Aesthetic

Construction and finishing material stores operate in high-tempo, bright-light counter and outdoor yard environments (handling rebar, cement bags, porcelain tiles, paint buckets, and hardware). The UI/UX avoids generic SaaS bloat and decorative clutter in favor of **Industrial Ledger Precision**:
1. **High-Contrast Daylight Legibility:** Crisp warm-stone neutrals (`#F8F7F4`) paired with deep structural slate (`#14171A`) and industrial safety-amber/terracotta accents (`#C85A17`) that remain legible on budget Android screens in outdoor yard sunlight.
2. **Zero-Pill Static Metadata Discipline:** Static metadata (material categories, tracking units, specification strings like `Ø12mm · Grade 60`, timestamps) is rendered as clean, unboxed typography separated by middle dots (`·`). Interactive category filters and language selectors (`EN` | `አማ` | `ORO`) are styled as tactile segmented control buttons.
3. **Tabular Numeric Discipline (`tabular-nums`):** Every quantity, remaining stock balance, variance delta, and Ethiopian Birr (`ETB`) currency figure uses monospace tabular numerals so columns and receipt lines align vertically to the decimal point.
4. **Adaptive Mobile-First & Desktop-Ready Layout:** Optimized for one-handed thumb operation on mobile viewports (`360px–480px`) via a persistent bottom navigation bar, while smoothly expanding on desktop/counter screens (`1024px–1440px`) into a persistent left navigation rail and multi-column workspace (never shrinking into a narrow mobile strip floating in empty desktop space).

---

## 2. Complete Screen Inventory

| Screen ID | Screen Name | SRS Traceability | Primary Operational Role |
| :--- | :--- | :--- | :--- |
| **`SCR-01`** | **Store Operations Dashboard** | `FR-020`, `FR-022`, `FR-023` | Real-time financial & inventory valuation overview (`ETB`), low-stock alerts, and 1-tap operational launchers. |
| **`SCR-02`** | **Material Catalog & Stock Directory** | `FR-001`–`FR-005`, `BR-001` | SKU-free searchable and category-filterable directory of all construction and finishing materials with live stock and unit cost/price visibility. |
| **`SCR-03`** | **Material Registration & Edit Sheet** | `FR-001`–`FR-004`, `VAL-001`–`003` | Focused modal/bottom-sheet for registering a new material or editing mutable metadata without permitting arbitrary stock tampering. |
| **`SCR-04`** | **Multi-Item Point-of-Sale (POS) Workbench** | `FR-006`–`FR-012`, `BR-002`, `BR-003` | Multi-item customer sale builder with editable unit selling price (`ETB`), live remaining-stock preview, and strict negative-stock blocking. |
| **`SCR-05`** | **Stock-In (Supplier Restocking) Workbench** | `FR-013`–`FR-015`, `BR-006` | Incoming delivery logger capturing quantity received, supplier unit purchase cost (`ETB`), and live weighted-average cost preview. |
| **`SCR-06`** | **Physical Ground-Stock Audit & Reconciliation** | `FR-016`–`FR-019`, `BR-008` | Yard count worksheet comparing expected app stock against actual physical count on the ground, highlighting variances, and synchronizing stock 100%. |
| **`SCR-07`** | **Transaction & Audit History Ledger** | `FR-021`, `BR-007` | Chronological, filterable ledger of all completed Sales receipts, Stock-In deliveries, and Physical Ground-Stock Audit adjustments. |

---

## 3. Design System Specification

### 3.1 Color Palette (60-30-10 Distribution & WCAG AA Compliance)

| Role | Token Name | Hex Value | Usage & Contrast Notes |
| :--- | :--- | :--- | :--- |
| **60% Canvas (Primary Background)** | `bg-canvas` | `#F6F5F1` | Warm concrete/limestone paper background; reduces glare in bright yard environments. |
| **30% Surface (Cards & Panels)** | `bg-surface` | `#FFFFFF` | Pure crisp white for primary data containers, ledger tables, and form sheets. |
| **30% Secondary Surface** | `bg-subtle` | `#ECEAE3` | Segmented filter tracks, table headers, and read-only calculation preview boxes. |
| **Structural Border** | `border-hairline` | `#DCD9D0` | `1px solid` all-around container borders and table row dividers (no thick left accent stripes). |
| **Primary Ink (Text)** | `text-primary` | `#14171A` | Deep forged iron; `15.8:1` contrast ratio against `#FFFFFF` (exceeds WCAG AAA). |
| **Secondary Ink** | `text-secondary` | `#4A5056` | Specifications (`Ø12mm · Grade 60`), timestamps, and field labels (`7.8:1` contrast). |
| **Muted Ink** | `text-muted` | `#6E757C` | Hints, unit suffixes, and inactive tab labels (`4.6:1` WCAG AA contrast). |
| **10% Primary Accent (Brand CTA)** | `accent-primary` | `#B84A14` | Industrial terracotta/rebar oxide; used strictly for primary action buttons and active state indicators (`5.3:1` contrast with white text). |
| **Primary Accent Hover/Pressed** | `accent-hover` | `#963B0E` | Darker pressed state for tactile feedback. |
| **Semantic Success (Stock In / Match)** | `status-success` | `#166534` | Deep forest green text on `#F0FDF4` surface for completed transactions and `0` audit variance. |
| **Semantic Warning (Low Stock)** | `status-warning` | `#9A3412` | Deep amber-rust text on `#FFF7ED` surface when `currentStock <= minStockLevel`. |
| **Semantic Danger (Blocked / Shortage)** | `status-danger` | `#B91C1C` | Crimson text (`5.9:1` contrast) on `#FEF2F2` surface for `INSUFFICIENT_STOCK` blocks and negative ground-audit variances. |

### 3.2 Typography System (2+1 Font Rule + Ethiopic Support)

- **Display & Section Headings:** `'Plus Jakarta Sans'`, fallback `'Noto Sans Ethiopic'`, `sans-serif` — Geometric clarity with strong weight differentiation (`600 SemiBold`, `700 Bold`).
- **Body, Labels & Trilingual Prose:** `'Public Sans'`, fallback `'Noto Sans Ethiopic'`, `sans-serif` — Designed for high-density government/industrial forms; renders English, Afan Oromo, and Amharic (`አማርኛ`) with generous x-height and open counters (`400 Regular`, `600 SemiBold`).
- **Numeric, Currency (`ETB`) & Stock Quantities:** `'JetBrains Mono'`, `monospace` with `font-variant-numeric: tabular-nums` — Used exclusively for prices, revenue totals, stock counts, and audit variances.

#### Type Scale
| Element | Size (`rem` / `px`) | Line Height | Weight | Tracking |
| :--- | :--- | :--- | :--- | :--- |
| **Page Title (`H1`)** | `1.5rem` (`24px`) | `1.25` | `700` | `-0.02em` |
| **Section Heading (`H2`)** | `1.125rem` (`18px`) | `1.35` | `600` | `-0.01em` |
| **Card / Material Title (`H3`)** | `1rem` (`16px`) | `1.4` | `600` | `0` |
| **KPI Metric Value** | `1.5rem` (`24px`) | `1.2` | `700` (`Mono`) | `-0.02em` |
| **Primary Body & Inputs** | `0.9375rem` (`15px`) | `1.5` | `400` / `500` | `0` |
| **Secondary Metadata & Labels** | `0.8125rem` (`13px`) | `1.4` | `500` | `0` |

### 3.3 Spacing & Geometry Math
- **Base Grid Unit:** `4px` (`0.25rem`).
- **Screen Outer Padding:** `16px` (`p-4`) on Mobile (`<768px`), `24px` (`p-6`) on Tablet, `32px` (`p-8`) on Desktop (`>=1024px`).
- **Card Padding:** `16px` (`p-4`) to `20px` (`p-5`), maintaining outer padding $\ge$ internal child gap (`12px` / `gap-3`).
- **Border Radius Scale:**
  - Outer containers/cards: `10px` (`rounded-lg`)
  - Inner buttons/inputs/segmented tabs: `6px` (`rounded-md`), satisfying nested radius math ($r_{\text{inner}} = r_{\text{outer}} - \text{padding}$).
- **Single-Elevation Rule:** Maximum 1 level of card elevation (`bg-white border border-[#DCD9D0]`). Never nest bordered cards inside bordered cards; use hairline horizontal dividers (`border-t border-[#ECEAE3]`) inside containers.

### 3.4 Core Reusable Components

#### Buttons
- **Minimum Touch Target:** `44px` height (`min-h-[44px]`), horizontal padding $\ge 2\times$ vertical padding (`px-4 py-2.5`).
- **Primary Button:** Solid `#B84A14` background, `#FFFFFF` text, `600` weight. Disabled state uses `#D6D3CD` background with `#78756F` text and `cursor-not-allowed`.
- **Secondary / Outline Button:** `#FFFFFF` background, `1px solid #DCD9D0` border, `#14171A` text, hover `#F6F5F1`.
- **Destructive / Remove Action:** Subtle text/icon button `#B91C1C`, hover `#FEF2F2` background (used for removing an item from the POS cart).

#### Cards & Ledger Rows
- Lead directly with the Material Name (`H3`) and right-aligned tabular stock balance (`e.g., 200 bars`).
- Subtitle line uses unboxed text with middle-dot separators:
  `Rebar · Ø12mm Grade 60 · Cost: ETB 850.00 · Sell: ETB 980.00`
- Zero decorative status dots or pill wrappers. Low-stock items display a quiet inline text indicator (`Low stock: min 30 bars`) in `#9A3412`.

#### Forms & Numeric Inputs
- Every input has a persistent visible `<label>` above the field (never placeholder-only labels).
- Numeric fields (`quantity`, `unitSellingPrice`, `unitPurchaseCost`, `physicalCount`) use `inputMode="decimal"`, right-aligned or monospace tabular numerals, and explicit unit/currency suffixes (`ETB`, `bars`, `bags`) inside the input frame.
- Field validation errors render immediately below the input in `13px` `#B91C1C` text.

#### Navigation Architecture
- **Top Header Bar:** Sticky `56px` height displaying the store title, active view title, and the 3-way segmented **Language Switcher** (`EN` | `አማ` | `ORO`).
- **Mobile Navigation (`< 1024px`):** Fixed 5-item bottom navigation bar (`64px` height) with clear icons and single-line labels:
  1. `Dashboard` (`SCR-01`)
  2. `Materials` (`SCR-02`)
  3. `POS Sale` (`SCR-04`)
  4. `Stock-In` (`SCR-05`)
  5. `Audit & Log` (`SCR-06` / `SCR-07`)
- **Desktop Navigation (`>= 1024px`):** Fixed `240px` left navigation rail with the same 5 primary destinations, allowing the main workspace to utilize up to `1200px` of multi-column width.

#### Tables & Responsive Lists
- On Desktop (`>= 768px`), catalog, cart lines, audit worksheets, and transaction history render in structured data tables with right-aligned numeric columns (`tabular-nums`).
- On Mobile (`< 768px`), tables automatically adapt into structured ledger rows with hairline dividers so there is zero horizontal scrolling.

#### Modals & Bottom Sheets
- Used strictly for **Material Registration / Metadata Edit (`SCR-03`)**.
- Renders as a slide-up bottom sheet on mobile (`max-h-[90vh]` with sticky header/footer) and a centered dialog (`max-w-lg`) on desktop, with backdrop click and `Esc` key dismissal.

---

## 4. Detailed Screen-by-Screen Design Specification

---

### `SCR-01`: Store Operations Dashboard (`DashboardView`)

- **Purpose:** Provide the store operator with an immediate, at-a-glance financial and inventory pulse in `ETB`, highlight materials requiring restocking (`currentStock <= minStockLevel`), and offer 1-tap shortcuts to record a sale, log a stock-in, or run a ground-stock audit (`FR-020`).
- **Layout:**
  - **Mobile:** Vertical stack—Quick Action Bar (3 buttons) $\rightarrow$ 2×2 KPI Metric Grid $\rightarrow$ Low-Stock Attention List $\rightarrow$ Recent 5 Transactions preview.
  - **Desktop (`1024px+`):** Top 4-column KPI Metric Row $\rightarrow$ 2-column split below (`Left 60%`: Low-Stock & Inventory Category Breakdown; `Right 40%`: Quick Actions & Recent Transactions).
- **Components:**
  1. `KpiSummaryGrid`: 4 clean metric blocks separated by hairline borders:
     - **Total Sales Revenue (`ETB`)** + count of completed sales.
     - **Total Gross Profit (`ETB`)** + margin subtitle.
     - **Inventory Cost Value (`ETB`)** + retail valuation subtitle (`ETB`).
     - **Low-Stock Items** count (`currentStock <= minStockLevel`).
  2. `QuickOperationBar`: Direct navigation buttons to `+ Record Sale` (`SCR-04`), `+ Stock-In` (`SCR-05`), and `Ground Audit` (`SCR-06`).
  3. `LowStockAlertList`: Lists every material where `currentStock <= minStockLevel`, showing `Material Name`, `Current Stock / Min Level`, and a direct `Restock` button that opens `SCR-05` pre-selected with that material.
- **Navigation:** Default home screen (`Tab 1`); quick buttons route directly to `SCR-04`, `SCR-05`, `SCR-06`, or `SCR-02`.
- **User Interactions:**
  - Clicking `Restock` on any low-stock material navigates to `SCR-05` (`Stock-In`) with that `materialId` pre-selected.
  - Clicking `+ Record Sale` navigates to `SCR-04` (`POS Sale`).
- **Required Data:** `summary` (`totalRevenue`, `totalProfit`, `inventoryCostValue`, `inventoryRetailValue`, `lowStockCount`), `materials` filtered by `currentStock <= minStockLevel`, and latest 5 records across `sales`, `stockIns`, `audits`.
- **Validation:** Read-only view; all monetary values formatted via `formatETB(value)` (`ETB #,##0.00`).
- **Loading State:** Skeleton placeholders matching exact KPI row height (`88px`) and list row heights (`56px`) to prevent layout shift.
- **Empty State:**
  - If catalog has 0 materials: Clean onboarding prompt with a primary CTA button `Register First Material` opening `SCR-03`.
  - If `lowStockCount === 0`: Quiet confirmation message *"All registered materials are above minimum stock levels."*
- **Error State:** Top inline error banner with localized error description and a `Retry` button if `GET /api/state` fails.
- **Success State:** Real-time synchronized numbers immediately reflecting the latest sale, restock, or ground audit.

---

### `SCR-02`: SKU-Free Material Catalog & Stock Directory (`MaterialsView`)

- **Purpose:** Enable rapid lookup, filtering, registration, and metadata editing of construction and finishing materials without SKU codes or warehouse bin locations (`FR-001`–`FR-005`).
- **Layout:**
  - Sticky filter bar at top containing Search Input, Category Segmented Filter (`All`, `Rebar`, `Cement`, `Tiles`, `Paint`, `Hardware`, `Other`), Low-Stock toggle, and `+ New Material` primary button.
  - Main area renders the responsive Material Ledger Table (Desktop) / Divided Ledger List (Mobile).
- **Components:**
  1. `CatalogSearchAndFilterBar`: Instant client-side search matching `name` and `specs` substrings (e.g., `"12mm"`, `"Grade 60"`, `"50kg"`).
  2. `MaterialLedgerRow`: Displays:
     - Primary line: `name` (`16px SemiBold`) and right-aligned `currentStock` + `unit` (`tabular-nums Bold`).
     - Secondary line (unboxed metadata with `·` separators): `Category · Specs · Unit Cost: ETB X.XX · Selling Price: ETB Y.YY · Min Stock: Z`.
     - Row actions: `Sell` (adds to POS or jumps to `SCR-04`), `Stock-In` (jumps to `SCR-05` for this item), and `Edit` (opens `SCR-03` modal).
- **Navigation:** Accessed via `Tab 2 (Materials)`.
- **User Interactions:**
  - Typing in search or clicking a category tab filters the list in `< 16ms`.
  - Clicking `+ New Material` opens `SCR-03` in Create mode.
  - Clicking `Edit` on any row opens `SCR-03` in Edit mode.
- **Required Data:** `materials: Material[]`.
- **Validation:** Search query is safely trimmed; read-only stock display enforces `BR-004` (stock cannot be edited inline here).
- **Loading State:** 6 shimmer ledger rows.
- **Empty State:**
  - When search/filter matches 0 items: *"No materials match your filter."* with a `Reset Filters` button.
  - When catalog is empty: *"No materials registered yet."* with `+ New Material` button.
- **Error State:** Inline banner if catalog refresh fails.
- **Success State:** Newly created or edited material highlights briefly and appears in sorted order.

---

### `SCR-03`: Material Registration & Metadata Edit Sheet (`MaterialFormModal`)

- **Purpose:** Register new construction/finishing materials using a single tracking unit (`FR-001`, `FR-002`) or edit mutable metadata (`name`, `category`, `specs`, `minStockLevel`, `defaultSellingPrice`) while strictly preventing direct tampering with `currentStock` (`FR-003`, `FR-004`, `BR-001`).
- **Layout:** Slide-up bottom sheet on mobile / centered modal dialog (`max-w-lg`) on desktop with a 2-column numeric field row.
- **Components:**
  1. `name` text input (Required, `1..120` chars, e.g., *"Deformed Rebar 12mm"*).
  2. `category` select/segmented control (`rebar`, `cement`, `tiles`, `paint`, `hardware`, `other`).
  3. `specs` text input (Optional, `0..120` chars, e.g., *"Ø12mm · Grade 60 · 12m"*).
  4. `unit` selector (`pcs`, `bars`, `bags`, `boxes`, `buckets`, `kg`, `m`, `liters`). *Note: Locked/read-only in Edit mode if transactions already exist for this material (`BR-001`).*
  5. **Create Mode Only:** `initialStock` ($\ge 0$) and `unitCost` (`ETB` $\ge 0$). *(In Edit mode, these fields are displayed as read-only informational text with a note explaining that stock and cost are updated via POS Sales, Stock-In, or Ground Audit per `FR-004`.)*
  6. `defaultSellingPrice` (`ETB` $\ge 0$) and `minStockLevel` ($\ge 0$).
- **Navigation:** Modal overlay triggered from `SCR-02` (`Materials`) or `SCR-01` (`Dashboard`).
- **User Interactions:** Fill fields $\rightarrow$ live inline validation $\rightarrow$ submit (`POST /api/materials` or `PATCH /api/materials/:id`) or cancel.
- **Required Data:** In Edit mode, existing `Material` object and boolean `hasTransactions`.
- **Validation:** Enforces `VAL-001` (non-empty name), `VAL-002` (valid category/unit), and `VAL-003` (non-negative finite numbers for stock, cost, and price).
- **Loading State:** Submit button shows spinner and disables inputs while saving.
- **Empty State:** N/A (form).
- **Error State:** Field-level red error text below invalid inputs + modal top error message if server returns `400`.
- **Success State:** Modal closes automatically and triggers a localized confirmation banner on `SCR-02` (*"Material saved successfully"*).

---

### `SCR-04`: Multi-Item Point-of-Sale (POS) Workbench (`SalesPosView`)

- **Purpose:** Allow the operator to build a multi-item customer sale cart, customize the unit selling price (`ETB`) per item, preview exact line subtotals, total receipt revenue, and remaining stock after sale, and strictly block any sale where requested quantity exceeds current stock (`FR-006`–`FR-012`, `BR-002`, `BR-003`).
- **Layout:**
  - **Mobile (`< 1024px`):** Top Material Quick-Picker (searchable dropdown/list showing available stock) $\rightarrow$ Active Sale Cart Line Items $\rightarrow$ Customer Note input $\rightarrow$ Sticky Bottom Checkout Summary Bar (`Total Revenue ETB` + `Complete Sale` button).
  - **Desktop (`>= 1024px`):** 2-column split workspace:
    - **Left Column (45% width):** Searchable Material Picker list (1-click to add material to cart; out-of-stock materials with `currentStock === 0` are clearly marked `Out of stock` and disabled).
    - **Right Column (55% width):** Multi-Item Sale Receipt Cart, Customer Note field, Live Calculation Breakdown, and `Complete Sale` primary CTA.
- **Components:**
  1. `PosMaterialPicker`: Displays each material's `Name`, `Specs`, `Default Price (ETB)`, and `Available Stock + Unit`. Clicking `+ Add` adds the material to the cart (or increments quantity if already in cart per `FR-007`).
  2. `PosCartLineItem`: For each item in the cart:
     - Header: `Material Name` + `Available: X [unit]` + `Remove` button.
     - Input Row:
       - `Quantity Sold` numeric input (`step="any"`, `min="0.01"`) with `unit` suffix.
       - `Unit Selling Price (ETB)` numeric input pre-filled with `defaultSellingPrice` (`FR-008`).
     - Live Output Row (`FR-009`):
       - `Line Subtotal: ETB [quantity × unitSellingPrice]` (`tabular-nums`).
       - `Remaining Stock After Sale: [currentStock - quantity] [unit]` (`tabular-nums`).
     - **Strict Stock-Floor Guard (`FR-011`, `BR-002`):** If `quantity > currentStock`, the line border turns `#B91C1C`, `Remaining Stock` displays a clear localized error (*"Exceeds available stock of X [unit] — sale blocked"*), and checkout is disabled.
  3. `PosCheckoutFooter`: Displays total item count, `Total Revenue (ETB)` (`FR-010`), and `Complete Sale` button.
- **Navigation:** Accessed via `Tab 3 (POS Sale)` or quick actions on `SCR-01`/`SCR-02`.
- **User Interactions:**
  - Select one or multiple materials $\rightarrow$ adjust `quantity` and `unitSellingPrice` $\rightarrow$ system recalculates all totals in real time $\rightarrow$ click `Complete Sale` (`POST /api/sales`).
- **Required Data:** `materials: Material[]`, local draft `cartItems: PosCartItem[]`, `customerNote: string`.
- **Validation:**
  - Cart must have $\ge 1$ item (`VAL-006`).
  - Every line must have `quantity > 0` (`VAL-004`) and `quantity <= material.currentStock` (`VAL-005`).
  - Every line must have `unitSellingPrice >= 0` (`VAL-003`).
- **Loading State:** `Complete Sale` button displays processing indicator and locks cart inputs during API submission.
- **Empty State:** When cart has `0` items, the cart panel shows clear instructions (*"Select materials from the catalog to build a customer sale receipt."*) and a disabled `Complete Sale` button.
- **Error State:**
  - Client-side oversale attempt: Instant inline red error on the specific line item; `Complete Sale` button is disabled.
  - Server-side `400 INSUFFICIENT_STOCK`: Preserves all cart items (`FAIL-003`), highlights the offending item, and displays the exact available stock.
- **Success State:** Clears the draft cart, displays a dismissible **Sale Receipt Confirmation Card** showing the completed receipt ID, line items sold, `Total Revenue (ETB)`, and updated remaining stock balances.

---

### `SCR-05`: Stock-In (Supplier Restocking) Workbench (`StockInView`)

- **Purpose:** Record incoming supplier material deliveries with `Quantity Added` and `Supplier Unit Purchase Cost (ETB)`, previewing total restock expenditure, new stock balance, and updated weighted-average unit cost before committing (`FR-013`–`FR-015`, `BR-006`).
- **Layout:**
  - **Mobile:** Restock Form Card at top $\rightarrow$ Live Calculation Preview Box $\rightarrow$ Recent Stock-In Deliveries list below.
  - **Desktop (`>= 1024px`):** Left Column (50%): Restock Entry Form & Live Calculation Preview; Right Column (50%): Recent Stock-In Ledger Table.
- **Components:**
  1. `MaterialSelector`: Searchable selector showing current stock and current `unitCost (ETB)`.
  2. `quantityAdded` numeric input ($> 0$) with the selected material's `unit` label.
  3. `unitPurchaseCost` numeric input ($\ge 0$, in `ETB`) pre-populated with the material's latest `unitCost` for convenience.
  4. `supplierNote` text input (Optional, e.g., *"Dangote Factory Truck #14"*).
  5. `StockInLivePreview` (`FR-014`, `BR-006`): Read-only `#ECEAE3` calculation card showing:
     - `Previous Stock` $\rightarrow$ `New Stock Balance` (`previousStock + quantityAdded`)
     - `Total Restock Cost (ETB)` (`quantityAdded × unitPurchaseCost`)
     - `Updated Weighted-Average Unit Cost (ETB)`
- **Navigation:** Accessed via `Tab 4 (Stock-In)` or `Restock` buttons on `SCR-01`/`SCR-02`.
- **User Interactions:** Choose material $\rightarrow$ enter quantity received & supplier unit cost $\rightarrow$ verify live preview $\rightarrow$ click `Confirm Stock-In` (`POST /api/stock-in`).
- **Required Data:** `materials: Material[]`, `stockIns: StockInRecord[]`.
- **Validation:** `materialId` required (`VAL-007`), `quantityAdded > 0` (`VAL-004`), `unitPurchaseCost >= 0` (`VAL-003`).
- **Loading State:** Submit button disabled with spinner during `POST /api/stock-in`.
- **Empty State:** If no materials exist in catalog yet, prompts user to register a material first.
- **Error State:** Inline field validation message or top error banner if request fails; user inputs remain intact.
- **Success State:** Form resets quantity/note, displays a green confirmation banner (*"Stock-In recorded: +100 bags added. New stock: 240 bags"*), and prepends the new record to the Recent Stock-In list.

---

### `SCR-06`: Physical Ground-Stock Audit & Reconciliation (`StockAuditView`)

- **Purpose:** Keep the remaining stock shown in the app and the physical stock on the ground 100% synchronized by allowing the operator to enter actual ground counts, inspect exact variances (`Physical Count - System Stock`), and commit an auditable reconciliation (`FR-016`–`FR-019`, `BR-008`).
- **Layout:**
  - Top bar with Category Filter, Search Input, Audit Reason/Note field (`note`), and summary counter (`X items counted · Y variances detected`).
  - Main Audit Worksheet table (Desktop) / structured list (Mobile) listing materials with their `Expected App Stock`, `Physical Ground Count` input, and live `Variance` column.
  - Sticky bottom action bar with `Clear Counts` and `Commit Ground Audit & Sync Stock` primary button.
- **Components:**
  1. `AuditWorksheetRow`: For each material:
     - `Material Name` + `Category · Specs`.
     - `Expected System Stock`: Read-only `currentStock` + `unit` (`tabular-nums`).
     - `Physical Ground Count` input: Numeric input (`>= 0`) with a quick `Match (=)` button for 1-tap confirmation when ground stock matches app stock.
     - `Live Variance Display` (`FR-018`):
       - Blank if no count entered yet (item untouched in this audit session per `BR-008`).
       - `0 [unit] (Exact Match)` in `#166534` if `physicalCount === expectedStock`.
       - `+X [unit] (Surplus)` in `#9A3412` if `physicalCount > expectedStock`.
       - `-X [unit] (Shortage)` in `#B91C1C` ( plus `ETB` cost impact) if `physicalCount < expectedStock`.
  2. `AuditCommitFooter`: Shows count of materials being reconciled in this batch and submits `POST /api/audits`.
- **Navigation:** Accessed via `Tab 5 (Audit & Log)` with segmented sub-tab `Ground Audit`.
- **User Interactions:** Walk the yard/store with mobile phone $\rightarrow$ enter observed physical counts for audited items $\rightarrow$ review variances $\rightarrow$ enter optional audit note $\rightarrow$ click `Commit Ground Audit & Sync Stock`.
- **Required Data:** `materials: Material[]`, local draft map `physicalCounts: Record<string, string>`, `auditNote: string`.
- **Validation:** At least 1 material must have a valid `physicalCount >= 0` entered (`VAL-006`, `VAL-003`). Negative numbers are strictly rejected.
- **Loading State:** Commit button shows spinner and locks worksheet rows during `POST /api/audits`.
- **Empty State:** If catalog has 0 materials, prompts user to register materials first.
- **Error State:** Inline red error on any row with invalid negative input; top error banner if server call fails while preserving all entered ground counts.
- **Success State:** Clears draft inputs, updates `currentStock` across all views to 100% match the physical counts, and displays a confirmation summary with a link to view the permanent record in `SCR-07`.

---

### `SCR-07`: Transaction & Audit History Ledger (`HistoryView`)

- **Purpose:** Provide complete financial and inventory accountability by displaying an immutable chronological ledger of all `Sales`, `Stock-In` deliveries, and `Physical Ground-Stock Audits` (`FR-021`, `BR-007`).
- **Layout:**
  - Top segmented filter bar: `All Transactions` | `Sales` | `Stock-In` | `Ground Audits` + Search input.
  - Chronological list of ledger cards/rows ordered newest-first (`createdAt DESC`).
- **Components:**
  1. `SaleLedgerEntry`: Shows Receipt ID, timestamp, optional `customerNote`, `Total Revenue (ETB)`, `Gross Profit (ETB)`, and expandable/inline breakdown of each `SaleLineItem` (`quantity × unitSellingPrice = lineTotal`).
  2. `StockInLedgerEntry`: Shows Record ID, timestamp, Material Name, `+quantityAdded [unit]`, `Supplier Unit Cost (ETB)`, `Total Restock Cost (ETB)`, `Previous Stock -> New Stock`, and `supplierNote`.
  3. `AuditLedgerEntry`: Shows Audit ID, timestamp, `note`, and each `AuditLineItem` (`Expected Stock` $\rightarrow$ `Physical Count`, `Variance`, and `Unit Cost Snapshot`).
- **Navigation:** Accessed via `Tab 5 (Audit & Log)` with segmented sub-tab `History Ledger` (or via `View All` on Dashboard).
- **User Interactions:** Toggle transaction type filter (`All`, `Sales`, `Stock-In`, `Audits`) or search by material name/note.
- **Required Data:** `sales: SaleTransaction[]`, `stockIns: StockInRecord[]`, `audits: StockAuditRecord[]`.
- **Validation:** Read-only historical ledger (`BR-007`).
- **Loading State:** Shimmer ledger entries.
- **Empty State:** *"No transactions recorded in this category yet."*
- **Error State:** Inline retry banner if state fetch fails.
- **Success State:** Displays accurate, immutable historical records in the active language (`en` / `am` / `om`).

---

## 5. Responsive Behavior Matrix

| Viewport Breakpoint | Navigation Pattern | Layout Adaptation | Touch & Density Rules |
| :--- | :--- | :--- | :--- |
| **Mobile (`320px – 767px`)** | Sticky Top Header (`56px`) + Fixed 5-Tab Bottom Bar (`64px`) | Single-column stacked workspace; POS Cart and Sticky Checkout Bar sit above bottom nav; tables render as structured multi-line ledger rows. | Minimum `44px × 44px` touch targets; `16px` container padding; zero horizontal overflow. |
| **Tablet (`768px – 1023px`)** | Sticky Top Header + Fixed 5-Tab Bottom Bar | 2-column KPI grid; structured tabular lists for Catalog, Audit Worksheet, and History. | `24px` container padding; side-by-side form inputs. |
| **Desktop (`1024px – 1440px+`)** | Fixed Left Navigation Rail (`240px`) + Top Workspace Header | Full multi-column ERP layout (`max-w-[1360px]`): POS shows Material Picker (`45%`) alongside Live Receipt Cart (`55%`); Stock-In shows Form (`50%`) alongside History (`50%`). | `32px` container padding; keyboard-friendly tab order and visible focus rings (`focus-visible:ring-2`). |
