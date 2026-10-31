import dotenv from 'dotenv';
import express, { NextFunction, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import {
  calculateStoreSummary,
  createInitialErpState,
  recordMultiItemSale,
  recordStockAudit,
  recordStockIn,
  registerMaterial,
  updateMaterialMetadata,
} from './src/domain/inventoryEngine';
import {
  CreateAuditInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateStockInInput,
  ErpState,
  UpdateMaterialInput,
} from './src/types/erp';
import { AppDomainError } from './src/utils/errors';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = Number(process.env.PORT) || 3000;
const DATA_FILE_PATH = path.resolve(
  __dirname,
  process.env.DATA_FILE_PATH || './data/erp-store.json'
);

/**
 * Loads or initializes the persistent ERP state on disk per docs/ARCHITECTURE.md Section 10.
 */
function loadOrInitializeStore(): ErpState {
  try {
    if (fs.existsSync(DATA_FILE_PATH)) {
      const raw = fs.readFileSync(DATA_FILE_PATH, 'utf-8');
      const parsed = JSON.parse(raw) as ErpState;
      if (parsed && Array.isArray(parsed.materials)) {
        parsed.summary = calculateStoreSummary(
          parsed.materials,
          parsed.sales ?? []
        );
        return parsed;
      }
    }
  } catch (err) {
    console.warn('Initializing fresh ERP store file:', err);
  }

  const initialState = createInitialErpState();
  saveStoreAtomically(initialState);
  return initialState;
}

/**
 * Writes the ERP state atomically via a temporary file rename so partial writes never corrupt state.
 */
export function saveStoreAtomically(state: ErpState): void {
  const dir = path.dirname(DATA_FILE_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const tempPath = `${DATA_FILE_PATH}.tmp`;
  fs.writeFileSync(tempPath, JSON.stringify(state, null, 2), 'utf-8');
  fs.renameSync(tempPath, DATA_FILE_PATH);
}

async function startServer() {
  const app = express();
  let storeState: ErpState = loadOrInitializeStore();

  // Enforce 100kb payload limit per SEC-003
  app.use(express.json({ limit: '100kb' }));

  // ============================================================================
  // Approved API Contract Routes (docs/API_CONTRACT.md)
  // ============================================================================

  // 1. GET /api/state (FR-005, FR-020, FR-021)
  app.get('/api/state', (_req: Request, res: Response) => {
    storeState.summary = calculateStoreSummary(
      storeState.materials,
      storeState.sales
    );
    res.status(200).json(storeState);
  });

  // 2. POST /api/materials (FR-001, FR-002, BR-005)
  app.post(
    '/api/materials',
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateMaterialInput;
        const material = registerMaterial(storeState, body);
        saveStoreAtomically(storeState);
        res.status(201).json({
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 3. PATCH /api/materials/:id (FR-003, FR-004, BR-001)
  app.patch(
    '/api/materials/:id',
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const materialId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as UpdateMaterialInput;
        const material = updateMaterialMetadata(storeState, materialId, body);
        saveStoreAtomically(storeState);
        res.status(200).json({
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 4. POST /api/sales (FR-006..FR-012, BR-002, BR-003, FAIL-004)
  app.post('/api/sales', (req: Request, res: Response, next: NextFunction) => {
    try {
      const body = (req.body ?? {}) as CreateSaleInput;
      const sale = recordMultiItemSale(storeState, body);
      saveStoreAtomically(storeState);
      res.status(201).json({
        sale,
        materials: storeState.materials,
        summary: storeState.summary,
      });
    } catch (err) {
      next(err);
    }
  });

  // 5. POST /api/stock-in (FR-013..FR-015, BR-004, BR-006, BR-007)
  app.post(
    '/api/stock-in',
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateStockInInput;
        const { stockIn, material } = recordStockIn(storeState, body);
        saveStoreAtomically(storeState);
        res.status(201).json({
          stockIn,
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 6. POST /api/audits (FR-016..FR-019, BR-004, BR-008, VAL-003, VAL-006, VAL-007)
  app.post(
    '/api/audits',
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateAuditInput;
        const audit = recordStockAudit(storeState, body);
        saveStoreAtomically(storeState);
        res.status(201).json({
          audit,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // Centralized Domain & API Error Boundary (SEC-001, docs/API_CONTRACT.md Section 3.2)
  app.use(
    (err: unknown, _req: Request, res: Response, _next: NextFunction) => {
      if (err instanceof AppDomainError) {
        res.status(err.statusHttp).json(err.toEnvelope());
        return;
      }
      const fallback = new AppDomainError(
        'INTERNAL_ERROR',
        err instanceof Error ? err.message : 'Unexpected server error'
      );
      res.status(500).json(fallback.toEnvelope());
    }
  );

  // Mount Vite dev middleware in development or static dist in production
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.resolve(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req: Request, res: Response) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(
      `Construction & Finishing ERP Server listening on http://0.0.0.0:${PORT}`
    );
  });
}

startServer();
