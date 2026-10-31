# API Contract Specification (`API_CONTRACT.md`)

**Project:** Construction & Finishing Material Store Mobile ERP & Inventory Management System  
**Document Version:** 1.0  
**Source of Truth References:** `docs/PRODUCT_BRIEF.md`, `docs/SRS.md`, `docs/ARCHITECTURE.md`, `docs/DATABASE_DESIGN.md`

---

## 1. API Design Principles

1. **Zero Unrequested Endpoints:** Every endpoint in this contract maps strictly to an approved functional requirement in `docs/SRS.md` (`FR-001` through `FR-021`).
2. **Base Path & Format:** All endpoints use the `/api` prefix and exchange UTF-8 `application/json` payloads.
3. **Monetary & Quantity Precision (`NFR-003`):** All currency fields are denominated in **Ethiopian Birr (`ETB`)** and rounded to 2 decimal places (`0.01`).
4. **Server-Side Security Boundary (`SEC-001`):** The server enforces all validation rules (`VAL-001` through `VAL-007`) and business rules (`BR-001` through `BR-008`) independently of client validation.

---

## 2. Endpoint Summary Matrix

| Method | Path | SRS Requirement | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/state` | `FR-005`, `FR-020`, `FR-021` | Retrieve complete store state (materials, sales, stock-ins, audits, and summary KPIs). |
| `POST` | `/api/materials` | `FR-001`, `FR-002`, `BR-005` | Register a new SKU-free construction/finishing material. |
| `PATCH` | `/api/materials/:id` | `FR-003`, `FR-004`, `BR-001` | Edit material metadata (`name`, `category`, `specs`, `minStockLevel`, `defaultSellingPrice`). |
| `POST` | `/api/sales` | `FR-006`–`FR-012`, `BR-002`, `BR-003` | Record an atomic multi-item sale and deduct stock (strictly blocks if `quantity > currentStock`). |
| `POST` | `/api/stock-in` | `FR-013`–`FR-015`, `BR-006` | Record incoming supplier stock and supplier unit purchase cost (`ETB`). |
| `POST` | `/api/audits` | `FR-016`–`FR-019`, `BR-008` | Commit a physical ground-stock audit and synchronize `currentStock` to `physicalCount`. |

---

## 3. Shared Enumerations & Error Envelope

### 3.1 Allowed Enumerations (`VAL-002`)
- **`MaterialCategory`:** `'rebar' | 'cement' | 'tiles' | 'paint' | 'hardware' | 'other'`
- **`MaterialUnit`:** `'pcs' | 'bars' | 'bags' | 'boxes' | 'buckets' | 'kg' | 'm' | 'liters'`

### 3.2 Standard Error Response Envelope (`400`, `404`, `500`)
```json
{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Requested quantity (16) for Porcelain Floor Tile 60x60 exceeds available stock (15).",
    "details": {
      "materialId": "mat_03",
      "materialName": "Porcelain Floor Tile 60x60",
      "requested": 16,
      "available": 15,
      "unit": "boxes"
    }
  }
}
```

#### Standardized Error Codes
| Error Code | HTTP Status | Trigger Condition |
| :--- | :--- | :--- |
| `VALIDATION_ERROR` | `400 Bad Request` | Missing required fields, empty material name (`VAL-001`), invalid enum (`VAL-002`), negative number (`VAL-003`), or non-positive quantity (`VAL-004`). |
| `INSUFFICIENT_STOCK` | `400 Bad Request` | Any sale item (or aggregated duplicate item) requests `quantity > material.currentStock` (`VAL-005`, `BR-002`, `BR-003`). |
| `IMMUTABLE_FIELD_VIOLATION` | `400 Bad Request` | Attempt to mutate `currentStock` via `PATCH /api/materials/:id` (`FR-004`, `BR-004`) or change `unit` after transactions exist (`BR-001`). |
| `MATERIAL_NOT_FOUND` | `404 Not Found` | Referenced `materialId` does not exist (`VAL-007`). |
| `INTERNAL_ERROR` | `500 Internal Server Error` | Unexpected server or storage failure. |

---

## 4. Detailed Endpoint Specifications

### 4.1 `GET /api/state`
Returns the complete synchronized ERP state and derived dashboard metrics.

- **Success Response (`200 OK`):**
```json
{
  "materials": [
    {
      "id": "mat_1",
      "name": "Deformed Rebar 12mm",
      "category": "rebar",
      "specs": "Ø12mm • Grade 60 • 12m length",
      "unit": "bars",
      "currentStock": 200,
      "minStockLevel": 30,
      "unitCost": 850.00,
      "defaultSellingPrice": 980.00,
      "createdAt": "2026-10-30T08:00:00.000Z",
      "updatedAt": "2026-10-30T08:00:00.000Z"
    }
  ],
  "sales": [],
  "stockIns": [],
  "audits": [],
  "summary": {
    "totalRevenue": 0.00,
    "totalProfit": 0.00,
    "inventoryCostValue": 170000.00,
    "inventoryRetailValue": 196000.00,
    "lowStockCount": 0
  }
}
```

---

### 4.2 `POST /api/materials`
Registers a new construction or finishing material without SKU or bin location fields (`FR-001`, `FR-002`).

- **Request Body:**
```json
{
  "name": "Dangote Portland Cement 50kg",
  "category": "cement",
  "specs": "OPC 42.5R • 50kg bag",
  "unit": "bags",
  "initialStock": 150,
  "minStockLevel": 25,
  "unitCost": 1100.00,
  "defaultSellingPrice": 1250.00
}
```
- **Validation Rules:**
  - `name`: non-empty string after trim, `1..120` chars (`VAL-001`).
  - `category`: valid `MaterialCategory` (`VAL-002`).
  - `specs`: optional string, `0..120` chars.
  - `unit`: valid `MaterialUnit` (`VAL-002`).
  - `initialStock`, `minStockLevel`, `unitCost`, `defaultSellingPrice`: finite numbers $\ge 0$ (`VAL-003`).
- **Success Response (`201 Created`):**
  Returns the newly created `Material` object and updated `summary`.

---

### 4.3 `PATCH /api/materials/:id`
Updates mutable metadata of an existing material (`FR-003`, `FR-004`, `BR-001`).

- **Request Body (Partial Update):**
```json
{
  "name": "Dangote Portland Cement 50kg",
  "category": "cement",
  "specs": "OPC 42.5R • 50kg bag",
  "minStockLevel": 30,
  "defaultSellingPrice": 1280.00
}
```
- **Validation Rules:**
  - Passing `currentStock` in the payload is rejected with `400 IMMUTABLE_FIELD_VIOLATION` (`FR-004`, `BR-004`).
  - Attempting to change `unit` when the material already has recorded sales, stock-ins, or audits is rejected with `400 IMMUTABLE_FIELD_VIOLATION` (`BR-001`).
- **Success Response (`200 OK`):**
  Returns the updated `Material` object and updated `summary`.

---

### 4.4 `POST /api/sales`
Executes an atomic multi-item sale, calculates line and total revenue/profit in `ETB`, and deducts sold quantities from inventory (`FR-006`–`FR-012`).

- **Request Body:**
```json
{
  "customerNote": "Site delivery - Bole project",
  "items": [
    {
      "materialId": "mat_1",
      "quantity": 20,
      "unitSellingPrice": 980.00
    },
    {
      "materialId": "mat_2",
      "quantity": 10,
      "unitSellingPrice": 1250.00
    }
  ]
}
```
- **Validation & Business Rules:**
  - `items`: non-empty array (`VAL-006`).
  - Duplicate `materialId` entries in `items` are aggregated prior to checking available stock (`BR-003`).
  - Each item must have `quantity > 0` (`VAL-004`) and `unitSellingPrice >= 0` (`VAL-003`).
  - **Strict Stock Floor (`VAL-005`, `BR-002`):** For every item, `quantity <= material.currentStock`. If any item exceeds `currentStock`, the entire sale is rejected with `400 INSUFFICIENT_STOCK` and zero stock is deducted (`FAIL-004`).
- **Success Response (`201 Created`):**
```json
{
  "sale": {
    "id": "sale_1",
    "createdAt": "2026-10-31T10:00:00.000Z",
    "customerNote": "Site delivery - Bole project",
    "items": [
      {
        "materialId": "mat_1",
        "materialName": "Deformed Rebar 12mm",
        "unit": "bars",
        "quantity": 20,
        "unitSellingPrice": 980.00,
        "unitCostSnapshot": 850.00,
        "lineTotal": 19600.00,
        "lineProfit": 2600.00
      },
      {
        "materialId": "mat_2",
        "materialName": "Dangote Portland Cement 50kg",
        "unit": "bags",
        "quantity": 10,
        "unitSellingPrice": 1250.00,
        "unitCostSnapshot": 1100.00,
        "lineTotal": 12500.00,
        "lineProfit": 1500.00
      }
    ],
    "totalRevenue": 32100.00,
    "totalProfit": 4100.00
  },
  "materials": [ /* Updated materials list with deducted currentStock */ ],
  "summary": { /* Updated KPI summary */ }
}
```

---

### 4.5 `POST /api/stock-in`
Records an incoming supplier restock delivery with `quantityAdded` and `unitPurchaseCost` in `ETB`, incrementing `currentStock` and updating weighted-average `unitCost` (`FR-013`–`FR-015`, `BR-006`).

- **Request Body:**
```json
{
  "materialId": "mat_2",
  "quantityAdded": 100,
  "unitPurchaseCost": 1150.00,
  "supplierNote": "Factory truck delivery #402"
}
```
- **Validation Rules:**
  - `materialId` must exist (`VAL-007`).
  - `quantityAdded` must be a finite number $> 0$ (`VAL-004`).
  - `unitPurchaseCost` must be a finite number $\ge 0$ (`VAL-003`).
- **Success Response (`201 Created`):**
```json
{
  "stockIn": {
    "id": "stkin_1",
    "materialId": "mat_2",
    "materialName": "Dangote Portland Cement 50kg",
    "unit": "bags",
    "quantityAdded": 100,
    "unitPurchaseCost": 1150.00,
    "totalCost": 115000.00,
    "previousStock": 140,
    "newStock": 240,
    "supplierNote": "Factory truck delivery #402",
    "createdAt": "2026-10-31T10:05:00.000Z"
  },
  "material": { /* Updated Material with new currentStock and weighted-avg unitCost */ },
  "summary": { /* Updated KPI summary */ }
}
```

---

### 4.6 `POST /api/audits`
Commits a Physical Ground-Stock Audit reconciliation, updating each audited material's `currentStock` to match the counted `physicalCount` on the ground and recording the exact variance (`FR-016`–`FR-019`, `BR-008`).

- **Request Body:**
```json
{
  "note": "Weekly Saturday yard count - 2 cement bags damaged by moisture",
  "items": [
    {
      "materialId": "mat_2",
      "physicalCount": 238
    }
  ]
}
```
- **Validation Rules:**
  - `items`: non-empty array of audited items (`VAL-006`).
  - Every `materialId` must exist (`VAL-007`).
  - Every `physicalCount` must be a finite number $\ge 0$ (`VAL-003`).
- **Success Response (`201 Created`):**
```json
{
  "audit": {
    "id": "audit_1",
    "createdAt": "2026-10-31T10:10:00.000Z",
    "note": "Weekly Saturday yard count - 2 cement bags damaged by moisture",
    "adjustments": [
      {
        "materialId": "mat_2",
        "materialName": "Dangote Portland Cement 50kg",
        "unit": "bags",
        "expectedStock": 240,
        "physicalCount": 238,
        "variance": -2,
        "unitCostSnapshot": 1120.83
      }
    ]
  },
  "materials": [ /* Updated materials list with synchronized currentStock */ ],
  "summary": { /* Updated KPI summary */ }
}
```
