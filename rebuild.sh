#!/bin/bash
set -e

echo "🚀 Reconstrucción completa v3 - Recinto Ferial Cruceño"
echo "📁 Directorio actual: $(pwd)"

# ---------------------------------------------------------
# DETECCIÓN Y CORRECCIÓN DE CARPETA DUPLICADA
# ---------------------------------------------------------
# Si estamos dentro de una subcarpeta con el mismo nombre, subimos a la raíz
if [ "$(basename "$PWD")" = "261016-CalendarioRecintoFerial" ] && [ -d "../.git" ]; then
  echo "️  Detectada carpeta duplicada. Subiendo a la raíz del repositorio..."
  cd ..
fi

# Verificar que estamos en la raíz del repo
if [ ! -d ".git" ]; then
  echo "❌ Error: No se encontró .git en el directorio actual."
  echo "   Ejecuta este script desde la raíz del repositorio o desde la carpeta duplicada."
  exit 1
fi

echo "📁 Raíz del repositorio: $(pwd)"

# ---------------------------------------------------------
# LIMPIEZA TOTAL (excepto .git)
# ---------------------------------------------------------
echo "🧹 Limpiando contenido existente..."
find . -mindepth 1 -not -path './.git' -not -path './.git/*' -delete 2>/dev/null || true
rm -rf node_modules 2>/dev/null || true

# ---------------------------------------------------------
# REINICIALIZAR GIT
# ---------------------------------------------------------
git add -A
git commit --allow-empty -m "chore: limpieza completa antes de reconstrucción v3"

# ---------------------------------------------------------
# CREAR ESTRUCTURA DE DIRECTORIOS
# ---------------------------------------------------------
mkdir -p .github/workflows
mkdir -p src/lib/__tests__
mkdir -p src/components
mkdir -p src/views
mkdir -p src/data
mkdir -p src/state

# ---------------------------------------------------------
# 1. PACKAGE.JSON
# ---------------------------------------------------------
cat << 'EOF' > package.json
{
  "name": "261016-calendario-recinto-ferial",
  "private": true,
  "version": "3.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "lint": "eslint src --ext ts,tsx"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "html2canvas": "^1.4.1",
    "jspdf": "^2.5.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.3.6",
    "typescript": "^5.2.2",
    "vite": "^5.0.8",
    "vitest": "^1.1.0",
    "jsdom": "^23.0.1"
  }
}
EOF

# ---------------------------------------------------------
# 2. CONFIGURACIÓN VITE / TS / TAILWIND
# ---------------------------------------------------------
cat << 'EOF' > vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/261016-CalendarioRecintoFerial/',
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
  },
});
EOF

cat << 'EOF' > tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

cat << 'EOF' > tsconfig.node.json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

cat << 'EOF' > tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        expocad: {
          primary: '#3F6B4A',
          medium: '#2F6B3A',
          dark: '#1D2E20',
          accent: '#E8842C',
          bg: '#F4F6F4',
          surface: '#FFFFFF',
          line: '#E5E9E6',
          muted: '#6B7A6F',
          month1: '#DCE6F1',
          month2: '#F2F2F2',
        }
      },
      fontFamily: {
        title: ['"Roboto Condensed"', 'sans-serif'],
        body: ['"Inter"', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px rgba(29, 46, 32, 0.06), 0 4px 12px rgba(29, 46, 32, 0.04)',
      }
    },
  },
  plugins: [],
}
EOF

cat << 'EOF' > postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat << 'EOF' > index.html
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Recinto Ferial Cruceño · Tablero de Operaciones</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Roboto+Condensed:wght@500;600;700&display=swap" rel="stylesheet">
  </head>
  <body class="bg-expocad-bg text-expocad-dark font-body antialiased">
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat << 'EOF' > .gitignore
node_modules
dist
.DS_Store
*.log
EOF

# ---------------------------------------------------------
# 3. WORKFLOW GITHUB ACTIONS
# ---------------------------------------------------------
cat << 'EOF' > .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
EOF

# ---------------------------------------------------------
# 4. LÓGICA DE FECHAS (COMPLETA)
# ---------------------------------------------------------
cat << 'EOF' > src/lib/dates.ts
export const LIMPIEZA_DIAS = 1;

