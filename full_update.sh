#!/bin/bash
set -e

echo "🚀 Actualización completa: Calendario, Verificación, Ferias, Ocupación, Pabellones..."

# ---------------------------------------------------------
# 1. ACTUALIZAR SEED CON PABELLONES DEL BRIEFING + TOPOLOGÍA
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

export const FAIR_COLORS = [
  '#FF00FF', // Magenta
  '#00FFFF', // Cyan
  '#FFFF00', // Amarillo
  '#FF1493', // Rosa fuerte
  '#00FF7F', // Verde spring
  '#FF4500', // Naranja rojizo
  '#9400D3', // Violeta oscuro
  '#FFD700', // Oro
  '#00CED1', // Turquesa oscuro
  '#FF69B4', // Rosa caliente
  '#7FFF00', // Verde chartreuse
  '#FF6347', // Tomate
  '#4169E1', // Azul royal
  '#32CD32', // Verde lima
  '#FF8C00', // Naranja oscuro
  '#DC143C', // Carmesí
  '#00BFFF', // Azul cielo profundo
  '#FFD700', // Oro
  '#8A2BE2', // Azul violeta
  '#FF1493', // Rosa profundo
  '#00FA9A', // Verde menta medio
  '#FF4500', // Naranja rojizo
];

export const generateSeedFairs = (year: number): Fair[] => {
  const base = `${year}-01-15`;
  const mk = (id: string, nombre: string, sector: string, offset: number, m: number, f: number, d: number, pavs: string[]): Fair => ({
    id, nombre, sector,
    color: FAIR_COLORS[parseInt(id.slice(1)) - 1] || '#FF00FF',
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

echo "✓ Seed actualizado con pabellones del briefing"

# ---------------------------------------------------------
# 2. ACTUALIZAR VALIDATION.TS - Prioridad: TODOS los tipos
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
        const hasAllTypes = requiredTypes.every(t => typesInCombo.has(t));
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

  // PRIORIDAD: 1) hasAllTypes, 2) más tipos, 3) más m²
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

    const combinations = findValidCombinations(freePavs, availablePavilions, requiredM2, selectedTypes);
    
    // Filtrar solo combinaciones que tienen TODOS los tipos requeridos
    const validCombinations = combinations.filter(c => c.hasAllTypes);
    
    if (validCombinations.length > 0) {
      const start = ds;
      let lastValid = ds;
      let nxt = new Date(cursor);
      nxt.setUTCDate(nxt.getUTCDate() + 1);
      
      while (nxt <= end) {
        const nds = nxt.toISOString().split('T')[0];
        const nextFree = dayFreePavilions[nds];
        const nextCombinations = findValidCombinations(nextFree, availablePavilions, requiredM2, selectedTypes);
        const nextValid = nextCombinations.filter(c => c.hasAllTypes);
        if (nextValid.length === 0) break;
        lastValid = nds;
        nxt.setUTCDate(nxt.getUTCDate() + 1);
      }
      
      const duration = diffDays(start, lastValid) + 1;
      const firstCombo = validCombinations[0];
      const m2ByType = firstCombo.breakdown.map(b => ({ tipo: b.tipo, m2: b.m2 }));
      
      windows.push({
        start,
        end: lastValid,
        duration,
        combinations: validCombinations,
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

echo "✓ Validation.ts actualizado con prioridad de tipos"

# ---------------------------------------------------------
# 3. ACTUALIZAR CALENDARVIEW - Gráfica de columnas
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

  const maxPercentage = Math.max(...occupancyByPavilion.map(p => parseFloat(p.percentage)), 1);

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
        <div className="flex items-end gap-2 h-48 overflow-x-auto pb-2">
          {occupancyByPavilion.map(p => {
            const height = (parseFloat(p.percentage) / maxPercentage) * 100;
            return (
              <div key={p.id} className="flex flex-col items-center min-w-[60px] flex-1">
                <div className="text-xs font-bold text-expocad-dark mb-1">{p.percentage}%</div>
                <div className="w-full bg-expocad-line rounded-t-lg relative" style={{ height: '100%' }}>
                  <div 
                    className="absolute bottom-0 w-full bg-expocad-primary rounded-t-lg transition-all"
                    style={{ height: `${height}%` }}
                  />
                </div>
                <div className="text-[10px] text-expocad-muted mt-2 text-center truncate w-full" title={p.nombre}>
                  {p.nombre.split(' ').slice(0, 2).join(' ')}
                </div>
              </div>
            );
          })}
        </div>
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

echo "✓ CalendarView actualizado con gráfica de columnas"

# ---------------------------------------------------------
# 4. ACTUALIZAR FAIRSVIEW - Colores más contrastantes
# ---------------------------------------------------------
cat << 'EOF' > src/views/FairsView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { Fair, checkConflicts, getFairPhases } from '../lib/validation';
import { formatDate, addDays } from '../lib/dates';

export const FairsView = () => {
  const { fairs, setFairs, pavilions, selectedYear, resetToSeed } = useStore();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  const emptyFair: Partial<Fair> = {
    nombre: '', sector: '', color: '#FF00FF', fechaInicioMontaje: `${selectedYear}-03-01`,
    diasMontaje: 3, diasFeria: 5, diasDesmontaje: 2, pabellonIds: []
  };
  const [form, setForm] = useState<Partial<Fair>>(emptyFair);
  const [validation, setValidation] = useState<any>(null);

  const filtered = fairs.filter(f => f.nombre.toLowerCase().includes(search.toLowerCase()) || f.sector.toLowerCase().includes(search.toLowerCase()));

  const handleSave = () => {
    if (!form.nombre || !form.fechaInicioMontaje || (form.pabellonIds?.length || 0) === 0) {
      alert('Complete todos los campos obligatorios.');
      return;
    }
    const fairToCheck: Fair = {
      id: editingId || `f${Date.now()}`,
      nombre: form.nombre!, sector: form.sector!, color: form.color!,
      fechaInicioMontaje: form.fechaInicioMontaje!,
      diasMontaje: form.diasMontaje!, diasFeria: form.diasFeria!, diasDesmontaje: form.diasDesmontaje!,
      pabellonIds: form.pabellonIds!
    };
    const val = checkConflicts(fairToCheck, fairs, pavilions, editingId || undefined);
    setValidation(val);
    if (val.hasConflict) return;

    if (editingId) setFairs(fairs.map(f => f.id === editingId ? fairToCheck : f));
    else setFairs([...fairs, fairToCheck]);
    setShowForm(false); setEditingId(null); setForm(emptyFair); setValidation(null);
  };

  const livePhases = form.fechaInicioMontaje && form.diasMontaje && form.diasFeria && form.diasDesmontaje
    ? getFairPhases({ fechaInicioMontaje: form.fechaInicioMontaje, diasMontaje: form.diasMontaje, diasFeria: form.diasFeria, diasDesmontaje: form.diasDesmontaje } as Fair)
    : null;

  const colorOptions = ['#FF00FF', '#00FFFF', '#FFFF00', '#FF1493', '#00FF7F', '#FF4500', '#9400D3', '#FFD700', '#00CED1', '#FF69B4', '#7FFF00', '#FF6347', '#4169E1', '#32CD32', '#FF8C00', '#DC143C', '#00BFFF', '#8A2BE2', '#00FA9A', '#FF1493'];

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <h2 className="font-title text-2xl sm:text-3xl font-bold text-expocad-dark">Ferias programadas</h2>
        <div className="flex flex-wrap gap-2">
          <button onClick={() => { if (confirm('¿Restaurar datos de ejemplo?')) resetToSeed(); }} className="touch-target px-4 py-2 border border-expocad-line text-expocad-dark rounded-lg font-medium hover:bg-expocad-bg text-sm">Restaurar seed</button>
          <button onClick={() => { setShowForm(true); setEditingId(null); setForm(emptyFair); setValidation(null); }} className="touch-target px-4 py-2 bg-expocad-primary text-white rounded-lg font-medium hover:opacity-90 text-sm">+ Nueva feria</button>
        </div>
      </div>

      <input type="text" placeholder="Buscar por nombre o sector…" value={search} onChange={e => setSearch(e.target.value)} className="w-full border border-expocad-line rounded-lg px-4 py-2 touch-target bg-white" />

      {showForm && (
        <div className="bg-white p-5 rounded-xl shadow-card space-y-4 border border-expocad-line">
          <h3 className="font-title text-lg font-bold text-expocad-dark">{editingId ? 'Editar' : 'Nueva'} feria</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Nombre *</label><input className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} /></div>
            <div><label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Sector *</label><input className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.sector} onChange={e => setForm({ ...form, sector: e.target.value })} /></div>
            <div><label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Inicio montaje *</label><input type="date" className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.fechaInicioMontaje} onChange={e => setForm({ ...form, fechaInicioMontaje: e.target.value })} /></div>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Color</label>
              <div className="flex flex-wrap gap-2">
                {colorOptions.map(c => (
                  <button
                    key={c}
                    onClick={() => setForm({ ...form, color: c })}
                    className={`w-8 h-8 rounded-lg border-2 ${form.color === c ? 'border-expocad-dark scale-110' : 'border-transparent'}`}
                    style={{ backgroundColor: c }}
                  />
                ))}
              </div>
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div><label className="block text-[10px] font-semibold text-expocad-muted">Montaje</label><input type="number" className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.diasMontaje} onChange={e => setForm({ ...form, diasMontaje: Number(e.target.value) })} /></div>
              <div><label className="block text-[10px] font-semibold text-expocad-muted">Feria</label><input type="number" className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.diasFeria} onChange={e => setForm({ ...form, diasFeria: Number(e.target.value) })} /></div>
              <div><label className="block text-[10px] font-semibold text-expocad-muted">Desmontaje</label><input type="number" className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.diasDesmontaje} onChange={e => setForm({ ...form, diasDesmontaje: Number(e.target.value) })} /></div>
            </div>
          </div>

          <div className="bg-expocad-bg p-3 rounded-lg text-xs">
            <p className="font-semibold text-expocad-dark mb-1">+1 día de limpieza (automático)</p>
            {livePhases && (
              <div className="grid grid-cols-2 gap-2 text-expocad-muted">
                <div>Montaje: {formatDate(livePhases.inicioMontaje)} → {formatDate(livePhases.finMontaje)}</div>
                <div>Feria: {formatDate(livePhases.inicioFeria)} → {formatDate(livePhases.finFeria)}</div>
                <div>Desmontaje: {formatDate(livePhases.inicioDesmontaje)} → {formatDate(livePhases.finDesmontaje)}</div>
                <div>Limpieza: {formatDate(livePhases.inicioLimpieza)} → {formatDate(livePhases.finLimpieza)}</div>
              </div>
            )}
            <p className="mt-2 font-bold text-expocad-primary">Total días ocupados: {livePhases?.totalDiasOcupados ?? 0}</p>
          </div>

          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Pabellones *</label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-expocad-line rounded-lg p-2">
              {pavilions.map(p => (
                <label key={p.id} className="flex items-center gap-2 touch-target">
                  <input type="checkbox" checked={form.pabellonIds?.includes(p.id)} onChange={e => {
                    const ids = form.pabellonIds || [];
                    setForm({ ...form, pabellonIds: e.target.checked ? [...ids, p.id] : ids.filter(id => id !== p.id) });
                  }} />
                  <span className="text-sm">{p.nombre} ({p.m2.toLocaleString()} m²)</span>
                </label>
              ))}
            </div>
          </div>

          {validation && validation.hasConflict && (
            <div className="bg-expocad-accent/10 border border-expocad-accent p-3 rounded-lg text-sm">
              <p className="font-bold mb-1 text-expocad-dark">⚠ Conflicto detectado:</p>
              {validation.conflicts.map((c: any, i: number) => (
                <p key={i} className="text-expocad-dark">Choca con «{c.fairNombre}» en {c.pabellonNombre}. Días pisados: {c.fechasPisadas.join(', ')}. Primera fecha disponible: {formatDate(c.primeraFechaDisponible)}</p>
              ))}
            </div>
          )}

          <div className="flex gap-2 pt-2">
            <button onClick={handleSave} className="touch-target flex-1 bg-expocad-primary text-white rounded-lg py-2 font-medium">Guardar</button>
            <button onClick={() => { setShowForm(false); setValidation(null); }} className="touch-target flex-1 border border-expocad-line rounded-lg py-2 font-medium">Cancelar</button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead className="bg-expocad-dark text-white font-title">
              <tr>
                <th className="p-3">Nombre</th>
                <th className="p-3 hidden sm:table-cell">Sector</th>
                <th className="p-3 hidden md:table-cell">Fechas</th>
                <th className="p-3 text-center">Pabellones</th>
                <th className="p-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-expocad-line">
              {filtered.map(f => {
                const p = getFairPhases(f);
                return (
                  <tr key={f.id} className="hover:bg-expocad-bg/60">
                    <td className="p-3 font-medium"><div className="flex items-center gap-2"><span className="w-4 h-4 rounded-sm" style={{ backgroundColor: f.color }}></span>{f.nombre}</div></td>
                    <td className="p-3 hidden sm:table-cell text-expocad-muted">{f.sector}</td>
                    <td className="p-3 hidden md:table-cell text-xs text-expocad-muted">{formatDate(p.inicioMontaje)} → {formatDate(p.finOcupacion)}</td>
                    <td className="p-3 text-center">{f.pabellonIds.length}</td>
                    <td className="p-3 text-right space-x-2">
                      <button onClick={() => { setForm(f); setEditingId(f.id); setShowForm(true); setValidation(null); }} className="text-expocad-primary hover:underline text-xs">Editar</button>
                      <button onClick={() => { if (confirm('¿Eliminar esta feria?')) setFairs(fairs.filter(x => x.id !== f.id)); }} className="text-expocad-accent hover:underline font-medium text-xs">Eliminar</button>
                    </td>
                  </tr>
                );
              })}
              {filtered.length === 0 && <tr><td colSpan={5} className="p-6 text-center text-expocad-muted">No se encontraron ferias.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
EOF

echo "✓ FairsView actualizado con colores contrastantes"

# ---------------------------------------------------------
# 5. ACTUALIZAR OCCUPANCYVIEW - Calendario Gantt + Gráfico anular
# ---------------------------------------------------------
cat << 'EOF' > src/views/OccupancyView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { getFairPhases, getPhaseForDay, getAvailablePavilionsByTypeForDay } from '../lib/validation';
import { MONTH_NAMES, addDays, diffDays } from '../lib/dates';

const MONTH_NAMES_SHORT = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

export const OccupancyView = () => {
  const { selectedYear, setSelectedYear, pavilions, fairs } = useStore();
  const [selectedTipo, setSelectedTipo] = useState<string | null>(null);

  const tipos = [...new Set(pavilions.map(p => p.tipo))];
  const totalM2 = pavilions.reduce((sum, p) => sum + p.m2, 0);

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getOccupancyByTipo = () => {
    const yearStart = `${selectedYear}-01-01`;
    const yearEnd = `${selectedYear}-12-31`;
    const totalDays = (selectedYear % 4 === 0 && selectedYear % 100 !== 0) || selectedYear % 400 === 0 ? 366 : 365;

    return tipos.map(tipo => {
      const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
      const occupiedDays = new Set<string>();
      
      fairs.forEach(f => {
        const p = getFairPhases(f);
        const fairTypes = pavilionsOfType.filter(p => f.pabellonIds.includes(p.id));
        if (fairTypes.length > 0) {
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

  const getFairForDayAndTipo = (year: number, month: number, day: number, tipo: string) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
    
    for (const f of fairs) {
      const p = getFairPhases(f);
      const hasPavilionOfType = f.pabellonIds.some(pid => pavilionsOfType.some(p => p.id === pid));
      if (hasPavilionOfType && dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
        return f;
      }
    }
    return null;
  };

  const getDayOfWeek = (year: number, month: number, day: number) => {
    return new Date(year, month, day).getDay();
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <h2 className="font-title text-2xl sm:text-3xl font-bold text-expocad-dark">Ocupación</h2>
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-expocad-muted">Año:</label>
          <input type="number" min={1900} max={2200} value={selectedYear} onChange={e => setSelectedYear(Math.min(2200, Math.max(1900, Number(e.target.value) || selectedYear)))} className="w-24 text-center border border-expocad-line rounded-lg py-2 font-title font-bold" />
        </div>
      </div>

      {selectedTipo && (
        <div className="bg-white rounded-xl shadow-card p-5">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-title text-lg font-bold text-expocad-dark capitalize">{selectedTipo}</h3>
            <button onClick={() => setSelectedTipo(null)} className="text-expocad-muted hover:text-expocad-dark text-sm">← Volver</button>
          </div>
          <p className="text-sm text-expocad-muted mb-4">Se muestran el nº de pabellones <strong>{selectedTipo.toUpperCase()}</strong> y el total de m² disponibles</p>
          
          <div className="overflow-x-auto">
            <div className="min-w-[800px]">
              {/* Header con días 1-31 */}
              <div className="grid grid-cols-[60px_repeat(31,1fr)] gap-px mb-2">
                <div className="text-xs font-bold text-expocad-muted">Día</div>
                {Array.from({ length: 31 }, (_, i) => (
                  <div key={i} className="text-center text-xs font-bold text-expocad-dark">{i + 1}</div>
                ))}
              </div>
              
              {/* Filas por mes */}
              {MONTH_NAMES.map((monthName, monthIdx) => {
                const daysInMonth = getDaysInMonth(selectedYear, monthIdx);
                return (
                  <div key={monthIdx} className="grid grid-cols-[60px_repeat(31,1fr)] gap-px mb-1">
                    <div className="text-xs font-medium text-expocad-muted flex items-center">{monthName}</div>
                    {Array.from({ length: 31 }, (_, dayIdx) => {
                      const day = dayIdx + 1;
                      if (day > daysInMonth) {
                        return <div key={dayIdx} className="bg-gray-100 h-8" />;
                      }
                      const dow = getDayOfWeek(selectedYear, monthIdx, day);
                      const fair = getFairForDayAndTipo(selectedYear, monthIdx, day, selectedTipo);
                      const isSaturday = dow === 6;
                      const isSunday = dow === 0;
                      
                      let bgColor = 'bg-white';
                      if (isSunday) bgColor = 'bg-expocad-primary/20';
                      else if (isSaturday) bgColor = 'bg-expocad-primary/10';
                      
                      if (fair) {
                        return (
                          <div 
                            key={dayIdx} 
                            className="h-8 rounded-sm" 
                            style={{ backgroundColor: fair.color }}
                            title={fair.nombre}
                          />
                        );
                      }
                      
                      return <div key={dayIdx} className={`h-8 rounded-sm ${bgColor}`} />;
                    })}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {!selectedTipo && (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {tipos.map(tipo => {
              const stats = occupancyByTipo.find(t => t.tipo === tipo);
              const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
              const today = new Date();
              const todayStr = today.toISOString().split('T')[0];
              const availableToday = getAvailablePavilionsByTypeForDay(todayStr, fairs, pavilions, tipo);
              const todayM2 = availableToday.reduce((sum, p) => sum + p.m2, 0);
              const dayOfMonth = today.getUTCDate();

              return (
                <div
                  key={tipo}
                  onClick={() => setSelectedTipo(tipo)}
                  className="bg-white rounded-xl shadow-card p-5 cursor-pointer hover:shadow-elevated transition-shadow border-2 border-transparent hover:border-expocad-primary"
                >
                  <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">{availableToday.length} DISPONIBLES</div>
                  <div className="font-title font-bold text-5xl text-expocad-dark my-3">{dayOfMonth}</div>
                  <div className="text-sm text-expocad-muted">TOTAL <span className="font-bold text-expocad-dark">{todayM2.toLocaleString()}</span> m²</div>
                  <div className="mt-3 text-xs text-expocad-primary font-semibold capitalize">Ver calendario →</div>
                </div>
              );
            })}
          </div>

          {/* Gráfico anular por tipo */}
          <div className="bg-white rounded-xl shadow-card p-5">
            <h3 className="font-title font-bold text-expocad-dark mb-4">Ocupación anual por tipo de pabellón</h3>
            <div className="flex flex-wrap justify-center gap-8">
              {occupancyByTipo.map((item, idx) => {
                const percentage = parseFloat(item.percentage);
                const circumference = 2 * Math.PI * 40;
                const strokeDashoffset = circumference - (percentage / 100) * circumference;
                const colors = ['#3F6B4A', '#E8842C', '#4682B4', '#8A2BE2', '#FF6347'];
                const color = colors[idx % colors.length];

                return (
                  <div key={item.tipo} className="flex flex-col items-center">
                    <svg width="100" height="100" className="transform -rotate-90">
                      <circle cx="50" cy="50" r="40" stroke="#E5E9E6" strokeWidth="8" fill="none" />
                      <circle
                        cx="50"
                        cy="50"
                        r="40"
                        stroke={color}
                        strokeWidth="8"
                        fill="none"
                        strokeDasharray={circumference}
                        strokeDashoffset={strokeDashoffset}
                        strokeLinecap="round"
                      />
                    </svg>
                    <div className="mt-2 text-center">
                      <div className="font-title font-bold text-expocad-dark capitalize">{item.tipo}</div>
                      <div className="text-sm text-expocad-muted">{item.percentage}%</div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}
    </div>
  );
};
EOF

echo "✓ OccupancyView actualizado con calendario Gantt y gráfico anular"

# ---------------------------------------------------------
# 6. ACTUALIZAR VERIFICATIONVIEW - Vista de calendario
# ---------------------------------------------------------
cat << 'EOF' > src/views/VerificationView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { findConnectedPavilionCombinations, WindowOption, PavilionCombination } from '../lib/validation';
import { formatDate, MONTH_NAMES, addDays, generateSpanGrid } from '../lib/dates';

export const VerificationView = () => {
  const { selectedYear, setSelectedYear, fairs, pavilions } = useStore();
  const [diasMontaje, setDiasMontaje] = useState(5);
  const [diasExpo, setDiasExpo] = useState(7);
  const [diasDesmontaje, setDiasDesmontaje] = useState(3);
  const [metrosNecesarios, setMetrosNecesarios] = useState(5000);
  const [tiposSeleccionados, setTiposSeleccionados] = useState<string[]>([]);
  const [searched, setSearched] = useState(false);
  const [windows, setWindows] = useState<WindowOption[]>([]);
  const [selectedOptions, setSelectedOptions] = useState<{ [key: number]: { windowIdx: number; comboIdx: number } | null }>({});
  const [fixedOptions, setFixedOptions] = useState<Set<number>>(new Set());
  const [showConfirmModal, setShowConfirmModal] = useState<number | null>(null);
  const [showManyCombinations, setShowManyCombinations] = useState(false);

  const totalRequired = diasMontaje + diasExpo + diasDesmontaje + 1;
  const minM2 = Math.min(...pavilions.map(p => p.m2));
  const tiposDisponibles = [...new Set(pavilions.map(p => p.tipo))];

  const handleSearch = () => {
    if (metrosNecesarios < minM2) {
      alert(`Los metros necesarios deben ser al menos ${minM2} m² (el pabellón más pequeño)`);
      return;
    }
    if (tiposSeleccionados.length === 0) {
      alert('Seleccione al menos un tipo de espacio');
      return;
    }

    const results = findConnectedPavilionCombinations(fairs, pavilions, selectedYear, metrosNecesarios, tiposSeleccionados);
    
    if (results.length > 15) {
      setShowManyCombinations(true);
      return;
    }

    setWindows(results.slice(0, 3));
    setSearched(true);
    setSelectedOptions({});
    setFixedOptions(new Set());
  };

  const handleSelectOption = (windowIdx: number, comboIdx: number) => {
    setSelectedOptions(prev => ({ ...prev, [windowIdx]: { windowIdx, comboIdx } }));
  };

  const handleFixOption = (windowIdx: number) => {
    if (!selectedOptions[windowIdx]) {
      alert('Elija una ventana');
      return;
    }
    setShowConfirmModal(windowIdx);
  };

  const confirmFix = (windowIdx: number) => {
    setFixedOptions(prev => new Set([...prev, windowIdx]));
    setShowConfirmModal(null);
  };

  const canExport = fixedOptions.size > 0;

  const getM2ByTypeText = (m2ByType: { tipo: string; m2: number }[]) => {
    return m2ByType.map(m => `${m.m2.toLocaleString()} m² ${m.tipo}`).join(', ');
  };

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getFairForDay = (year: number, month: number, day: number) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    for (const f of fairs) {
      const p = getFairPhases(f);
      if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
        return f;
      }
    }
    return null;
  };

  const getDayOfWeek = (year: number, month: number, day: number) => {
    return new Date(year, month, day).getDay();
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-title text-2xl sm:text-3xl font-bold text-expocad-dark">Verificación de disponibilidad</h2>
        <p className="text-expocad-muted text-sm mt-1">Consulte ventanas libres en el recinto para agendar una nueva feria.</p>
      </div>

      <div className="bg-white rounded-xl shadow-card p-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Días Montaje</label>
            <input type="number" min={1} value={diasMontaje} onChange={e => setDiasMontaje(Math.max(1, Number(e.target.value) || 1))} className="w-full border border-expocad-line rounded-lg px-3 py-2 font-title text-xl" />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Días de Exposición Activa</label>
            <input type="number" min={1} value={diasExpo} onChange={e => setDiasExpo(Math.max(1, Number(e.target.value) || 1))} className="w-full border border-expocad-line rounded-lg px-3 py-2 font-title text-xl" />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Días de Desmontaje</label>
            <input type="number" min={1} value={diasDesmontaje} onChange={e => setDiasDesmontaje(Math.max(1, Number(e.target.value) || 1))} className="w-full border border-expocad-line rounded-lg px-3 py-2 font-title text-xl" />
            <p className="text-[11px] text-expocad-muted mt-1">No incluya el día de limpieza, el sistema lo incluye en la búsqueda.</p>
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Metros necesarios (m²)</label>
            <input type="number" min={minM2} value={metrosNecesarios} onChange={e => setMetrosNecesarios(Math.max(minM2, Number(e.target.value) || minM2))} className="w-full border border-expocad-line rounded-lg px-3 py-2 font-title text-xl" />
            <p className="text-[11px] text-expocad-muted mt-1">Mínimo: {minM2} m²</p>
          </div>
        </div>

        <div className="mt-4">
          <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Tipos de espacio necesarios</label>
          <div className="flex flex-wrap gap-2">
            {tiposDisponibles.map(tipo => (
              <label key={tipo} className="flex items-center gap-2 touch-target bg-expocad-bg px-3 py-2 rounded-lg cursor-pointer hover:bg-expocad-line">
                <input type="checkbox" checked={tiposSeleccionados.includes(tipo)} onChange={e => {
                  if (e.target.checked) setTiposSeleccionados([...tiposSeleccionados, tipo]);
                  else setTiposSeleccionados(tiposSeleccionados.filter(t => t !== tipo));
                }} />
                <span className="text-sm capitalize">{tipo}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="mt-5 flex flex-col sm:flex-row gap-3 items-start sm:items-center justify-between pt-4 border-t border-expocad-line">
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-expocad-dark">Año:</label>
            <input type="number" min={1900} max={2200} value={selectedYear} onChange={e => setSelectedYear(Math.min(2200, Math.max(1900, Number(e.target.value) || selectedYear)))} className="w-24 text-center border border-expocad-line rounded-lg py-2 font-title font-bold" />
          </div>
          <div className="text-sm text-expocad-dark">
            <span className="font-semibold">Total días:</span>{' '}
            <span className="font-title font-bold text-xl text-expocad-primary">{totalRequired}</span>
            <span className="text-expocad-muted ml-1 text-xs">(incluye +1 día de limpieza)</span>
          </div>
          <button onClick={handleSearch} className="touch-target w-full sm:w-auto bg-expocad-accent hover:opacity-90 text-white font-title font-bold px-6 py-3 rounded-lg shadow-sm">
            Buscar ventanas disponibles
          </button>
        </div>
      </div>

      {searched && windows.length > 0 && (
        <div className="space-y-5">
          <div className="bg-white rounded-xl shadow-card p-5">
            <h3 className="font-title text-xl font-bold text-expocad-dark mb-4">Calendario de disponibilidad</h3>
            
            <div className="overflow-x-auto mb-6">
              <div className="min-w-[800px]">
                <div className="grid grid-cols-[60px_repeat(31,1fr)] gap-px mb-2">
                  <div className="text-xs font-bold text-expocad-muted">Día</div>
                  {Array.from({ length: 31 }, (_, i) => (
                    <div key={i} className="text-center text-xs font-bold text-expocad-dark">{i + 1}</div>
                  ))}
                </div>
                
                {MONTH_NAMES.map((monthName, monthIdx) => {
                  const daysInMonth = getDaysInMonth(selectedYear, monthIdx);
                  return (
                    <div key={monthIdx} className="grid grid-cols-[60px_repeat(31,1fr)] gap-px mb-1">
                      <div className="text-xs font-medium text-expocad-muted flex items-center">{monthName}</div>
                      {Array.from({ length: 31 }, (_, dayIdx) => {
                        const day = dayIdx + 1;
                        if (day > daysInMonth) {
                          return <div key={dayIdx} className="bg-gray-100 h-8" />;
                        }
                        const dow = getDayOfWeek(selectedYear, monthIdx, day);
                        const fair = getFairForDay(selectedYear, monthIdx, day);
                        const isSaturday = dow === 6;
                        const isSunday = dow === 0;
                        
                        let bgColor = 'bg-white';
                        if (isSunday) bgColor = 'bg-expocad-primary/20';
                        else if (isSaturday) bgColor = 'bg-expocad-primary/10';
                        
                        if (fair) {
                          return (
                            <div 
                              key={dayIdx} 
                              className="h-8 rounded-sm" 
                              style={{ backgroundColor: fair.color }}
                              title={fair.nombre}
                            />
                          );
                        }
                        
                        return <div key={dayIdx} className={`h-8 rounded-sm ${bgColor}`} />;
                      })}
                    </div>
                  );
                })}
              </div>
            </div>

            <h4 className="font-title font-bold text-expocad-dark mb-3">Ventanas disponibles</h4>
            <div className="space-y-4">
              {windows.map((win, wIdx) => {
                const selected = selectedOptions[wIdx];
                const isFixed = fixedOptions.has(wIdx);
                const combo = selected ? win.combinations[selected.comboIdx] : null;

                return (
                  <div key={wIdx} className={`border-2 rounded-xl p-4 transition-all ${isFixed ? 'border-expocad-primary bg-expocad-bg' : 'border-expocad-line'}`}>
                    <div className="flex items-center justify-between mb-3">
                      <div>
                        <h4 className="font-title font-bold text-expocad-dark">Ventana {wIdx + 1}</h4>
                        <p className="text-sm text-expocad-muted">{formatDate(win.start)} → {formatDate(win.end)} ({win.duration} días)</p>
                      </div>
                      {isFixed && <span className="text-xs font-bold text-expocad-primary bg-expocad-primary/10 px-2 py-0.5 rounded">FIJADA</span>}
                    </div>

                    <div className="mb-3 p-3 bg-expocad-bg rounded-lg">
                      <p className="text-xs font-semibold text-expocad-dark mb-1">Esta ventana tiene:</p>
                      <p className="text-sm text-expocad-dark">{getM2ByTypeText(win.m2ByType)}</p>
                    </div>

                    <div className="space-y-2 mb-3">
                      <p className="text-xs font-semibold text-expocad-muted uppercase">Combinaciones disponibles:</p>
                      <div className="max-h-40 overflow-y-auto space-y-2">
                        {win.combinations.map((combo, cIdx) => (
                          <label key={cIdx} className={`flex items-start gap-2 p-2 rounded-lg cursor-pointer ${selected?.comboIdx === cIdx ? 'bg-expocad-primary/10 border border-expocad-primary' : 'bg-white border border-expocad-line hover:bg-expocad-bg'}`}>
                            <input type="radio" name={`window-${wIdx}`} checked={selected?.comboIdx === cIdx} onChange={() => handleSelectOption(wIdx, cIdx)} className="mt-1" />
                            <div className="text-sm">
                              <div className="font-medium text-expocad-dark">{combo.totalM2.toLocaleString()} m² totales</div>
                              <div className="text-xs text-expocad-muted">
                                {combo.breakdown.map(b => `${b.count}x ${b.tipo} (${b.m2.toLocaleString()} m²)`).join(', ')}
                              </div>
                              {combo.totalM2 > metrosNecesarios && (
                                <div className="text-xs text-expocad-accent mt-1">
                                  Contiene {(combo.totalM2 - metrosNecesarios).toLocaleString()} m² adicionales
                                </div>
                              )}
                            </div>
                          </label>
                        ))}
                      </div>
                    </div>

                    {!isFixed && (
                      <button onClick={() => handleFixOption(wIdx)} className="touch-target w-full bg-expocad-accent hover:opacity-90 text-white font-title font-bold px-4 py-2 rounded-lg">
                        Fijar Ventana {wIdx + 1}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {canExport && (
            <button className="touch-target w-full bg-expocad-primary hover:opacity-90 text-white font-title font-bold px-5 py-3 rounded-xl shadow-card">
              📄 Exportar a PDF
            </button>
          )}
        </div>
      )}

      {searched && windows.length === 0 && (
        <div className="bg-white rounded-xl shadow-card p-8 text-center">
          <p className="text-expocad-muted">No se encontraron ventanas disponibles con los criterios seleccionados.</p>
        </div>
      )}

      {showManyCombinations && (
        <div className="fixed inset-0 bg-expocad-dark/60 z-50 flex items-center justify-center p-4" onClick={() => setShowManyCombinations(false)}>
          <div className="bg-white rounded-xl p-6 max-w-md" onClick={e => e.stopPropagation()}>
            <h3 className="font-title text-xl font-bold text-expocad-dark mb-3">Muchas combinaciones posibles</h3>
            <p className="text-expocad-dark mb-4">Existen muchas combinaciones posibles. Fije una fecha antes de mostrar la combinación de espacios disponibles con la cantidad de metros solicitada, o limite el tipo de pabellón a utilizar.</p>
            <button onClick={() => setShowManyCombinations(false)} className="touch-target w-full bg-expocad-primary text-white rounded-lg py-2 font-medium">Entendido</button>
          </div>
        </div>
      )}

      {showConfirmModal !== null && (
        <div className="fixed inset-0 bg-expocad-dark/60 z-50 flex items-center justify-center p-4" onClick={() => setShowConfirmModal(null)}>
          <div className="bg-white rounded-xl p-6 max-w-md" onClick={e => e.stopPropagation()}>
            <h3 className="font-title text-xl font-bold text-expocad-dark mb-3">Confirmar selección</h3>
            <p className="text-expocad-dark mb-2">Esta ventana tiene:</p>
            <p className="text-expocad-dark font-medium mb-4">{getM2ByTypeText(windows[showConfirmModal].m2ByType)}</p>
            <p className="text-expocad-dark mb-4">¿Selección correcta?</p>
            <div className="flex gap-2">
              <button onClick={() => setShowConfirmModal(null)} className="touch-target flex-1 border border-expocad-line rounded-lg py-2 font-medium">NO</button>
              <button onClick={() => confirmFix(showConfirmModal)} className="touch-target flex-1 bg-expocad-primary text-white rounded-lg py-2 font-medium">Confirmar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const getFairPhases = (fair: any) => {
  const { addDays, diffDays, LIMPIEZA_DIAS } = require('../lib/dates');
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
EOF

echo "✓ VerificationView actualizado con vista de calendario"

echo ""
echo "✅ Todas las vistas actualizadas"
echo " Recarga el navegador (Ctrl+R) para ver los cambios"
