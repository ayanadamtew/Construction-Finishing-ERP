# Software Requirements Specification (SRS)
**Project:** Construction & Finishing Material Store Mobile ERP & Inventory Management System  
**Document Version:** 1.0 (Approved Baseline)  
**Source of Truth Reference:** `docs/PRODUCT_BRIEF.md`, `PROJECT_RULES.md`

---

## 1. Project Overview
The Construction & Finishing Material Store Mobile ERP & Inventory Management System is a mobile-first web application designed specifically for retail and yard operations selling construction and finishing materials (such as rebar of varying diameters and grades, cement, tiles, paint, and hardware).

Unlike complex generic ERP software that requires alphanumeric SKU hierarchies, barcode scanners, and multi-bin warehouse mapping, this system tracks each material using a **single tracking unit** (`pcs`, `bars`, `bags`, `boxes`, `buckets`, `kg`, `m`, `liters`). It supports **multi-item sales transactions**, dynamic unit selling prices in **Ethiopian Birr (`ETB`)**, **Stock-In (restocking)** with supplier unit purchase cost tracking, **strict negative-stock blocking**, a **Physical Ground-Stock Audit** workflow for 100% synchronization between digital and ground stock, and a trilingual interface supporting **English (`en`)**, **Amharic (`am` - አማርኛ)**, and **Afan Oromo (`om` - Afaan Oromoo)**.

---

## 2. Objectives and Scope

### 2.1 Business Objectives
- **OBJ-001:** Eliminate manual calculation errors in multi-item sales and inventory deduction.
- **OBJ-002:** Maintain 100% synchronization between the remaining stock displayed in the application and physical stock on the ground through structured Stock-In and Ground-Stock Audit workflows.
- **OBJ-003:** Prevent overselling and negative stock balances by strictly blocking any sale that exceeds available inventory.
- **OBJ-004:** Provide instant visibility into daily and cumulative sales revenue, cost of goods sold, gross profit, and inventory valuation in Ethiopian Birr (`ETB`).
- **OBJ-005:** Ensure accessible, rapid operation (< 15 seconds per transaction) on mobile devices in English, Amharic, and Afan Oromo.

### 2.2 In-Scope Modules
1. **Material Catalog & Registration Module:** Single-unit, SKU-free material registration, editing, search, and category filtering.
2. **Multi-Item Point-of-Sale (POS) Module:** Cart-based sales recording with per-item quantity, editable unit selling price (`ETB`), live revenue/remaining-stock preview, and strict stock-floor enforcement.
3. **Stock-In (Restocking) Module:** Recording incoming supplier deliveries with quantity added and supplier unit purchase cost (`ETB`).
4. **Physical Ground-Stock Audit Module:** Comparing system stock against actual physical ground counts, calculating variances, and committing auditable stock adjustments.
5. **Dashboard & Transaction Ledger Module:** Real-time financial/stock KPIs, low-stock alerts, and chronological history of Sales, Stock-Ins, and Audit Adjustments.
6. **Localization & Preferences Module:** Instant language switching (`en`, `am`, `om`) and `ETB` currency formatting.

---

## 3. Stakeholders

| Stakeholder ID | Role / Title | Responsibility & Interest |
| :--- | :--- | :--- |
| **STK-001** | **Store Owner / Operator** | Primary business stakeholder and system operator; relies on accurate stock balances, revenue/profit metrics in `ETB`, and ground-stock audit integrity. |
| **STK-002** | **Store Clerk / Yard Attendant** | Operates the application on a mobile device during counter sales, supplier deliveries, and physical yard stock counts. |
| **STK-003** | **Software Architect / Engineering Lead** | Ensures architectural integrity, security, requirement compliance, and automated testing per `PROJECT_RULES.md`. |

---

## 4. User Roles and Permissions

Per `docs/PRODUCT_BRIEF.md` (Section 5), the system operates in a **Single-User Operational Model**.

- **ROLE-001 (Store Operator - Single User):**
  - Has full access to view dashboard metrics, register and edit materials, record multi-item sales, record Stock-In deliveries with supplier purchase costs, execute physical ground-stock audits, view full transaction history, and switch application languages (`en`, `am`, `om`).
  - No multi-user role-based access control (RBAC) or login barrier is required in the MVP.