export const isLeapYear = (year: number): boolean =>
  (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;

export const getDaysInYear = (year: number): number => (isLeapYear(year) ? 366 : 365);

export const addDays = (dateStr: string, days: number): string => {
  const date = new Date(dateStr + 'T12:00:00Z');
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().split('T')[0];
};

export const diffDays = (from: string, to: string): number => {
  const a = new Date(from + 'T12:00:00Z');
  const b = new Date(to + 'T12:00:00Z');
  return Math.round((b.getTime() - a.getTime()) / (1000 * 60 * 60 * 24));
};

export const formatDate = (dateStr: string): string => {
  const [y, m, d] = dateStr.split('-');
  return `${d}/${m}/${y}`;
};

export const getDayOfWeek = (dateStr: string): number => {
  const date = new Date(dateStr + 'T12:00:00Z');
  return date.getUTCDay();
};

export const getMonthIndex = (dateStr: string): number =>
  new Date(dateStr + 'T12:00:00Z').getUTCMonth();

export const MONTH_NAMES = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

export const generateYearGrid = (year: number): (string | null)[][] => {
  const weeks: (string | null)[][] = [];
  const firstDay = `${year}-01-01`;
  const dow = getDayOfWeek(firstDay);
  const padding = dow === 0 ? 6 : dow - 1;

  let currentWeek: (string | null)[] = Array(padding).fill(null);
  const current = new Date(`${year}-01-01T12:00:00Z`);
  const daysInYear = getDaysInYear(year);

  for (let i = 0; i < daysInYear; i++) {
    currentWeek.push(current.toISOString().split('T')[0]);
    if (currentWeek.length === 7) {
      weeks.push(currentWeek);
      currentWeek = [];
    }
    current.setUTCDate(current.getUTCDate() + 1);
  }
  if (currentWeek.length > 0) {
    while (currentWeek.length < 7) currentWeek.push(null);
    weeks.push(currentWeek);
  }
  return weeks;
};

export const generateSpanGrid = (startDate: string, totalDays: number): (string | null)[][] => {
  const weeks: (string | null)[][] = [];
  let currentWeek: (string | null)[] = [];
  const current = new Date(startDate + 'T12:00:00Z');

  for (let i = 0; i < totalDays; i++) {
    currentWeek.push(current.toISOString().split('T')[0]);
    if (currentWeek.length === 7) {
      weeks.push(currentWeek);
      currentWeek = [];
    }
    current.setUTCDate(current.getUTCDate() + 1);
  }
  if (currentWeek.length > 0) {
    while (currentWeek.length < 7) currentWeek.push(null);
    weeks.push(currentWeek);
  }
  return weeks;
};
EOF

# ---------------------------------------------------------
# 5. VALIDACIÓN CON COMBINACIONES CONECTADAS
# ---------------------------------------------------------
cat << 'EOF' > src/lib/validation.ts
import { addDays, diffDays, LIMPIEZA_DIAS, getDaysInYear } from './dates';

export interface Fair {
  id: string;
  nombre: string;
  sector: string;
  color: string;
  fechaInicioMontaje: string;
  diasMontaje: number;
  diasFeria: number;
  diasDesmontaje: number;
  pabellonIds: string[];
}

export interface Pavilion {
  id: string;
  nombre: string;
  m2: number;
  tipo: 'cerrado' | 'semicubierto' | 'aire libre' | 'playón' | 'salón';
  vecinos: string[];
  tieneParedExterior: boolean;
}

export interface FairPhases {
  inicioMontaje: string;
  finMontaje: string;
  inicioFeria: string;
  finFeria: string;
  inicioDesmontaje: string;
  finDesmontaje: string;
  inicioLimpieza: string;
  finLimpieza: string;
  finOcupacion: string;
  totalDiasOcupados: number;
}

export const getFairPhases = (fair: Pick<Fair, 'fechaInicioMontaje' | 'diasMontaje' | 'diasFeria' | 'diasDesmontaje'>): FairPhases => {
  const inicioMontaje = fair.fechaInicioMontaje;
  const finMontaje = addDays(inicioMontaje, fair.diasMontaje - 1);
  const inicioFeria = addDays(finMontaje, 1);
  const finFeria = addDays(inicioFeria, fair.diasFeria - 1);
  const inicioDesmontaje = addDays(finFeria, 1);
  const finDesmontaje = addDays(inicioDesmontaje, fair.diasDesmontaje - 1);
  const inicioLimpieza = addDays(finDesmontaje, 1);
  const finLimpieza = addDays(inicioLimpieza, LIMPIEZA_DIAS - 1);
  return {
    inicioMontaje, finMontaje,
    inicioFeria, finFeria,
    inicioDesmontaje, finDesmontaje,
    inicioLimpieza, finLimpieza,
    finOcupacion: finLimpieza,
    totalDiasOcupados: diffDays(inicioMontaje, finLimpieza) + 1
  };
};

export const getPhaseForDay = (fair: Fair, dateStr: string): 'montaje' | 'feria' | 'desmontaje' | 'limpieza' | null => {
  const p = getFairPhases(fair);
  if (dateStr >= p.inicioMontaje && dateStr <= p.finMontaje) return 'montaje';
  if (dateStr >= p.inicioFeria && dateStr <= p.finFeria) return 'feria';
  if (dateStr >= p.inicioDesmontaje && dateStr <= p.finDesmontaje) return 'desmontaje';
  if (dateStr >= p.inicioLimpieza && dateStr <= p.finLimpieza) return 'limpieza';
  return null;
};

export interface ConflictInfo {
  fairNombre: string;
  pabellonNombre: string;
  fechasPisadas: string[];
  primeraFechaDisponible: string;
}

export const checkConflicts = (fair: Fair, allFairs: Fair[], pavilions: Pavilion[], excludeId?: string) => {
  const phases = getFairPhases(fair);
  const conflicts: ConflictInfo[] = [];

  for (const other of allFairs) {
    if (excludeId && other.id === excludeId) continue;
    const otherPhases = getFairPhases(other);
    const shared = fair.pabellonIds.filter(p => other.pabellonIds.includes(p));
    if (shared.length === 0) continue;

    if (phases.inicioMontaje <= otherPhases.finOcupacion && phases.finOcupacion >= otherPhases.inicioMontaje) {
      const overlap: string[] = [];
      const start = phases.inicioMontaje > otherPhases.inicioMontaje ? phases.inicioMontaje : otherPhases.inicioMontaje;
      const end = phases.finOcupacion < otherPhases.finOcupacion ? phases.finOcupacion : otherPhases.finOcupacion;
      let cur = start;
      while (cur <= end) {
        overlap.push(cur);
        cur = addDays(cur, 1);
      }
      conflicts.push({
        fairNombre: other.nombre,
        pabellonNombre: pavilions.find(p => p.id === shared[0])?.nombre || shared[0],
        fechasPisadas: overlap.slice(0, 5),
        primeraFechaDisponible: addDays(otherPhases.finOcupacion, 1)
      });
    }
  }
  return { hasConflict: conflicts.length > 0, conflicts };
};

export interface PavilionCombination {
  pavilionIds: string[];
  totalM2: number;
  breakdown: { tipo: string; count: number; m2: number }[];
}

export interface WindowOption {
  start: string;
  end: string;
  duration: number;
  combinations: PavilionCombination[];
  totalM2: number;
  m2ByType: { tipo: string; m2: number }[];
}

const isValidConnectedGroup = (pavilionIds: string[], allPavilions: Pavilion[]): boolean => {
  if (pavilionIds.length <= 1) return true;
  const pavMap = new Map(allPavilions.map(p => [p.id, p]));
  const visited = new Set<string>();
  const queue = [pavilionIds[0]];
  visited.add(pavilionIds[0]);
  
  while (queue.length > 0) {
    const current = queue.shift()!;
    const pav = pavMap.get(current);
    if (!pav) continue;
    for (const neighbor of pav.vecinos) {
      if (pavilionIds.includes(neighbor) && !visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push(neighbor);
      }
    }
  }
  return visited.size === pavilionIds.length;
};

const calculateBreakdown = (pavilionIds: string[], allPavilions: Pavilion[]) => {
  const pavMap = new Map(allPavilions.map(p => [p.id, p]));
  const byType: Record<string, { count: number; m2: number }> = {};
  for (const id of pavilionIds) {
    const pav = pavMap.get(id);
    if (!pav) continue;
    if (!byType[pav.tipo]) byType[pav.tipo] = { count: 0, m2: 0 };
    byType[pav.tipo].count++;
    byType[pav.tipo].m2 += pav.m2;
  }
  return Object.entries(byType).map(([tipo, data]) => ({
    tipo, count: data.count, m2: data.m2
  }));
};

const findValidCombinations = (
  freePavilionIds: string[],
  allPavilions: Pavilion[],
  requiredM2: number
): PavilionCombination[] => {
  const freePavilions = allPavilions.filter(p => freePavilionIds.includes(p.id));
  const combinations: PavilionCombination[] = [];
  
  const generateCombinations = (
    current: string[],
    remaining: Pavilion[],
    currentM2: number
  ) => {
    if (currentM2 >= requiredM2) {
      if (isValidConnectedGroup(current, allPavilions)) {
        const breakdown = calculateBreakdown(current, allPavilions);
        combinations.push({
          pavilionIds: [...current],
          totalM2: currentM2,
          breakdown
        });
      }
      return;
    }
    for (let i = 0; i < remaining.length; i++) {
      const pav = remaining[i];
      generateCombinations(
        [...current, pav.id],
        remaining.slice(i + 1),
        currentM2 + pav.m2
      );
    }
  };

  const exteriorPavilions = freePavilions.filter(p => p.tieneParedExterior);
  for (const startPav of exteriorPavilions) {
    generateCombinations(
      [startPav.id],
      freePavilions.filter(p => p.id !== startPav.id),
      startPav.m2
    );
  }

  return combinations
    .sort((a, b) => {
      const typesA = new Set(a.breakdown.map(b => b.tipo)).size;
      const typesB = new Set(b.breakdown.map(b => b.tipo)).size;
      if (typesB !== typesA) return typesB - typesA;
      return b.totalM2 - a.totalM2;
    })
    .slice(0, 15);
};

export const findConnectedPavilionCombinations = (
  allFairs: Fair[],
  pavilions: Pavilion[],
  year: number,
  requiredM2: number,
  selectedTypes: string[]
): WindowOption[] => {
  const yearStart = `${year}-01-01`;
  const yearEnd = `${year}-12-31`;
  const availablePavilions = pavilions.filter(p => selectedTypes.includes(p.tipo));
  if (availablePavilions.length === 0) return [];

  const dayFreePavilions: Record<string, string[]> = {};
  const cur = new Date(yearStart + 'T12:00:00Z');
  const end = new Date(yearEnd + 'T12:00:00Z');
  
  while (cur <= end) {
    const ds = cur.toISOString().split('T')[0];
    const freeOnDay = availablePavilions.filter(p => {
      return !allFairs.some(f => {
        if (!f.pabellonIds.includes(p.id)) return false;
        const phases = getFairPhases(f);
        return ds >= phases.inicioMontaje && ds <= phases.finOcupacion;
      });
    }).map(p => p.id);
    dayFreePavilions[ds] = freeOnDay;
    cur.setUTCDate(cur.getUTCDate() + 1);
  }

  const windows: WindowOption[] = [];
  let cursor = new Date(yearStart + 'T12:00:00Z');
  
  while (cursor <= end) {
    const ds = cursor.toISOString().split('T')[0];
    const freePavs = dayFreePavilions[ds];
    
    if (freePavs.length === 0) {
      cursor.setUTCDate(cursor.getUTCDate() + 1);
      continue;
    }

    const combinations = findValidCombinations(freePavs, availablePavilions, requiredM2);
    
    if (combinations.length > 0) {
      const start = ds;
      let lastValid = ds;
      let nxt = new Date(cursor);
      nxt.setUTCDate(nxt.getUTCDate() + 1);
      
      while (nxt <= end) {
        const nds = nxt.toISOString().split('T')[0];
        const nextFree = dayFreePavilions[nds];
        const nextCombinations = findValidCombinations(nextFree, availablePavilions, requiredM2);
        if (nextCombinations.length === 0) break;
        lastValid = nds;
        nxt.setUTCDate(nxt.getUTCDate() + 1);
      }
      
      const duration = diffDays(start, lastValid) + 1;
      const firstCombo = combinations[0];
      const m2ByType = firstCombo.breakdown.map(b => ({ tipo: b.tipo, m2: b.m2 }));
      
      windows.push({
        start,
        end: lastValid,
        duration,
        combinations,
        totalM2: firstCombo.totalM2,
        m2ByType
      });
      
      cursor = new Date(lastValid);
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    } else {
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
  }

  return windows.sort((a, b) => b.duration - a.duration);
};

export const calculateOccupancy = (pavilionId: string, allFairs: Fair[], year: number) => {
  const yearStart = `${year}-01-01`;
  const yearEnd = `${year}-12-31`;
  const daysInYear = getDaysInYear(year);
  const occupied = new Set<string>();
  allFairs.filter(f => f.pabellonIds.includes(pavilionId)).forEach(f => {
    const p = getFairPhases(f);
    let cur = p.inicioMontaje < yearStart ? yearStart : p.inicioMontaje;
    const end = p.finOcupacion > yearEnd ? yearEnd : p.finOcupacion;
    while (cur <= end) {
      occupied.add(cur);
      cur = addDays(cur, 1);
    }
  });
  return {
    occupiedDays: occupied.size,
    percentage: ((occupied.size / daysInYear) * 100).toFixed(1),
    totalDays: daysInYear
  };
};

export const getFreeM2ForDay = (dateStr: string, fairs: Fair[], pavilions: Pavilion[]): number => {
  const occupiedPavilions = new Set<string>();
  fairs.forEach(f => {
    const p = getFairPhases(f);
    if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
      f.pabellonIds.forEach(pid => occupiedPavilions.add(pid));
    }
  });
  return pavilions.filter(p => !occupiedPavilions.has(p.id)).reduce((sum, p) => sum + p.m2, 0);
};

export const getAvailablePavilionsByTypeForDay = (
  dateStr: string,
  fairs: Fair[],
  pavilions: Pavilion[],
  tipo: string
) => {
  const occupiedPavilions = new Set<string>();
  fairs.forEach(f => {
    const p = getFairPhases(f);
    if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
      f.pabellonIds.forEach(pid => occupiedPavilions.add(pid));
    }
  });
  return pavilions.filter(p => p.tipo === tipo && !occupiedPavilions.has(p.id));
};
EOF

