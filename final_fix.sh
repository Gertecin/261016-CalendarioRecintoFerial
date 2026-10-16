#!/bin/bash
set -e

echo "🔧 Aplicando correcciones finales..."

# ---------------------------------------------------------
# 1. CALENDARIO: números x2, solo % libre visible
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

export const CalendarGrid: React.FC<Props> = ({ 
  year, fairs, pavilions, highlightRanges = [], onDayClick, compact = false, id, getFreeM2ForDay, totalM2 = 0 
}) => {
  const weeks = generateYearGrid(year);
  const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  const getFairsForDay = (dateStr: string) => {
    const found: { fair: Fair; phase: string }[] = [];
    for (const f of fairs) {
      const phase = getPhaseForDay(f, dateStr);
      if (phase) found.push({ fair: f, phase });
    }
    return found;
  };

  const isHighlighted = (dateStr: string) => highlightRanges.find(r => dateStr >= r.start && dateStr <= r.end);
  let lastMonth = -1;

  return (
    <div id={id} className="bg-white rounded-xl shadow-card overflow-hidden">
      <div className="grid grid-cols-7 bg-expocad-dark text-white">
        {days.map(d => (
          <div key={d} className="px-2 py-2 text-center font-title font-semibold text-xs tracking-wider">{d}</div>
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
                if (!dateStr) return <div key={dIdx} className={`border-r border-expocad-line bg-expocad-bg/40 ${compact ? 'h-10' : 'h-14 sm:h-16'}`} />;
                const month = new Date(dateStr + 'T12:00:00Z').getUTCMonth();
                const bgMonth = month % 2 === 0 ? 'bg-expocad-month1' : 'bg-expocad-month2';
                const dayFairs = getFairsForDay(dateStr);
                const highlight = isHighlighted(dateStr);
                const freeM2 = getFreeM2ForDay ? getFreeM2ForDay(dateStr) : 0;
                const isFullyOccupied = freeM2 === 0;
                const freePercent = totalM2 > 0 ? Math.round((freeM2 / totalM2) * 100) : 0;
                const hasOccupation = dayFairs.length > 0;

                return (
                  <div
                    key={dateStr}
                    onClick={() => onDayClick?.(dateStr)}
                    className={`relative border-r border-expocad-line p-1 transition-colors ${isFullyOccupied ? 'bg-gray-300 opacity-60' : bgMonth} ${onDayClick ? 'cursor-pointer hover:ring-2 hover:ring-expocad-accent hover:ring-inset' : ''}`}
                    style={highlight ? { boxShadow: `inset 0 0 0 2px ${highlight.color}` } : undefined}
                  >
                    <div className="flex justify-between items-start">
                      <span className="font-title font-bold text-sm sm:text-base text-expocad-dark leading-none">
                        {new Date(dateStr + 'T12:00:00Z').getUTCDate()}
                      </span>
                      {hasOccupation && (
                        <span className="font-title font-bold text-sm sm:text-base text-expocad-primary leading-none">
                          {freePercent}%
                        </span>
                      )}
                    </div>

                    {dayFairs.length > 0 && (
                      <div className="space-y-px mt-1">
                        {dayFairs.slice(0, 3).map(({ fair }) => (
                          <div
                            key={fair.id}
                            className="h-2 sm:h-2.5 rounded"
                            style={{ backgroundColor: fair.color }}
                            title={fair.nombre}
                          />
                        ))}
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

echo "✓ CalendarGrid actualizado"

# ---------------------------------------------------------
# 2. VERIFICACIÓN: Relajar lógica para que funcione siempre
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
  hasAllTypes: boolean;
  typesCount: number;
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
  requiredM2: number,
  requiredTypes: string[]
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
        const typesInCombo = new Set(breakdown.map(b => b.tipo));
        const hasAllTypes = requiredTypes.length === 0 || requiredTypes.every(t => typesInCombo.has(t));
        combinations.push({
          pavilionIds: [...current],
          totalM2: currentM2,
          breakdown,
          hasAllTypes,
          typesCount: typesInCombo.size
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
      if (a.hasAllTypes !== b.hasAllTypes) return a.hasAllTypes ? -1 : 1;
      if (a.typesCount !== b.typesCount) return b.typesCount - a.typesCount;
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
  const availablePavilions = pavilions.filter(p => selectedTypes.length === 0 || selectedTypes.includes(p.tipo));
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

    const combinations = findValidCombinations(freePavs, availablePavilions, requiredM2, selectedTypes);
    
    if (combinations.length > 0) {
      const start = ds;
      let lastValid = ds;
      let nxt = new Date(cursor);
      nxt.setUTCDate(nxt.getUTCDate() + 1);
      
      while (nxt <= end) {
        const nds = nxt.toISOString().split('T')[0];
        const nextFree = dayFreePavilions[nds];
        const nextCombinations = findValidCombinations(nextFree, availablePavilions, requiredM2, selectedTypes);
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

echo "✓ Validation.ts actualizado (lógica relajada)"

# ---------------------------------------------------------
# 3. FERIAS: Colores como los anulares
# ---------------------------------------------------------
cat << 'EOF' > src/data/seed.ts
import { Pavilion, Fair } from '../lib/validation';
import { addDays } from '../lib/dates';

export const PAVILIONS: Pavilion[] = [
  { id: 'p1', nombre: 'Pabellón Principal', m2: 8000, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p2', 'p3', 'p7'] },
  { id: 'p2', nombre: 'Pabellón Internacional', m2: 4500, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p4'] },
  { id: 'p3', nombre: 'Pabellón 1', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p5'] },
  { id: 'p4', nombre: 'Pabellón 2', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p2', 'p6'] },
  { id: 'p5', nombre: 'Pabellón 3', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p3', 'p7'] },
  { id: 'p6', nombre: 'Pabellón 4', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p4', 'p8'] },
  { id: 'p7', nombre: 'Sector Aire Libre A', m2: 5000, tipo: 'aire libre', tieneParedExterior: true, vecinos: ['p1', 'p5', 'p8', 'p9'] },
  { id: 'p8', nombre: 'Sector Aire Libre B', m2: 5000, tipo: 'aire libre', tieneParedExterior: true, vecinos: ['p6', 'p7', 'p9', 'p10'] },
  { id: 'p9', nombre: 'Playón de Maquinaria', m2: 10000, tipo: 'playón', tieneParedExterior: true, vecinos: ['p7', 'p8', 'p10'] },
  { id: 'p10', nombre: 'Salón de Convenciones', m2: 3000, tipo: 'salón', tieneParedExterior: true, vecinos: ['p8', 'p9'] },
];

// Colores basados en los anulares de tipos
export const FAIR_COLORS = [
  '#3F6B4A', // cerrado (verde)
  '#E8842C', // semicubierto (naranja)
  '#4682B4', // aire libre (azul)
  '#8A2BE2', // playón (violeta)
  '#FF6347', // salón (tomate)
  '#3F6B4A',
  '#E8842C',
  '#4682B4',
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
    mk('f2', 'Feria de la Construcción', 'Construcción', 60, 4, 6, 2, ['p9']),
    mk('f3', 'Feria Agropecuaria', 'Agro', 90, 3, 7, 2, ['p7', 'p8']),
    mk('f4', 'Feria de Tecnología', 'Tecnología', 120, 3, 5, 2, ['p3', 'p4']),
    mk('f5', 'Feria del Mueble', 'Hogar', 150, 4, 6, 2, ['p5', 'p6']),
    mk('f6', 'Feria Gastronómica', 'Gastronomía', 180, 2, 8, 2, ['p10']),
    mk('f7', 'Expo Automotriz', 'Automotriz', 210, 5, 7, 3, ['p9', 'p7']),
    mk('f8', 'Feria de Moda', 'Textil', 240, 3, 5, 2, ['p2', 'p3']),
  ];
};
EOF

echo "✓ Seed actualizado con colores anulares"

# ---------------------------------------------------------
# 4. OCUPACIÓN: Meses mitad de alto, unificados, solo leyenda
# ---------------------------------------------------------
cat << 'EOF' > src/views/OccupancyView.tsx
import React from 'react';
import { useStore } from '../state/store';
import { getFairPhases, getAvailablePavilionsByTypeForDay } from '../lib/validation';
import { MONTH_NAMES, addDays } from '../lib/dates';

const TIPO_COLORS: Record<string, string> = {
  'cerrado': '#3F6B4A',
  'semicubierto': '#E8842C',
  'aire libre': '#4682B4',
  'playón': '#8A2BE2',
  'salón': '#FF6347'
};

export const OccupancyView = () => {
  const { selectedYear, setSelectedYear, pavilions, fairs } = useStore();
  const tipos = [...new Set(pavilions.map(p => p.tipo))];

  const getDaysInMonth = (year: number, month: number) => new Date(year, month + 1, 0).getDate();

  const getOccupancyByTipo = () => {
    const yearStart = `${selectedYear}-01-01`;
    const yearEnd = `${selectedYear}-12-31`;
    const totalDays = (selectedYear % 4 === 0 && selectedYear % 100 !== 0) || selectedYear % 400 === 0 ? 366 : 365;

    return tipos.map(tipo => {
      const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
      const occupiedDays = new Set<string>();
      
      fairs.forEach(f => {
        const p = getFairPhases(f);
        const hasPavilionOfType = f.pabellonIds.some(pid => pavilionsOfType.some(p => p.id === pid));
        if (hasPavilionOfType) {
          let cur = p.inicioMontaje;
          while (cur <= p.finOcupacion) {
            if (cur >= yearStart && cur <= yearEnd) occupiedDays.add(cur);
            cur = addDays(cur, 1);
          }
        }
      });

      const percentage = ((occupiedDays.size / totalDays) * 100).toFixed(1);
      return { tipo, occupiedDays: occupiedDays.size, percentage, totalDays };
    });
  };

  const occupancyByTipo = getOccupancyByTipo();

  const getDayOccupied = (year: number, month: number, day: number, tipo: string) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
    const totalPav = pavilionsOfType.length;
    
    let occupiedCount = 0;
    fairs.forEach(f => {
      const p = getFairPhases(f);
      if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
        const matchingPavs = f.pabellonIds.filter(pid => pavilionsOfType.some(p => p.id === pid));
        occupiedCount += matchingPavs.length;
      }
    });
    
    return { occupied: occupiedCount, total: totalPav };
  };

  const getDayOfWeek = (year: number, month: number, day: number) => new Date(year, month, day).getDay();

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <h2 className="font-title text-2xl sm:text-3xl font-bold text-expocad-dark">Ocupación</h2>
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-expocad-muted">Año:</label>
          <input type="number" min={1900} max={2200} value={selectedYear} onChange={e => setSelectedYear(Math.min(2200, Math.max(1900, Number(e.target.value) || selectedYear)))} className="w-24 text-center border border-expocad-line rounded-lg py-2 font-title font-bold" />
        </div>
      </div>

      {/* Gráfico anular */}
      <div className="bg-white rounded-xl shadow-card p-5">
        <h3 className="font-title font-bold text-expocad-dark mb-4">Ocupación anual por tipo de pabellón</h3>
        <div className="flex flex-wrap justify-around gap-6">
          {occupancyByTipo.map((item) => {
            const percentage = parseFloat(item.percentage);
            const circumference = 2 * Math.PI * 50;
            const strokeDashoffset = circumference - (percentage / 100) * circumference;
            const color = TIPO_COLORS[item.tipo] || '#3F6B4A';

            return (
              <div key={item.tipo} className="flex flex-col items-center flex-1 min-w-[120px]">
                <svg width="140" height="140" className="transform -rotate-90">
                  <circle cx="70" cy="70" r="50" stroke="#E5E9E6" strokeWidth="12" fill="none" />
                  <circle
                    cx="70"
                    cy="70"
                    r="50"
                    stroke={color}
                    strokeWidth="12"
                    fill="none"
                    strokeDasharray={circumference}
                    strokeDashoffset={strokeDashoffset}
                    strokeLinecap="round"
                  />
                  <text x="70" y="70" textAnchor="middle" dominantBaseline="central" className="transform rotate-90 origin-center" style={{ fontSize: '18px', fontWeight: 'bold', fill: '#1D2E20' }}>
                    {item.percentage}%
                  </text>
                </svg>
                <div className="mt-2 text-center">
                  <div className="font-title font-bold text-expocad-dark capitalize text-sm">{item.tipo}</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Leyenda de colores */}
      <div className="bg-white rounded-xl shadow-card p-4">
        <h4 className="font-title font-bold text-expocad-dark mb-3 text-sm">Leyenda por tipo de pabellón</h4>
        <div className="flex flex-wrap gap-4">
          {tipos.map(tipo => (
            <div key={tipo} className="flex items-center gap-2">
              <div className="w-4 h-4 rounded" style={{ backgroundColor: TIPO_COLORS[tipo] }} />
              <span className="text-sm capitalize text-expocad-dark">{tipo}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Calendarios Gantt unificados - meses mitad de alto */}
      <div className="space-y-4">
        {tipos.map(tipo => {
          const color = TIPO_COLORS[tipo] || '#3F6B4A';
          const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);

          return (
            <div key={tipo} className="bg-white rounded-xl shadow-card p-4">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-4 h-4 rounded" style={{ backgroundColor: color }} />
                <h3 className="font-title font-bold text-expocad-dark capitalize">{tipo}</h3>
                <span className="text-xs text-expocad-muted">({pavilionsOfType.length} pabellones)</span>
              </div>
              
              <div className="overflow-x-auto">
                <div className="min-w-[700px]">
                  <div className="grid grid-cols-[50px_repeat(31,1fr)] gap-px mb-1">
                    <div className="text-[10px] font-bold text-expocad-muted">Mes</div>
                    {Array.from({ length: 31 }, (_, i) => (
                      <div key={i} className="text-center text-[10px] font-bold text-expocad-dark">{i + 1}</div>
                    ))}
                  </div>
                  
                  {MONTH_NAMES.map((monthName, monthIdx) => {
                    const daysInMonth = getDaysInMonth(selectedYear, monthIdx);
                    return (
                      <div key={monthIdx} className="grid grid-cols-[50px_repeat(31,1fr)] gap-px mb-px">
                        <div className="text-[10px] font-medium text-expocad-muted flex items-center">{monthName}</div>
                        {Array.from({ length: 31 }, (_, dayIdx) => {
                          const day = dayIdx + 1;
                          if (day > daysInMonth) return <div key={dayIdx} className="bg-gray-100 h-4" />;
                          const dow = getDayOfWeek(selectedYear, monthIdx, day);
                          const { occupied, total } = getDayOccupied(selectedYear, monthIdx, day, tipo);
                          const isSaturday = dow === 6;
                          const isSunday = dow === 0;
                          
                          let bgColor = 'bg-white';
                          if (isSunday) bgColor = 'bg-expocad-primary/15';
                          else if (isSaturday) bgColor = 'bg-expocad-primary/5';
                          
                          if (occupied > 0) {
                            const opacity = 0.3 + (occupied / total) * 0.7;
                            return (
                              <div 
                                key={dayIdx} 
                                className="h-4 rounded-sm"
                                style={{ backgroundColor: color, opacity }}
                                title={`${occupied}/${total} pabellones ocupados`}
                              />
                            );
                          }
                          
                          return <div key={dayIdx} className={`h-4 rounded-sm ${bgColor}`} />;
                        })}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
EOF

echo "✓ OccupancyView actualizado (meses h-4, unificados, solo leyenda)"

echo ""
echo "✅ Todas las correcciones aplicadas"
echo "🔄 Recarga el navegador (Ctrl+R)"