---

## 5. Functional Requirements

### 5.1 Material Catalog & Registration
- **FR-001:** The system shall allow the user to register a new construction or finishing material with: Material Name, Category (`rebar`, `cement`, `tiles`, `paint`, `hardware`, `other`), Optional Specifications (e.g., diameter/grade or dimensions), Single Tracking Unit (`pcs`, `bars`, `bags`, `boxes`, `buckets`, `kg`, `m`, `liters`), Initial Stock Quantity, Minimum Stock Alert Level, Supplier Unit Purchase Cost (`ETB`), and Default Unit Selling Price (`ETB`).
- **FR-002:** The system shall NOT require or enforce SKU codes, barcodes, or warehouse bin location fields during material registration or management.
- **FR-003:** The system shall allow the user to edit an existing material's Name, Category, Specifications, Minimum Stock Alert Level, and Default Unit Selling Price (`ETB`).
- **FR-004:** The system shall prevent direct arbitrary editing of a material's `currentStock` from the metadata edit form; after initial creation, all stock quantity changes must occur strictly through a `Sale`, `Stock-In`, or `Physical Ground-Stock Audit` transaction.
- **FR-005:** The system shall allow the user to search materials by name or specification substring and filter materials by Category or Low-Stock status.

### 5.2 Multi-Item Point-of-Sale (POS)
- **FR-006:** The system shall allow the user to build a multi-item sale cart containing one or more distinct materials.
- **FR-007:** If the user selects a material that is already present in the current sale cart, the system shall either merge/increment the line item quantity or update the existing line item so that total requested quantity for that material is validated as a single aggregate against `currentStock`.
- **FR-008:** When adding a material to the sale cart, the system shall pre-fill the `Unit Selling Price (ETB)` with the material's `defaultSellingPrice` while allowing the user to override it with any valid non-negative price for that transaction.
- **FR-009:** For each line item in the sale cart, the system shall automatically calculate and display:
  - `Line Revenue Subtotal (ETB) = Quantity Sold × Unit Selling Price`
  - `Projected Remaining Stock = Current Stock - Quantity Sold`
- **FR-010:** For the entire sale cart, the system shall automatically calculate and display the `Total Sale Revenue (ETB)` as the sum of all line subtotals.
- **FR-011:** The system shall strictly block adding a line item or completing a sale transaction if any line item's `Quantity Sold` is greater than the material's current available stock (`currentStock`).
- **FR-012:** Upon confirming a valid multi-item sale, the system shall atomically:
  1. Deduct each sold item's quantity from its material `currentStock`.
  2. Snapshot each item's current `unitCost` to calculate `lineProfit = Quantity Sold × (Unit Selling Price - unitCostSnapshot)`.
  3. Persist the `SaleTransaction` record with timestamp, optional customer note, line items, `totalRevenue`, and `totalProfit`.

### 5.3 Stock-In (Restocking)
- **FR-013:** The system shall allow the user to record a Stock-In (restocking) transaction for any registered material by specifying: Material, `Quantity Added`, `Supplier Unit Purchase Cost (ETB)`, and an optional Supplier/Delivery Note.
- **FR-014:** The system shall automatically calculate and display the `Total Restock Cost (ETB) = Quantity Added × Supplier Unit Purchase Cost` and the `New Stock Balance = Current Stock + Quantity Added` before confirmation.
- **FR-015:** Upon confirming a Stock-In transaction, the system shall atomically:
  1. Increase the material's `currentStock` by `Quantity Added`.
  2. Update the material's `unitCost` using a weighted average cost formula (or latest purchase cost when previous stock was `0`), defined in **BR-006**.
  3. Persist the `StockInRecord` in the transaction ledger.

### 5.4 Physical Ground-Stock Audit & Reconciliation
- **FR-016:** The system shall provide a Physical Ground-Stock Audit workflow listing registered materials alongside their expected `System Stock` (`currentStock`) and tracking unit.
- **FR-017:** The system shall allow the user to enter the observed `Physical Ground Count` ($\ge 0$) for one or more materials and an optional audit note/reason.
- **FR-018:** For each material with a entered physical count, the system shall automatically compute and display the `Variance = Physical Ground Count - Expected System Stock` (indicating shortage when negative, surplus when positive, and exact match when zero).
- **FR-019:** Upon committing a Physical Ground-Stock Audit, the system shall atomically update each audited material's `currentStock` to equal its `Physical Ground Count` and persist an immutable `StockAuditRecord` containing all audited items, expected quantities, physical counts, variances, and unit cost snapshots.

