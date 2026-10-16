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