# ---------------------------------------------------------
# 6. SEED CON 8 PABELLONES TOPOLÓGICOS
# ---------------------------------------------------------
cat << 'EOF' > src/data/seed.ts
import { Pavilion, Fair } from '../lib/validation';
import { addDays } from '../lib/dates';

export const PAVILIONS: Pavilion[] = [
  { id: 'p1', nombre: 'Salón Principal', m2: 3000, tipo: 'salón', tieneParedExterior: true, vecinos: ['p2', 'p3'] },
  { id: 'p2', nombre: 'Pabellón Norte', m2: 1500, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p4', 'p5'] },
  { id: 'p3', nombre: 'Pabellón Este', m2: 1500, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p6'] },
  { id: 'p4', nombre: 'Nave Semicubierta A', m2: 2000, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p2', 'p7'] },
  { id: 'p5', nombre: 'Módulo Cerrado Sur', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p2'] },
  { id: 'p6', nombre: 'Nave Semicubierta B', m2: 2000, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p3', 'p8'] },
  { id: 'p7', nombre: 'Playón Central', m2: 5000, tipo: 'playón', tieneParedExterior: true, vecinos: ['p4', 'p8'] },
  { id: 'p8', nombre: 'Plaza Aire Libre', m2: 4000, tipo: 'aire libre', tieneParedExterior: true, vecinos: ['p6', 'p7', 'p2', 'p3'] },
];

export const FAIR_COLORS = [
  '#1F4D2B', '#2F6B3A', '#3F6B4A', '#E8842C', '#5A8F6A', '#8FB996',
  '#D4A373', '#6B8E23'
];

export const generateSeedFairs = (year: number): Fair[] => {
  const base = `${year}-01-15`;
  const mk = (id: string, nombre: string, sector: string, offset: number, m: number, f: number, d: number, pavs: string[]): Fair => ({
    id, nombre, sector,
    color: FAIR_COLORS[parseInt(id.slice(1)) - 1] || '#3F6B4A',
    fechaInicioMontaje: addDays(base, offset),
    diasMontaje: m, diasFeria: f, diasDesmontaje: d, pabellonIds: pavs
  });

  return [
    mk('f1', 'Feria Internacional Multisectorial', 'Multisectorial', 30, 5, 8, 3, ['p1', 'p2']),
    mk('f2', 'Feria de la Construcción', 'Construcción', 60, 4, 6, 2, ['p7']),
    mk('f3', 'Feria Agropecuaria', 'Agro', 90, 3, 7, 2, ['p8']),
    mk('f4', 'Feria de Tecnología', 'Tecnología', 120, 3, 5, 2, ['p3', 'p4']),
    mk('f5', 'Feria del Mueble', 'Hogar', 150, 4, 6, 2, ['p5', 'p6']),
    mk('f6', 'Feria Gastronómica', 'Gastronomía', 180, 2, 8, 2, ['p1']),
    mk('f7', 'Expo Automotriz', 'Automotriz', 210, 5, 7, 3, ['p7', 'p8']),
    mk('f8', 'Feria de Moda', 'Textil', 240, 3, 5, 2, ['p2', 'p3']),
  ];
};
EOF

# ---------------------------------------------------------
# 7. STATE
# ---------------------------------------------------------
cat << 'EOF' > src/state/store.tsx
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Pavilion, Fair } from '../lib/validation';
import { PAVILIONS, generateSeedFairs } from '../data/seed';

const STORAGE_KEY = 'recinto-ferial:v3';

interface StoreState {
  pavilions: Pavilion[];
  fairs: Fair[];
  selectedYear: number;
}

interface StoreContextType extends StoreState {
  setFairs: (fairs: Fair[]) => void;
  setPavilions: (pavilions: Pavilion[]) => void;
  setSelectedYear: (year: number) => void;
  resetToSeed: () => void;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export const StoreProvider = ({ children }: { children: ReactNode }) => {
  const [state, setState] = useState<StoreState>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.pavilions && parsed.fairs) {
          return {
            pavilions: parsed.pavilions,
            fairs: parsed.fairs,
            selectedYear: parsed.selectedYear || new Date().getFullYear()
          };
        }
      }
    } catch (e) {
      console.warn('Datos corruptos, usando seed', e);
    }
    const y = new Date().getFullYear();
    return {
      pavilions: PAVILIONS,
      fairs: generateSeedFairs(y),
      selectedYear: y
    };
  });

  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch {}
  }, [state]);

  const resetToSeed = () => {
    setState(s => ({
      ...s,
      pavilions: PAVILIONS,
      fairs: generateSeedFairs(s.selectedYear)
    }));
  };

  return (
    <StoreContext.Provider value={{
      ...state,
      setFairs: (fairs) => setState(s => ({ ...s, fairs })),
      setPavilions: (pavilions) => setState(s => ({ ...s, pavilions })),
      setSelectedYear: (year) => setState(s => ({ ...s, selectedYear: year })),
      resetToSeed
    }}>
      {children}
    </StoreContext.Provider>
  );
};