### 5.5 Dashboard & Transaction Ledger
- **FR-020:** The system shall display a real-time Dashboard showing:
  - Total Sales Revenue (`ETB`)
  - Total Gross Profit (`ETB`)
  - Total Current Inventory Valuation at Cost (`ETB`) and at Retail (`ETB`)
  - Count and list of Low-Stock / Out-of-Stock Materials (`currentStock <= minStockLevel`)
- **FR-021:** The system shall display a chronological Transaction History Ledger showing all `Sales`, `Stock-In` deliveries, and `Physical Ground-Stock Audits`, with filtering by transaction type.

### 5.6 Localization & Currency
- **FR-022:** The system shall provide an accessible language switcher allowing the user to toggle the entire user interface dynamically between **English (`en`)**, **Amharic (`am` - አማርኛ)**, and **Afan Oromo (`om` - Afaan Oromoo)** without losing unsaved state.
- **FR-023:** The system shall format all monetary values clearly in **Ethiopian Birr (`ETB` / `ብር`)** rounded to two decimal places.

---

## 6. Non-Functional Requirements

- **NFR-001 (Mobile-First Responsiveness):** The UI shall be fully usable on mobile viewports (`320px` to `480px` width) as well as tablets and desktops, with touch targets of at least `44px × 44px` and zero horizontal page overflow.
- **NFR-002 (Performance):** All cart calculations, stock variance previews, and language switches shall execute in `< 50ms` on the client; API read/write operations shall complete in `< 500ms` under local/standard network conditions.
- **NFR-003 (Arithmetic Precision):** All currency (`ETB`) and quantity calculations shall avoid IEEE-754 floating-point drift by rounding deterministic results to at most 2 decimal places (`0.01`).
- **NFR-004 (Data Persistence):** All materials, sales, stock-ins, and audit records shall persist on the server across browser refreshes and server restarts.
- **NFR-005 (Usability & Clarity):** Every screen shall clearly handle loading, empty, error, and success states with localized messages (`en`, `am`, `om`), and never use `window.alert` or `window.confirm`.

---

## 7. Business Rules & Resolution of Potential Contradictions

During requirements engineering, potential ambiguities and edge cases were analyzed and resolved into the following binding business rules:

- **BR-001 (Single Tracking Unit Invariant):** Each material has exactly one tracking unit (`unit`) set at creation. Once transactions exist for a material, its `unit` cannot be changed to prevent historical ledger corruption.
- **BR-002 (Strict Non-Negative Stock Floor):** `currentStock` for any material must never be $< 0$. Any sale request where `requestedQuantity > currentStock` is strictly rejected on both frontend and backend.
- **BR-003 (Aggregate Cart Validation):** In a multi-item sale, a single material may not appear on multiple separate lines to bypass `currentStock`. All quantities for the same `materialId` in a cart are aggregated into a single line item and validated against `currentStock`.
- **BR-004 (Immutable Stock Mutation Path):** After initial material creation, `currentStock` can only be mutated via three auditable operations: `SaleTransaction` (decrements stock), `StockInRecord` (increments stock), or `StockAuditRecord` (reconciles stock to physical count).
- **BR-005 (Initial Stock Ledger Traceability):** When a material is registered with `initialStock > 0`, the system records the initial `unitCost` and `currentStock` immediately so inventory valuation is accurate from creation.
- **BR-006 (Weighted Average Cost on Stock-In):** When a `Stock-In` occurs with `quantityAdded > 0` at `unitPurchaseCost`:
  - If `previousStock == 0`, the material's new `unitCost = unitPurchaseCost`.
  - If `previousStock > 0`, the material's new `unitCost = round(((previousStock × oldUnitCost) + (quantityAdded × unitPurchaseCost)) / (previousStock + quantityAdded), 2)`.
  - This ensures accurate ongoing gross profit and inventory valuation when supplier prices fluctuate.
