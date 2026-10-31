# Product Idea Brief & Approved Requirements Specification

## 1. Problem Being Solved
Construction and finishing material stores handle diverse material categories—including rebar (various diameters and grades), cement, tiles, paint, and hardware. Store owners and clerks face two inadequate alternatives:
1. **Paper ledgers or spreadsheets:** Prone to arithmetic mistakes, unrecorded stock deductions, delayed revenue visibility, and drift between ledger numbers and physical stock on the ground.
2. **Complex generic ERP/warehouse systems:** Enforce rigid alphanumeric SKU hierarchies, multi-bin warehouse locations, and multi-unit conversion matrices that slow down counter and yard transactions.

This project solves that gap by providing a **streamlined, SKU-free, mobile-first ERP and inventory management system** where every item is tracked using a single unit of measure, sales and restocks are calculated automatically in Ethiopian Birr (`ETB`), negative stock is strictly blocked, and a physical ground-stock audit workflow keeps app stock 100% synchronized with physical stock on the ground.

---

## 2. Target Users
- **Primary User (Single-User Mode):** Store Owner / Manager / Clerk operating a construction and finishing material store.
- **Usage Context:** Primarily accessed on a mobile device at the counter or in the material yard to register items, record multi-item customer sales, log incoming supplier deliveries with unit purchase costs, and perform physical ground-stock audits in **English**, **Amharic (አማርኛ)**, or **Afan Oromo (Afaan Oromoo)**.

---

## 3. User Needs & Pain Points
- **Zero-SKU Material Lookup:** Fast registration and filtering by human-readable material name, category (`Rebar`, `Cement`, `Tiles`, `Paint`, `Hardware`, `Other`), and specifications (e.g., rebar diameter and grade) without requiring SKU codes or warehouse bin locations.
- **Multi-Item Point-of-Sale with Dynamic Pricing:** Customers frequently buy multiple construction materials in a single purchase, and unit selling prices may vary per transaction. The user needs to add multiple items to a sale, enter the quantity sold and unit selling price (`ETB`), and see automatic line totals, overall receipt revenue, and remaining stock.
- **Supplier Cost & Profit Visibility:** Recording the supplier unit purchase cost during initial registration and `Stock-In` (restocking) is required to track restock expenditure, inventory value, and gross profit.
- **Strict Stock Floor Enforcement:** The system must strictly block any sale where the requested quantity exceeds the current remaining stock, preventing negative inventory balances.
- **100% Physical-Digital Stock Synchronization:** Physical breakage, loading miscounts, or unrecorded yard movements require a dedicated Ground-Stock Audit workflow that compares system stock against physical counts on the ground and reconciles variances with a full audit trail.

---

## 4. Proposed Solution & Main Value Proposition

> **"Zero-SKU, 100% Ground-Accurate Mobile ERP for Construction & Finishing Material Stores."**

A trilingual (`English` / `Amharic` / `Afan Oromo`), mobile-first application tailored to construction supply stores that:
1. Registers construction and finishing materials using a **single tracking unit per item**.
2. Processes **multi-item sales** in `ETB`, automatically calculating total revenue and profit while strictly blocking overselling.
3. Records **Stock-In (restocking)** transactions with **supplier unit purchase cost** (`ETB`).
4. Executes **Physical Ground-Stock Audits** to reconcile system stock with actual physical counts on the ground.

---

## 5. Confirmed Requirements (Locked Source of Truth)

| Requirement Area | Approved Specification |
| :--- | :--- |
| **Access Model** | **Single-User Operation:** Direct access without multi-user role/permission complexity. |
| **Material Tracking** | **Single Tracking Unit per Item:** No SKU codes or warehouse bin locations required. Supported units include `pcs`, `bars`, `bags`, `boxes`, `buckets`, `kg`, `m`, `liters`. |
| **Sales Workflow (POS)** | **Multi-Item Sale / Receipt:** Supports adding multiple materials to a single sale transaction, specifying `Quantity Sold` and `Unit Selling Price (ETB)` per item, auto-calculating line subtotals and receipt total revenue, and deducting sold quantities atomically. |
| **Stock-In Workflow** | **Quantity + Supplier Unit Purchase Cost:** Records incoming stock quantity and the supplier unit purchase cost (`ETB`), updating stock balance and unit cost history. |
| **Stock Floor Rule** | **Strict Sale Blocking:** Any sale line where `Quantity Sold > Current Remaining Stock` is strictly blocked. Negative stock is never permitted. |
| **Physical Stock Audit** | **Ground-Stock Reconciliation:** Compares expected system stock with actual physical ground count, computes variance (`Physical Count - System Stock`), updates stock to match the physical count, and logs an immutable audit record. |
| **Currency & Languages** | **Currency:** Ethiopian Birr (`ETB` / `ብር`).<br>**Languages:** English (`en`), Amharic / አማርኛ (`am`), and Afan Oromo / Afaan Oromoo (`om`). |

---

## 6. Core Domain Data Model

### 6.1 `Material`
- `id`: string
- `name`: string (e.g., `"Deformed Rebar 12mm"`, `"Dangote Cement 50kg"`)
- `category`: `'rebar' | 'cement' | 'tiles' | 'paint' | 'hardware' | 'other'`
- `specs`: string (optional attributes, e.g., `"Ø12mm • Grade 60"`, `"60x60cm Porcelain"`)
- `unit`: `'pcs' | 'bars' | 'bags' | 'boxes' | 'buckets' | 'kg' | 'm' | 'liters'`
- `currentStock`: number ($\ge 0$)
- `minStockLevel`: number ($\ge 0$, low-stock alert threshold)
- `unitCost`: number ($\ge 0$, supplier unit purchase cost in `ETB`)
- `defaultSellingPrice`: number ($\ge 0$, default unit selling price in `ETB`)
- `updatedAt`: ISO 8601 timestamp