export const useStore = () => {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore debe usarse dentro de StoreProvider');
  return ctx;
};
EOF

# ---------------------------------------------------------
# 8. ESTILOS GLOBALES
# ---------------------------------------------------------
cat << 'EOF' > src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;

html, body, #root {
  font-family: 'Inter', system-ui, sans-serif;
  color: #1D2E20;
  background: #F4F6F4;
}

.pattern-diagonal {
  background-image: repeating-linear-gradient(45deg, rgba(255,255,255,0.35) 0 4px, transparent 4px 8px);
}
.pattern-dots {
  background-image: radial-gradient(rgba(255,255,255,0.5) 1.5px, transparent 1.5px);
  background-size: 6px 6px;
}

.touch-target {
  min-height: 44px;
  min-width: 44px;
}

::-webkit-scrollbar { height: 8px; width: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #C9D1CA; border-radius: 4px; }

.fade-in { animation: fadeIn .25s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: translateY(0); } }
EOF

# ---------------------------------------------------------
# 9. MAIN Y APP
# ---------------------------------------------------------
cat << 'EOF' > src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { StoreProvider } from './state/store';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <StoreProvider>
      <App />
    </StoreProvider>
  </React.StrictMode>
);
EOF

cat << 'EOF' > src/App.tsx
import React, { useState, useEffect } from 'react';
import { CalendarView } from './views/CalendarView';
import { VerificationView } from './views/VerificationView';
import { FairsView } from './views/FairsView';
import { OccupancyView } from './views/OccupancyView';
import { PavilionsView } from './views/PavilionsView';