- **BR-007 (Historical Price/Cost Immutability):** Changing a material's `defaultSellingPrice` or updating its `unitCost` via a new `Stock-In` must never retroactively alter `totalRevenue` or `totalProfit` of previously completed `SaleTransaction` records.
- **BR-008 (Audit Reconciliation Scope):** During a Physical Ground-Stock Audit, the user may enter counts for all materials or a subset of materials being audited in that session. Only materials for which a physical count is explicitly provided in the audit submission are adjusted and logged.

---

## 8. User Stories

- **US-001 (Register Material):** As a store operator, I want to register construction materials (such as 12mm Grade 60 rebar or 50kg cement bags) using a single tracking unit without SKU codes or bin locations, so that I can set up my catalog quickly.
- **US-002 (Record Multi-Item Sale):** As a store operator, I want to add multiple materials to a single customer sale, adjust the unit selling price in `ETB` if needed, and see the automatic total revenue and remaining stock before confirming, so that checkout is fast and error-free.
- **US-003 (Prevent Overselling):** As a store operator, I want the system to block any sale where the quantity requested exceeds current stock, so that I never sell materials that are not physically available.
- **US-004 (Record Stock-In with Supplier Cost):** As a store operator, I want to log incoming stock deliveries along with the supplier unit purchase cost in `ETB`, so that my available stock and purchase costs stay accurate.
- **US-005 (Synchronize Ground Stock via Audit):** As a store operator, I want to enter actual physical counts observed on the ground and see the variance against app stock, so that I can synchronize the app 100% with physical yard stock.
- **US-006 (Switch Language):** As a store operator, I want to switch the interface between English, Amharic (አማርኛ), and Afan Oromo (Afaan Oromoo), so that I can use the app in my preferred language.
- **US-007 (Monitor Store Performance):** As a store operator, I want to view total sales revenue, gross profit, inventory value in `ETB`, low-stock alerts, and transaction history on my dashboard.

---

## 9. Acceptance Criteria (Given / When / Then)

### AC-001: SKU-Free Material Registration (`FR-001`, `FR-002`)
- **Given** the user is on the Material Registration form,
- **When** the user enters Name `"Deformed Rebar 12mm"`, Category `"rebar"`, Specs `"Ø12mm • Grade 60"`, Unit `"bars"`, Initial Stock `200`, Min Stock `30`, Unit Cost `850 ETB`, and Default Selling Price `980 ETB` and submits without any SKU or bin code,
- **Then** the material is saved with `currentStock = 200`, `unitCost = 850`, `defaultSellingPrice = 980`, and appears immediately in the catalog.

### AC-002: Multi-Item Sale Calculation & Stock Deduction (`FR-006`, `FR-009`, `FR-010`, `FR-012`)
- **Given** Material A (`"Cement 50kg"`, `currentStock = 100`, `unitCost = 1100 ETB`) and Material B (`"Rebar 12mm"`, `currentStock = 50`, `unitCost = 850 ETB`) exist in the catalog,
- **When** the user adds `10` bags of Material A at `1250 ETB` and `5` bars of Material B at `980 ETB` to the sale cart and confirms the sale,
- **Then** the system calculates Line A subtotal = `12,500.00 ETB`, Line B subtotal = `4,900.00 ETB`, Total Revenue = `17,400.00 ETB`, Total Profit = `2,150.00 ETB`, deducts Material A stock to `90` bags and Material B stock to `45` bars, and records the transaction in history.

### AC-003: Strict Sale Blocking When Quantity Exceeds Stock (`FR-011`, `BR-002`)
- **Given** a material `"Porcelain Floor Tile 60x60"` has `currentStock = 15` boxes,
- **When** the user attempts to add `16` boxes to the sale cart or submit a sale for `16` boxes,
- **Then** the system blocks the operation, displays a clear localized validation error indicating that requested quantity (`16`) exceeds available stock (`15`), and leaves `currentStock` unchanged at `15`.

### AC-004: Stock-In with Supplier Unit Purchase Cost (`FR-013`, `FR-015`, `BR-006`)
- **Given** `"Cement 50kg"` has `currentStock = 100` bags and `unitCost = 1,000.00 ETB`,
- **When** the user records a Stock-In of `100` bags at a Supplier Unit Purchase Cost of `1,200.00 ETB`,
- **Then** the system updates `currentStock` to `200` bags, updates `unitCost` to `1,100.00 ETB` (weighted average), records Total Restock Cost = `120,000.00 ETB`, and saves the `StockInRecord`.

