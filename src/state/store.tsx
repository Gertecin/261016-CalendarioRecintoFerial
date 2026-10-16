import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Pavilion, Fair } from '../lib/validation';
import { PAVILIONS, generateSeedFairs } from '../data/seed';

const STORAGE_KEY = 'recinto-ferial:v3';

export interface PendingFair {
  nombre: string;
  sector: string;
  fechaInicioMontaje: string;
  diasMontaje: number;
  diasFeria: number;
  diasDesmontaje: number;
  pabellonIds: string[];
  color: string;
}

interface StoreState {
  pavilions: Pavilion[];
  fairs: Fair[];
  selectedYear: number;
  pendingFair: PendingFair | null;
}

interface StoreContextType extends StoreState {
  setFairs: (fairs: Fair[]) => void;
  setPavilions: (pavilions: Pavilion[]) => void;
  setSelectedYear: (year: number) => void;
  setPendingFair: (pending: PendingFair | null) => void;
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
            selectedYear: parsed.selectedYear || new Date().getFullYear(),
            pendingFair: null
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
      selectedYear: y,
      pendingFair: null
    };
  });

  useEffect(() => {
    try {
      const { pendingFair, ...toSave } = state;
      localStorage.setItem(STORAGE_KEY, JSON.stringify(toSave));
    } catch {}
  }, [state]);

  const resetToSeed = () => {
    setState(s => ({
      ...s,
      pavilions: PAVILIONS,
      fairs: generateSeedFairs(s.selectedYear),
      pendingFair: null
    }));
  };

  return (
    <StoreContext.Provider value={{
      ...state,
      setFairs: (fairs) => setState(s => ({ ...s, fairs })),
      setPavilions: (pavilions) => setState(s => ({ ...s, pavilions })),
      setSelectedYear: (year) => setState(s => ({ ...s, selectedYear: year })),
      setPendingFair: (pendingFair) => setState(s => ({ ...s, pendingFair })),
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