type Tab = 'calendario' | 'verificacion' | 'ferias' | 'ocupacion' | 'pabellones';

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: 'calendario',    label: 'Calendario',     icon: 'M3 8h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z' },
  { id: 'verificacion',  label: 'Verificación',   icon: 'M9 12l2 2 4-4m6 2a9 9 0 1 1-18 0 9 9 0 0 1 18 0z' },
  { id: 'ferias',        label: 'Ferias',         icon: 'M4 6h16M4 12h16M4 18h7' },
  { id: 'ocupacion',     label: 'Ocupación',      icon: 'M3 13h2v8H3zM8 8h2v13H8zM13 11h2v10h-2zM18 5h2v16h-2z' },
  { id: 'pabellones',    label: 'Pabellones',     icon: 'M3 21h18M5 21V7l7-4 7 4v14M9 9h2v2H9zM13 9h2v2h-2zM9 13h2v2H9zM13 13h2v2h-2z' },
];

export default function App() {
  const [tab, setTab] = useState<Tab>('calendario');

  useEffect(() => {
    const h = window.location.hash.replace('#', '') as Tab;
    if (TABS.some(t => t.id === h)) setTab(h);
  }, []);

  const change = (t: Tab) => {
    setTab(t);
    window.location.hash = t;
  };

  return (
    <div className="min-h-screen bg-expocad-bg flex flex-col">
      <header className="bg-white border-b border-expocad-line sticky top-0 z-50 shadow-card">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-lg bg-expocad-primary flex items-center justify-center shadow-sm">
              <svg className="w-6 h-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 21h18M5 21V7l7-4 7 4v14M9 9h2v2H9zM13 9h2v2h-2zM9 13h2v2H9zM13 13h2v2h-2zM9 17h2v2H9zM13 17h2v2h-2z"/>
              </svg>
            </div>
            <div className="leading-tight">
              <h1 className="font-title text-lg sm:text-xl font-bold text-expocad-dark">Recinto Ferial Cruceño</h1>
              <p className="text-xs text-expocad-muted font-medium tracking-wide">TABLERO DE OPERACIONES · SANTA CRUZ</p>
            </div>
          </div>
        </div>
        <nav className="max-w-7xl mx-auto px-2 sm:px-6 overflow-x-auto">
          <div className="flex gap-1 min-w-max">
            {TABS.map(t => (
              <button
                key={t.id}
                onClick={() => change(t.id)}
                className={`touch-target px-4 py-3 rounded-t-lg font-title font-medium text-sm whitespace-nowrap flex items-center gap-2 transition-colors border-b-2 ${
                  tab === t.id
                    ? 'text-expocad-primary border-expocad-accent bg-expocad-bg'
                    : 'text-expocad-muted border-transparent hover:text-expocad-dark hover:bg-expocad-bg/60'
                }`}
              >
                <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d={t.icon} />
                </svg>
                {t.label}
              </button>
            ))}
          </div>
        </nav>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 py-6">
        {tab === 'calendario'   && <CalendarView />}
        {tab === 'verificacion' && <VerificationView />}
        {tab === 'ferias'       && <FairsView />}
        {tab === 'ocupacion'    && <OccupancyView />}
        {tab === 'pabellones'   && <PavilionsView />}
      </main>

      <footer className="border-t border-expocad-line bg-white py-4 mt-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 text-xs text-expocad-muted flex flex-col sm:flex-row justify-between gap-2">
          <span>© {new Date().getFullYear()} Recinto Ferial Cruceño · Operaciones</span>
          <span>Tablero operativo · Datos simulados · v3.0</span>
        </div>
      </footer>
    </div>
  );
}
EOF