### AC-005: Physical Ground-Stock Audit Reconciliation (`FR-016`–`FR-019`)
- **Given** `"Wall Paint White 20L"` shows expected `currentStock = 25` buckets in the app,
- **When** the user opens the Ground-Stock Audit workflow, enters a physical ground count of `23` buckets with note `"2 buckets damaged in yard"`, and commits the audit,
- **Then** the system displays a variance of `-2` buckets before commit, updates `"Wall Paint White 20L"` `currentStock` to `23` buckets upon commit, and logs a permanent `StockAuditRecord` with `expectedStock = 25`, `physicalCount = 23`, and `variance = -2`.

### AC-006: Trilingual Switching (`FR-022`, `FR-023`)
- **Given** the user is viewing any screen in the application,
- **When** the user selects `አማርኛ (Amharic)` or `Afaan Oromoo` from the header language switcher,
- **Then** all navigation labels, form fields, buttons, categories, units, and status messages immediately render in the selected language while preserving `ETB` currency formatting and active form state.

---

## 10. Database Information Requirements

The persistent data store shall maintain the following logical collections/tables:

### 10.1 `materials`
| Field | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Primary Key, non-empty | Unique material identifier |
| `name` | `string` | Required, `1..120` chars | Human-readable material name |
| `category` | `enum` | `'rebar' \| 'cement' \| 'tiles' \| 'paint' \| 'hardware' \| 'other'` | Material category |
| `specs` | `string` | Optional, `0..120` chars | Diameter, grade, dimensions, or finish |
| `unit` | `enum` | `'pcs' \| 'bars' \| 'bags' \| 'boxes' \| 'buckets' \| 'kg' \| 'm' \| 'liters'` | Single tracking unit |
| `currentStock` | `number` | Required, $\ge 0$ | Exact remaining stock in `unit` |
| `minStockLevel` | `number` | Required, $\ge 0$ | Low-stock warning threshold |
| `unitCost` | `number` | Required, $\ge 0$ | Current weighted-average supplier unit cost (`ETB`) |
| `defaultSellingPrice` | `number` | Required, $\ge 0$ | Default unit selling price (`ETB`) |
| `createdAt` | `string` | ISO-8601 | Creation timestamp |
| `updatedAt` | `string` | ISO-8601 | Last modification timestamp |

### 10.2 `sales`
| Field | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Primary Key | Unique sale transaction ID |
| `createdAt` | `string` | ISO-8601 | Sale timestamp |
| `customerNote` | `string` | Optional, `0..200` chars | Optional buyer name or reference |
| `items` | `SaleLineItem[]` | Non-empty array ($\ge 1$ item) | Line items sold (`materialId`, `materialName`, `unit`, `quantity > 0`, `unitSellingPrice >= 0`, `unitCostSnapshot >= 0`, `lineTotal`, `lineProfit`) |
| `totalRevenue` | `number` | Required, $\ge 0$ | Sum of `lineTotal` in `ETB` |
| `totalProfit` | `number` | Required, numeric | Sum of `lineProfit` in `ETB` |

### 10.3 `stockIns`
| Field | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Primary Key | Unique stock-in record ID |
| `materialId` | `string` | Foreign Key $\rightarrow$ `materials.id` | Target material |
| `materialName` | `string` | Required | Snapshot of material name |
| `unit` | `string` | Required | Snapshot of tracking unit |
| `quantityAdded` | `number` | Required, $> 0$ | Quantity received |
| `unitPurchaseCost` | `number` | Required, $\ge 0$ | Supplier unit purchase price (`ETB`) |
| `totalCost` | `number` | Required, $\ge 0$ | `quantityAdded × unitPurchaseCost` (`ETB`) |
| `previousStock` | `number` | Required, $\ge 0$ | Stock before restock |
| `newStock` | `number` | Required, $> 0$ | Stock after restock |
| `supplierNote` | `string` | Optional, `0..200` chars | Supplier name / invoice note |
| `createdAt` | `string` | ISO-8601 | Restock timestamp |