### 6.2 `SaleTransaction` (Multi-Item)
- `id`: string
- `createdAt`: ISO 8601 timestamp
- `customerNote`: string (optional buyer name or reference note)
- `items`: Array of `SaleLineItem`:
  - `materialId`: string
  - `materialName`: string
  - `unit`: string
  - `quantity`: number ($> 0$ and $\le \text{currentStock}$)
  - `unitSellingPrice`: number ($\ge 0$, in `ETB`)
  - `unitCostSnapshot`: number ($\ge 0$, in `ETB` at time of sale)
  - `lineTotal`: number (`quantity × unitSellingPrice`)
  - `lineProfit`: number (`quantity × (unitSellingPrice - unitCostSnapshot)`)
- `totalRevenue`: number (sum of `lineTotal` in `ETB`)
- `totalProfit`: number (sum of `lineProfit` in `ETB`)

### 6.3 `StockInRecord` (Restocking)
- `id`: string
- `materialId`: string
- `materialName`: string
- `unit`: string
- `quantityAdded`: number ($> 0$)
- `unitPurchaseCost`: number ($\ge 0$, in `ETB`)
- `totalCost`: number (`quantityAdded × unitPurchaseCost`)
- `previousStock`: number
- `newStock`: number
- `supplierNote`: string (optional supplier name or delivery note)
- `createdAt`: ISO 8601 timestamp

### 6.4 `StockAuditRecord` (Physical Ground-Stock Reconciliation)
- `id`: string
- `createdAt`: ISO 8601 timestamp
- `note`: string (optional audit reason/note)
- `adjustments`: Array of `AuditLineItem`:
  - `materialId`: string
  - `materialName`: string
  - `unit`: string
  - `expectedStock`: number (app stock prior to audit)
  - `physicalCount`: number ($\ge 0$, actual counted stock on the ground)
  - `variance`: number (`physicalCount - expectedStock`)
  - `unitCostSnapshot`: number (`ETB` cost snapshot for variance valuation)

---

## 7. Risks & Mitigations
1. **Unlogged Deliveries Before Sales:** Because sales are strictly blocked when `Quantity Sold > Current Remaining Stock`, staff must log incoming deliveries (`Stock-In`) before selling newly arrived stock.
   - *Mitigation:* Make the `Stock-In` workflow accessible in 2 taps so clerks can immediately register incoming stock if a sale is blocked due to unlogged arrival.
2. **Audit Abuse / Unexplained Shrinkage:** Adjusting stock directly without records could hide missing materials.
   - *Mitigation:* Every ground-stock audit generates a permanent `StockAuditRecord` showing expected stock, physical count, exact variance delta, timestamp, and reason note.
3. **Floating-Point Rounding in Currency & Quantities:** Decimal quantities or prices in JavaScript can cause precision artifacts.
   - *Mitigation:* Centralize all currency (`ETB`) and quantity arithmetic in a unit-tested domain engine with deterministic rounding to 2 decimal places.

---

## 8. MVP Scope & Success Metrics

### In-Scope for MVP
- Trilingual UI (`English`, `Amharic`, `Afan Oromo`) with `ETB` currency formatting.
- SKU-free Material Registration & Catalog filtering (`Rebar`, `Cement`, `Tiles`, `Paint`, `Hardware`, `Other`).
- Multi-item Point-of-Sale (POS) cart with editable unit selling price, live revenue/remaining-stock preview, and strict stock-floor blocking.
- Stock-In (restocking) workflow capturing quantity added and supplier unit purchase cost (`ETB`).
- Physical Ground-Stock Audit workflow with live variance calculation and 100% stock synchronization.
- Dashboard KPIs (Total Revenue, Gross Profit, Inventory Cost Value, Low-Stock Alerts) and full Transaction/Audit History ledger.

### Out-of-Scope for MVP
- Multi-user authentication / RBAC.
- Barcode generation, SKU matrices, or multi-bin warehouse location tracking.
- Multi-unit conversion tables per item.

### Success Metrics
- **Speed:** Recording a multi-item sale or stock-in takes **< 15 seconds** on a mobile viewport.
- **Accuracy:** **100% arithmetic accuracy** across line subtotals, receipt totals, supplier cost updates, and stock deductions.
- **Stock Integrity:** **Zero negative-stock occurrences** (100% enforcement of sale blocking when requested quantity exceeds stock) and **100% synchronization** between app stock and physical ground stock after audit reconciliation.

---

## 9. Approved Phased Implementation Roadmap
- **Phase 1:** Trilingual Localization (`en` / `am` / `om`), TypeScript Domain Types (`src/types/erp.ts`), and Core Inventory Domain Engine (`src/domain/inventoryEngine.ts`) with Automated Unit Tests (`src/domain/inventoryEngine.test.ts`).
- **Phase 2:** Backend API & Persistent Storage (`server.ts`) with server-side validation.
- **Phase 3:** Mobile App Shell, Trilingual Switcher, Dashboard View, and SKU-Free Material Catalog UI.
- **Phase 4:** Multi-Item Point-of-Sale (POS) Cart & Stock-In (Restocking with Supplier Cost) UI.
- **Phase 5:** Physical Ground-Stock Audit Workflow & Full Transaction History Ledger.