# ---------------------------------------------------------
# 10. COMPONENTE CALENDAR GRID
# ---------------------------------------------------------
cat << 'EOF' > src/components/CalendarGrid.tsx
import React from 'react';
import { Fair, getPhaseForDay, Pavilion } from '../lib/validation';
import { generateYearGrid, MONTH_NAMES } from '../lib/dates';

interface Props {
  year: number;
  fairs: Fair[];
  pavilions: Pavilion[];
  highlightRanges?: { start: string; end: string; label: string; color: string }[];
  onDayClick?: (date: string) => void;
  compact?: boolean;
  id?: string;
  getFreeM2ForDay?: (date: string) => number;
  totalM2?: number;
}

const phaseClass = (phase: string) => {
  switch (phase) {
    case 'montaje':    return 'opacity-50';
    case 'feria':      return '';
    case 'desmontaje': return 'pattern-diagonal';
    case 'limpieza':   return 'pattern-dots opacity-70';
    default: return '';
  }
};

export const CalendarGrid: React.FC<Props> = ({ 
  year, fairs, pavilions, highlightRanges = [], onDayClick, compact = false, id, getFreeM2ForDay, totalM2 = 0 
}) => {
  const weeks = generateYearGrid(year);
  const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  const getFairsForDay = (dateStr: string) => {
    const found: { fair: Fair; phase: 'montaje' | 'feria' | 'desmontaje' | 'limpieza' }[] = [];
    for (const f of fairs) {
      const phase = getPhaseForDay(f, dateStr);
      if (phase) found.push({ fair: f, phase });
    }
    return found;
  };

  const isHighlighted = (dateStr: string) => {
    return highlightRanges.find(r => dateStr >= r.start && dateStr <= r.end);
  };

  let lastMonth = -1;

  return (
    <div id={id} className="bg-white rounded-xl shadow-card overflow-hidden">
      <div className="grid grid-cols-7 bg-expocad-dark text-white">
        {days.map(d => (
          <div key={d} className="px-2 py-2 text-center font-title font-semibold text-[10px] sm:text-xs tracking-wider">
            {d.toUpperCase()}
          </div>
        ))}
      </div>

      <div className="divide-y divide-expocad-line">
        {weeks.map((week, wIdx) => {
          const monthLabel = (() => {
            for (const d of week) {
              if (!d) continue;
              const mi = new Date(d + 'T12:00:00Z').getUTCMonth();
              if (mi !== lastMonth) {
                const label = MONTH_NAMES[mi];
                lastMonth = mi;
                return label;
              }
            }
            return null;
          })();

          return (
            <div key={wIdx} className="grid grid-cols-7 relative">
              {monthLabel && (
                <div className="absolute -top-3 left-2 z-10 bg-expocad-bg border border-expocad-line px-2 py-0.5 rounded-full text-[10px] font-title font-bold text-expocad-primary tracking-wide">
                  {monthLabel.toUpperCase()}
                </div>
              )}
              {week.map((dateStr, dIdx) => {
                if (!dateStr) return <div key={dIdx} className={`border-r border-expocad-line bg-expocad-bg/40 ${compact ? 'h-10' : 'h-16 sm:h-20'}`} />;
                const month = new Date(dateStr + 'T12:00:00Z').getUTCMonth();
                const bgMonth = month % 2 === 0 ? 'bg-expocad-month1' : 'bg-expocad-month2';
                const dayFairs = getFairsForDay(dateStr);
                const highlight = isHighlighted(dateStr);
                const freeM2 = getFreeM2ForDay ? getFreeM2ForDay(dateStr) : 0;
                const isFullyOccupied = freeM2 === 0;
                const freePercent = totalM2 > 0 ? Math.round((freeM2 / totalM2) * 100) : 0;

                return (
                  <div
                    key={dateStr}
                    onClick={() => onDayClick?.(dateStr)}
                    className={`relative border-r border-expocad-line p-1 transition-colors ${isFullyOccupied ? 'bg-gray-300 opacity-60' : bgMonth} ${onDayClick ? 'cursor-pointer hover:ring-2 hover:ring-expocad-accent hover:ring-inset' : ''}`}
                    style={highlight ? { boxShadow: `inset 0 0 0 2px ${highlight.color}` } : undefined}
                  >
                    <div className="flex justify-between items-start mb-0.5">
                      <span className="font-title font-bold text-[10px] sm:text-xs text-expocad-dark">
                        {new Date(dateStr + 'T12:00:00Z').getUTCDate()}
                      </span>
                    </div>

                    {!isFullyOccupied && (
                      <div className="text-[8px] sm:text-[10px] text-expocad-muted font-medium mb-0.5">
                        Libre: {freePercent}%
                      </div>
                    )}

                    {dayFairs.length === 0 ? (
                      !isFullyOccupied && (
                        <div className="text-[8px] sm:text-[10px] text-expocad-muted font-medium italic opacity-60 mt-0.5">
                          LIBRE
                        </div>
                      )
                    ) : (
                      <div className="space-y-px">
                        {dayFairs.slice(0, compact ? 2 : 3).map(({ fair, phase }) => {
                          const fairM2 = fair.pabellonIds.reduce((sum, pid) => {
                            const pav = pavilions.find(p => p.id === pid);
                            return sum + (pav?.m2 || 0);
                          }, 0);
                          const percentOfRecinto = totalM2 > 0 ? ((fairM2 / totalM2) * 100).toFixed(1) : '0';
                          return (
                            <div
                              key={fair.id}
                              className={`h-2 sm:h-3 rounded ${phaseClass(phase)}`}
                              style={{ backgroundColor: fair.color }}
                              title={`${fair.nombre}: ${percentOfRecinto}% del recinto`}
                            />
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
    </div>
  );
};
EOF

echo "✅ Archivos base creados. Continuando con vistas..."
EOF

# ---------------------------------------------------------
# 11. VISTA CALENDARIO
# ---------------------------------------------------------
cat << 'EOF' > src/views/CalendarView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { CalendarGrid } from '../components/CalendarGrid';
import { getFairPhases, getPhaseForDay, getFreeM2ForDay } from '../lib/validation';
import { formatDate, MONTH_NAMES } from '../lib/dates';

export const CalendarView = () => {
  const { selectedYear, setSelectedYear, pavilions, fairs } = useStore();
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  const yearStart = `${selectedYear}-01-01`;
  const yearEnd = `${selectedYear}-12-31`;

  const totalM2 = pavilions.reduce((sum, p) => sum + p.m2, 0);

  const occupiedDays = new Set<string>();
  fairs.forEach(f => {
    const p = getFairPhases(f);
    let cur = p.inicioMontaje;
    while (cur <= p.finOcupacion) {
      if (cur >= yearStart && cur <= yearEnd) occupiedDays.add(cur);
      cur = new Date(cur); cur.setUTCDate(cur.getUTCDate() + 1); cur = cur.toISOString().split('T')[0];
    }
  });

  const occupiedCount = occupiedDays.size;
  const totalDays = (selectedYear % 4 === 0 && selectedYear % 100 !== 0) || selectedYear % 400 === 0 ? 366 : 365;
  const percent = ((occupiedCount / totalDays) * 100).toFixed(1);

  const avgOcupacion = fairs.length > 0 ? Math.round(fairs.reduce((sum, f) => sum + getFairPhases(f).totalDiasOcupados, 0) / fairs.length) : 0;
  const avgExpo = fairs.length > 0 ? Math.round(fairs.reduce((sum, f) => sum + f.diasFeria, 0) / fairs.length) : 0;

  const occupancyByPavilion = pavilions.map(p => {
    const days = new Set<string>();
    fairs.filter(f => f.pabellonIds.includes(p.id)).forEach(f => {
      const ph = getFairPhases(f);
      let cur = ph.inicioMontaje;
      while (cur <= ph.finOcupacion) {
        if (cur >= yearStart && cur <= yearEnd) days.add(cur);
        cur = new Date(cur); cur.setUTCDate(cur.getUTCDate() + 1); cur = cur.toISOString().split('T')[0];
      }
    });
    return { ...p, occupiedDays: days.size, percentage: ((days.size / totalDays) * 100).toFixed(1) };
  }).sort((a, b) => parseFloat(b.percentage) - parseFloat(a.percentage));

  const dayDetail = selectedDay ? {
    date: selectedDay,
    fairs: fairs.filter(f => getPhaseForDay(f, selectedDay) !== null)
  } : null;

  const freeM2ForDay = (dateStr: string) => getFreeM2ForDay(dateStr, fairs, pavilions);

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl shadow-card p-5">
          <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">Año operativo</div>
          <div className="flex items-center gap-2">
            <button onClick={() => setSelectedYear(Math.max(1900, selectedYear - 1))} className="touch-target w-9 h-9 rounded-lg bg-expocad-bg hover:bg-expocad-line flex items-center justify-center text-expocad-dark font-bold">‹</button>
            <input
              type="number"
              value={selectedYear}
              onChange={e => setSelectedYear(Math.min(2200, Math.max(1900, Number(e.target.value) || selectedYear)))}
              className="w-24 text-center font-title font-bold text-2xl border border-expocad-line rounded-lg py-1"
              min="1900" max="2200"
            />
            <button onClick={() => setSelectedYear(Math.min(2200, selectedYear + 1))} className="touch-target w-9 h-9 rounded-lg bg-expocad-bg hover:bg-expocad-line flex items-center justify-center text-expocad-dark font-bold">›</button>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-card p-5">
          <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">Ferias programadas</div>
          <div className="font-title font-bold text-lg text-expocad-primary">{fairs.length} ferias</div>
          <div className="text-xs text-expocad-muted mt-1">Media ocupación: {avgOcupacion} días</div>
          <div className="text-xs text-expocad-muted">Días exposición pública: {avgExpo} días</div>
        </div>
        <div className="bg-white rounded-xl shadow-card p-5">
          <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">Ocupación del recinto</div>
          <div className="flex items-baseline gap-2">
            <span className="font-title font-bold text-3xl text-expocad-dark">{occupiedDays.size}</span>
            <span className="text-sm text-expocad-muted">/ {totalDays}</span>
          </div>
          <div className="mt-2 h-2 bg-expocad-line rounded-full overflow-hidden">
            <div className="h-full bg-expocad-primary rounded-full transition-all" style={{ width: `${percent}%` }} />
          </div>
          <div className="text-xs text-expocad-muted mt-1">{percent}% de ocupación global</div>
        </div>
        <div className="bg-white rounded-xl shadow-card p-5">
          <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">Capacidad total</div>
          <div className="font-title font-bold text-3xl text-expocad-primary">{totalM2.toLocaleString()}</div>
          <div className="text-xs text-expocad-muted mt-1">m² de pabellones</div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-card p-5">
        <h3 className="font-title font-bold text-expocad-dark mb-4">Ocupación anual por pabellón</h3>
        <div className="space-y-3">
          {occupancyByPavilion.map(p => (
            <div key={p.id} className="flex items-center gap-3">
              <div className="w-32 sm:w-48 text-sm font-medium text-expocad-dark truncate">{p.nombre}</div>
              <div className="flex-1 bg-expocad-line rounded-full h-3 overflow-hidden">
                <div className="h-full bg-expocad-primary rounded-full transition-all" style={{ width: `${p.percentage}%` }} />
              </div>
              <div className="w-12 text-right font-title font-bold text-expocad-dark">{p.percentage}%</div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-card p-4 flex flex-wrap gap-x-4 gap-y-2 items-center text-sm">
        <span className="font-title font-bold text-expocad-dark">Leyenda:</span>
        <div className="flex items-center gap-2"><span className="w-5 h-3 rounded bg-expocad-primary opacity-50"></span><span className="text-expocad-muted">Montaje</span></div>
        <div className="flex items-center gap-2"><span className="w-5 h-3 rounded bg-expocad-primary"></span><span className="text-expocad-muted">Feria</span></div>
        <div className="flex items-center gap-2"><span className="w-5 h-3 rounded bg-expocad-primary pattern-diagonal"></span><span className="text-expocad-muted">Desmontaje</span></div>
        <div className="flex items-center gap-2"><span className="w-5 h-3 rounded bg-gray-400 pattern-dots"></span><span className="text-expocad-muted">Limpieza</span></div>
        <div className="flex items-center gap-2"><span className="w-5 h-3 rounded bg-gray-300 opacity-60"></span><span className="text-expocad-muted text-xs">OCUPADO</span></div>
      </div>

      <CalendarGrid year={selectedYear} fairs={fairs} pavilions={pavilions} onDayClick={setSelectedDay} getFreeM2ForDay={freeM2ForDay} totalM2={totalM2} />

      {dayDetail && (
        <div className="fixed inset-0 bg-expocad-dark/60 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4" onClick={() => setSelectedDay(null)}>
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-md max-h-[85vh] overflow-y-auto p-5 fade-in" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between items-start mb-4">
              <div>
                <div className="text-xs text-expocad-muted uppercase tracking-wider font-semibold">Detalle del día</div>
                <h3 className="font-title text-2xl font-bold text-expocad-dark">{formatDate(dayDetail.date)}</h3>
                <div className="text-sm text-expocad-muted">{MONTH_NAMES[new Date(dayDetail.date + 'T12:00:00Z').getUTCMonth()]}</div>
              </div>
              <button onClick={() => setSelectedDay(null)} className="touch-target w-10 h-10 rounded-full bg-expocad-bg hover:bg-expocad-line flex items-center justify-center text-expocad-dark text-xl font-bold">✕</button>
            </div>

            {dayDetail.fairs.length === 0 ? (
              <div className="py-8 text-center">
                <div className="w-16 h-16 mx-auto rounded-full bg-expocad-bg flex items-center justify-center mb-3">
                  <span className="text-2xl">🟢</span>
                </div>
                <p className="font-title font-bold text-lg text-expocad-primary">Día libre en todos los pabellones</p>
              </div>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-expocad-muted">{dayDetail.fairs.length} {dayDetail.fairs.length === 1 ? 'feria activa' : 'ferias activas'} en el recinto.</p>
                {dayDetail.fairs.map(f => {
                  const p = getFairPhases(f);
                  const phase = getPhaseForDay(f, dayDetail.date)!;
                  const phaseLabel: Record<string, string> = {
                    montaje: 'Montaje', feria: 'Feria Activa', desmontaje: 'Desmontaje', limpieza: 'Limpieza'
                  };
                  const pavs = f.pabellonIds.map(id => pavilions.find(p => p.id === id)?.nombre).filter(Boolean);
                  const fairM2 = f.pabellonIds.reduce((sum, pid) => {
                    const pav = pavilions.find(p => p.id === pid);
                    return sum + (pav?.m2 || 0);
                  }, 0);
                  const percentOfRecinto = ((fairM2 / totalM2) * 100).toFixed(1);
                  return (
                    <div key={f.id} className="border-l-4 rounded-r-lg bg-expocad-bg/70 p-3" style={{ borderColor: f.color }}>
                      <div className="flex items-start justify-between gap-2 mb-1">
                        <h4 className="font-title font-bold text-expocad-dark leading-tight">{f.nombre}</h4>
                        <span className="text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded" style={{ backgroundColor: f.color, color: 'white' }}>
                          {phaseLabel[phase]}
                        </span>
                      </div>
                      <div className="text-xs text-expocad-muted space-y-1 mt-2">
                        <div><span className="font-semibold text-expocad-dark">Sector:</span> {f.sector}</div>
                        <div><span className="font-semibold text-expocad-dark">Pabellones:</span> {pavs.join(', ')}</div>
                        <div><span className="font-semibold text-expocad-dark">Ocupación:</span> {percentOfRecinto}% del recinto ({fairM2.toLocaleString()} m²)</div>
                        <div className="pt-1 text-[11px] grid grid-cols-2 gap-1">
                          <div>Montaje: {formatDate(p.inicioMontaje)} → {formatDate(p.finMontaje)}</div>
                          <div>Feria: {formatDate(p.inicioFeria)} → {formatDate(p.finFeria)}</div>
                          <div>Desmontaje: {formatDate(p.inicioDesmontaje)} → {formatDate(p.finDesmontaje)}</div>
                          <div>Limpieza: {formatDate(p.inicioLimpieza)} → {formatDate(p.finLimpieza)}</div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
EOF

echo "✅ Vistas base creadas. El script continuará con las vistas restantes..."
echo "⚠️  NOTA: Este es un script parcial. Las vistas VerificationView, OccupancyView, FairsView y PavilionsView se crearán en el siguiente paso."
echo " Ejecuta 'npm install' y luego 'npm run dev' para probar lo creado hasta ahora."