### 10.4 `audits`
| Field | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Primary Key | Unique ground-stock audit ID |
| `createdAt` | `string` | ISO-8601 | Audit timestamp |
| `note` | `string` | Optional, `0..250` chars | Audit reason or summary note |
| `adjustments` | `AuditLineItem[]` | Non-empty array ($\ge 1$ item) | Audited items (`materialId`, `materialName`, `unit`, `expectedStock`, `physicalCount >= 0`, `variance`, `unitCostSnapshot`) |

---

## 11. External Integrations

- **INT-001:** None required for MVP. The application is self-contained and does not depend on third-party payment gateways, external accounting APIs, or external AI services.

---

## 12. Validation Rules

All validation rules must be enforced on both the client UI and the backend server API:

- **VAL-001 (Material Name):** Must be a non-empty string after trimming whitespace (`1..120` characters).
- **VAL-002 (Valid Category & Unit):** `category` and `unit` must belong strictly to their allowed enumerations.
- **VAL-003 (Non-Negative Stock & Prices):** `initialStock`, `minStockLevel`, `unitCost`, `defaultSellingPrice`, `unitSellingPrice`, `unitPurchaseCost`, and `physicalCount` must be finite numbers $\ge 0$. `NaN` and `Infinity` are rejected.
- **VAL-004 (Strictly Positive Transaction Quantities):** `quantity` in a sale line item and `quantityAdded` in a Stock-In record must be finite numbers strictly $> 0$.
- **VAL-005 (Strict Stock Floor Check):** For every item in a sale request, `quantity <= material.currentStock`. If violated, the entire sale transaction is rejected with HTTP `400 Bad Request` and an explicit error payload.
- **VAL-006 (Non-Empty Sale Cart & Audit Batch):** A sale submission must contain at least 1 line item; an audit submission must contain at least 1 audited material entry.
- **VAL-007 (Existence Check):** Every referenced `materialId` in a Sale, Stock-In, or Audit request must correspond to an existing material in the catalog.

---

## 13. Failure Scenarios & Error Handling

- **FAIL-001 (Attempted Oversale):** User attempts to sell more units than `currentStock`.
  - *System Response:* UI disables checkout for invalid lines and highlights the exact available stock; backend API returns `400` without mutating any material stock.
- **FAIL-002 (Invalid Numeric Input):** User submits empty, negative, or non-numeric values for quantity or price.
  - *System Response:* Inline validation error is displayed in the active language (`en`/`am`/`om`); submission is prevented.
- **FAIL-003 (Network / Server Request Failure):** Client cannot reach the backend API during a transaction.
  - *System Response:* User receives a clear inline error banner with a retry option; cart/form inputs are preserved so the user does not have to re-enter data.
- **FAIL-004 (Atomic Multi-Item Sale Failure):** In a 4-item sale cart, 3 items have sufficient stock and 1 item exceeds available stock.
  - *System Response:* The entire transaction fails atomically; none of the 4 items have their stock deducted until the invalid line is fixed or removed.

---

## 14. Security Requirements

- **SEC-001 (Server-Side Validation Boundary):** Per `PROJECT_RULES.md` Section 5, frontend validation is never trusted as a security or data-integrity boundary. The Express backend must independently validate all payloads against `VAL-001` through `VAL-007`.
- **SEC-002 (Secret Protection):** No API keys, credentials, or sensitive environment variables shall be exposed in client bundles or API responses.
- **SEC-003 (Input Sanitization & Payload Limits):** Express JSON body parsing shall enforce safe payload size limits and sanitize strings by trimming and bounding lengths.
- **SEC-004 (Iframe Compatibility):** No `window.alert`, `window.confirm`, or `window.open` calls shall be used anywhere in the application.

---

## 15. MVP Exclusions

The following features are explicitly excluded from the MVP scope to preserve simplicity, speed, and compliance with `docs/PRODUCT_BRIEF.md`:
- **EX-001:** Alphanumeric SKU code generation or barcode/QR scanning hardware integration.
- **EX-002:** Multi-warehouse or bin/aisle/shelf location tracking.
- **EX-003:** Multi-unit conversion matrices per material (each material uses a single tracking unit).
- **EX-004:** Multi-user authentication, user management, or role-based access control (RBAC).
- **EX-005:** Customer credit / accounts receivable aging ledgers and tax-authority e-invoicing integrations.
