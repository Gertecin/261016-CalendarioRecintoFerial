#!/bin/bash
set -e

echo "🔧 Añadiendo botón 'Crear Feria' en Verificación y 'Verificar' en Ferias..."

# ---------------------------------------------------------
# 1. ACTUALIZAR APP.TSX para escuchar cambio de pestaña desde vistas hijas
# ---------------------------------------------------------
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

  // Escuchar cambios de pestaña desde vistas hijas
  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as Tab;
      if (TABS.some(t => t.id === detail)) {
        setTab(detail);
        window.location.hash = detail;
      }
    };
    window.addEventListener('changeTab', handler);
    return () => window.removeEventListener('changeTab', handler);
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

echo "✓ App.tsx actualizado con listener de cambio de pestaña"

# ---------------------------------------------------------
# 2. ACTUALIZAR STORE para soportar pendingFair
# ---------------------------------------------------------
cat << 'EOF' > src/state/store.tsx
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
EOF

echo "✓ Store actualizado con pendingFair"

# ---------------------------------------------------------
# 3. ACTUALIZAR VERIFICATIONVIEW - Botón CREAR FERIA
# ---------------------------------------------------------
cat << 'EOF' > src/views/VerificationView.tsx
import React, { useState, useRef } from 'react';
import { useStore } from '../state/store';
import { findConnectedPavilionCombinations, WindowOption, getFairPhases } from '../lib/validation';
import { formatDate, MONTH_NAMES, addDays, diffDays } from '../lib/dates';
import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';

const WINDOW_COLORS = ['#E8842C', '#4682B4', '#8A2BE2'];

export const VerificationView = () => {
  const { selectedYear, setSelectedYear, fairs, pavilions, setPendingFair } = useStore();
  const [diasMontaje, setDiasMontaje] = useState(5);
  const [diasExpo, setDiasExpo] = useState(7);
  const [diasDesmontaje, setDiasDesmontaje] = useState(3);
  const [metrosNecesarios, setMetrosNecesarios] = useState(5000);
  const [tiposSeleccionados, setTiposSeleccionados] = useState<string[]>([]);
  const [searched, setSearched] = useState(false);
  const [windows, setWindows] = useState<WindowOption[]>([]);
  const [selectedOptions, setSelectedOptions] = useState<{ [key: number]: { windowIdx: number; comboIdx: number } | null }>({});
  const [fixedOptions, setFixedOptions] = useState<{ [key: number]: { windowIdx: number; comboIdx: number; startDate: string } }>({});
  const [showStartInput, setShowStartInput] = useState<number | null>(null);
  const [startInputValue, setStartInputValue] = useState('');
  const [showManyCombinations, setShowManyCombinations] = useState(false);
  const [exporting, setExporting] = useState(false);
  const calendarRef = useRef<HTMLDivElement>(null);

  const totalRequired = diasMontaje + diasExpo + diasDesmontaje + 1;
  const minM2 = Math.min(...pavilions.map(p => p.m2));
  const tiposDisponibles = [...new Set(pavilions.map(p => p.tipo))];

  const handleSearch = () => {
    if (metrosNecesarios < minM2) {
      alert(`Los metros necesarios deben ser al menos ${minM2} m²`);
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
    setFixedOptions({});
  };

  const handleSelectOption = (windowIdx: number, comboIdx: number) => {
    setSelectedOptions(prev => ({ ...prev, [windowIdx]: { windowIdx, comboIdx } }));
  };

  const handleFixClick = (windowIdx: number) => {
    if (!selectedOptions[windowIdx]) {
      alert('Elija una combinación antes de fijar');
      return;
    }
    setStartInputValue(windows[windowIdx].start);
    setShowStartInput(windowIdx);
  };

  const confirmFix = (windowIdx: number) => {
    if (!startInputValue) {
      alert('Seleccione una fecha de inicio');
      return;
    }
    const win = windows[windowIdx];
    if (startInputValue < win.start || startInputValue > win.end) {
      alert(`La fecha debe estar entre ${formatDate(win.start)} y ${formatDate(win.end)}`);
      return;
    }
    const endDate = addDays(startInputValue, totalRequired - 1);
    if (endDate > win.end) {
      alert(`La feria no cabe: necesita ${totalRequired} días pero solo quedan ${diffDays(startInputValue, win.end) + 1} días en la ventana`);
      return;
    }
    setFixedOptions(prev => ({
      ...prev,
      [windowIdx]: {
        windowIdx,
        comboIdx: selectedOptions[windowIdx]!.comboIdx,
        startDate: startInputValue
      }
    }));
    setShowStartInput(null);
  };

  // NUEVO: Crear feria desde ventana fijada
  const handleCreateFair = (windowIdx: number) => {
    const fixed = fixedOptions[windowIdx];
    if (!fixed) {
      alert('Primero debe fijar la ventana con una fecha de inicio');
      return;
    }
    const win = windows[windowIdx];
    const combo = win.combinations[fixed.comboIdx];
    const pavNames = combo.pavilionIds.map(id => pavilions.find(p => p.id === id)?.nombre).filter(Boolean);
    
    setPendingFair({
      nombre: `Nueva Feria (desde Verificación)`,
      sector: 'Por definir',
      fechaInicioMontaje: fixed.startDate,
      diasMontaje,
      diasFeria: diasExpo,
      diasDesmontaje: diasDesmontaje,
      pabellonIds: combo.pavilionIds,
      color: WINDOW_COLORS[windowIdx]
    });
    
    // Navegar a pestaña Ferias
    window.dispatchEvent(new CustomEvent('changeTab', { detail: 'ferias' }));
  };

  const canExport = Object.keys(fixedOptions).length > 0;

  const getM2ByTypeText = (m2ByType: { tipo: string; m2: number }[]) => {
    return m2ByType.map(m => `${m.m2.toLocaleString()} m² ${m.tipo}`).join(', ');
  };

  const getDaysInMonth = (year: number, month: number) => new Date(year, month + 1, 0).getDate();

  const getFairForDay = (year: number, month: number, day: number) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    for (const f of fairs) {
      const p = getFairPhases(f);
      if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) return f;
    }
    return null;
  };

  const getDayOfWeek = (year: number, month: number, day: number) => new Date(year, month, day).getDay();

  const isDayInFixedWindow = (year: number, month: number, day: number, fixed: { startDate: string }) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const endDate = addDays(fixed.startDate, totalRequired - 1);
    return dateStr >= fixed.startDate && dateStr <= endDate;
  };

  const isDayInAnyWindow = (year: number, month: number, day: number) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return windows.some(w => dateStr >= w.start && dateStr <= w.end);
  };

  const handleExportPDF = async () => {
    if (!calendarRef.current) return;
    setExporting(true);
    try {
      const canvas = await html2canvas(calendarRef.current, {
        scale: 2,
        backgroundColor: '#FFFFFF',
        useCORS: true,
        logging: false
      });
      const imgData = canvas.toDataURL('image/png');
      const pdf = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a3' });
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();
      const ratio = Math.min(pageWidth / canvas.width, pageHeight / canvas.height) * 0.95;
      const imgW = canvas.width * ratio;
      const imgH = canvas.height * ratio;
      const x = (pageWidth - imgW) / 2;
      const y = (pageHeight - imgH) / 2;
      pdf.addImage(imgData, 'PNG', x, y, imgW, imgH);
      pdf.save(`verificacion-feria-${selectedYear}.pdf`);
    } catch (e) {
      console.error(e);
      alert('Error al generar el PDF');
    } finally {
      setExporting(false);
    }
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
          <div ref={calendarRef} className="bg-white rounded-xl shadow-card p-5">
            <h3 className="font-title text-xl font-bold text-expocad-dark mb-4">Calendario de disponibilidad {selectedYear}</h3>
            
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
                        if (day > daysInMonth) return <div key={dayIdx} className="bg-gray-100 h-8" />;
                        const dow = getDayOfWeek(selectedYear, monthIdx, day);
                        const fair = getFairForDay(selectedYear, monthIdx, day);
                        
                        let bgColor = 'bg-white';
                        if (dow === 0) bgColor = 'bg-expocad-primary/20';
                        else if (dow === 6) bgColor = 'bg-expocad-primary/10';
                        
                        const fixedEntry = Object.entries(fixedOptions).find(([_, f]) => isDayInFixedWindow(selectedYear, monthIdx, day, f));
                        const anyWindow = isDayInAnyWindow(selectedYear, monthIdx, day);
                        
                        if (fixedEntry) {
                          const [key, fixed] = fixedEntry;
                          const color = WINDOW_COLORS[Number(key)];
                          return (
                            <div 
                              key={dayIdx} 
                              className="h-8 rounded-sm" 
                              style={{ backgroundColor: color }}
                              title={`Ventana ${Number(key) + 1} fijada`}
                            />
                          );
                        }
                        
                        if (fair) {
                          return (
                            <div key={dayIdx} className="h-8 rounded-sm" style={{ backgroundColor: fair.color, opacity: 0.25 }} title={fair.nombre} />
                          );
                        }
                        
                        const borderStyle = anyWindow ? { border: '1px dashed #E8842C' } : undefined;
                        return <div key={dayIdx} className={`h-8 rounded-sm ${bgColor}`} style={borderStyle} />;
                      })}
                    </div>
                  );
                })}
              </div>
            </div>

            <h4 className="font-title font-bold text-expocad-dark mb-3">Ventanas disponibles ({windows.length})</h4>
            <div className="space-y-4">
              {windows.map((win, wIdx) => {
                const selected = selectedOptions[wIdx];
                const isFixed = fixedOptions[wIdx] !== undefined;
                const color = WINDOW_COLORS[wIdx];

                return (
                  <div key={wIdx} className="rounded-xl p-4 transition-all" style={{ border: `3px solid ${color}`, backgroundColor: isFixed ? `${color}15` : 'white' }}>
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full flex items-center justify-center text-white font-title font-bold text-sm" style={{ backgroundColor: color }}>
                          {wIdx + 1}
                        </div>
                        <div>
                          <h4 className="font-title font-bold text-expocad-dark">Ventana {wIdx + 1}</h4>
                          <p className="text-sm text-expocad-muted">{formatDate(win.start)} → {formatDate(win.end)} ({win.duration} días)</p>
                        </div>
                      </div>
                      {isFixed && (
                        <span className="text-xs font-bold px-3 py-1 rounded-full text-white" style={{ backgroundColor: color }}>
                          FIJADA · Inicio: {formatDate(fixedOptions[wIdx].startDate)}
                        </span>
                      )}
                    </div>

                    <div className="mb-3 p-3 rounded-lg" style={{ backgroundColor: `${color}10` }}>
                      <p className="text-xs font-semibold text-expocad-dark mb-1">Esta ventana tiene:</p>
                      <p className="text-sm text-expocad-dark">{getM2ByTypeText(win.m2ByType)}</p>
                    </div>

                    <div className="space-y-2 mb-3">
                      <p className="text-xs font-semibold text-expocad-muted uppercase">Combinaciones disponibles:</p>
                      <div className="max-h-40 overflow-y-auto space-y-2">
                        {win.combinations.map((combo, cIdx) => (
                          <label key={cIdx} className={`flex items-start gap-2 p-2 rounded-lg cursor-pointer ${selected?.comboIdx === cIdx ? 'border-2' : 'border border-expocad-line hover:bg-expocad-bg'}`} style={selected?.comboIdx === cIdx ? { borderColor: color, backgroundColor: `${color}10` } : {}}>
                            <input type="radio" name={`window-${wIdx}`} checked={selected?.comboIdx === cIdx} onChange={() => handleSelectOption(wIdx, cIdx)} className="mt-1" />
                            <div className="text-sm">
                              <div className="font-medium text-expocad-dark">{combo.totalM2.toLocaleString()} m² totales</div>
                              <div className="text-xs text-expocad-muted">
                                {combo.breakdown.map(b => `${b.count}x ${b.tipo} (${b.m2.toLocaleString()} m²)`).join(', ')}
                              </div>
                              {combo.totalM2 > metrosNecesarios && (
                                <div className="text-xs mt-1" style={{ color }}>
                                  Contiene {(combo.totalM2 - metrosNecesarios).toLocaleString()} m² adicionales
                                </div>
                              )}
                            </div>
                          </label>
                        ))}
                      </div>
                    </div>

                    {!isFixed ? (
                      showStartInput === wIdx ? (
                        <div className="space-y-2 p-3 rounded-lg" style={{ backgroundColor: `${color}10` }}>
                          <label className="block text-sm font-semibold text-expocad-dark">
                            Día de inicio de ocupación (dentro de la ventana):
                          </label>
                          <input 
                            type="date" 
                            min={win.start} 
                            max={win.end} 
                            value={startInputValue}
                            onChange={e => setStartInputValue(e.target.value)}
                            className="w-full border-2 rounded-lg px-3 py-2 font-title"
                            style={{ borderColor: color }}
                          />
                          <div className="flex gap-2">
                            <button 
                              onClick={() => confirmFix(wIdx)} 
                              className="touch-target flex-1 text-white font-title font-bold px-4 py-2 rounded-lg"
                              style={{ backgroundColor: color }}
                            >
                              Confirmar inicio
                            </button>
                            <button 
                              onClick={() => setShowStartInput(null)} 
                              className="touch-target flex-1 border-2 rounded-lg py-2 font-medium"
                              style={{ borderColor: color, color }}
                            >
                              Cancelar
                            </button>
                          </div>
                        </div>
                      ) : (
                        <button 
                          onClick={() => handleFixClick(wIdx)} 
                          className="touch-target w-full text-white font-title font-bold px-4 py-2 rounded-lg"
                          style={{ backgroundColor: color }}
                        >
                          Fijar Ventana {wIdx + 1}
                        </button>
                      )
                    ) : (
                      <div className="flex gap-2">
                        <div className="flex-1 text-center py-2 font-title font-bold rounded-lg" style={{ color, backgroundColor: `${color}15` }}>
                          ✓ Ventana fijada correctamente
                        </div>
                        <button
                          onClick={() => handleCreateFair(wIdx)}
                          className="touch-target flex-1 text-white font-title font-bold px-4 py-2 rounded-lg"
                          style={{ backgroundColor: color }}
                        >
                          + CREAR FERIA
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {canExport && (
            <button 
              onClick={handleExportPDF}
              disabled={exporting}
              className="touch-target w-full bg-expocad-primary hover:opacity-90 text-white font-title font-bold px-5 py-3 rounded-xl shadow-card disabled:opacity-50"
            >
              {exporting ? 'Generando PDF...' : '📄 Exportar a PDF'}
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
    </div>
  );
};
EOF

echo "✓ VerificationView: botón CREAR FERIA añadido"

# ---------------------------------------------------------
# 4. ACTUALIZAR FAIRSVIEW - Botón VERIFICAR + detectar pendingFair
# ---------------------------------------------------------
cat << 'EOF' > src/views/FairsView.tsx
import React, { useState, useEffect } from 'react';
import { useStore } from '../state/store';
import { Fair, checkConflicts, getFairPhases } from '../lib/validation';
import { formatDate } from '../lib/dates';

export const FairsView = () => {
  const { fairs, setFairs, pavilions, selectedYear, resetToSeed, pendingFair, setPendingFair } = useStore();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  const emptyFair: Partial<Fair> = {
    nombre: '', sector: '', color: '#3F6B4A', fechaInicioMontaje: `${selectedYear}-03-01`,
    diasMontaje: 3, diasFeria: 5, diasDesmontaje: 2, pabellonIds: []
  };
  const [form, setForm] = useState<Partial<Fair>>(emptyFair);
  const [validation, setValidation] = useState<any>(null);

  // Detectar pendingFair al montar o cuando cambie
  useEffect(() => {
    if (pendingFair) {
      setForm({
        nombre: pendingFair.nombre,
        sector: pendingFair.sector,
        color: pendingFair.color,
        fechaInicioMontaje: pendingFair.fechaInicioMontaje,
        diasMontaje: pendingFair.diasMontaje,
        diasFeria: pendingFair.diasFeria,
        diasDesmontaje: pendingFair.diasDesmontaje,
        pabellonIds: pendingFair.pabellonIds
      });
      setShowForm(true);
      setEditingId(null);
      setValidation(null);
      setPendingFair(null);
    }
  }, [pendingFair]);

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

  const colorOptions = ['#3F6B4A', '#E8842C', '#4682B4', '#8A2BE2', '#FF6347', '#F5C518', '#DC143C', '#00CED1', '#FF1493', '#7FFF00'];

  const goToVerification = () => {
    window.dispatchEvent(new CustomEvent('changeTab', { detail: 'verificacion' }));
  };

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
        <div className="bg-white p-5 rounded-xl shadow-card space-y-4 border-2 border-expocad-accent">
          <div className="flex items-center justify-between">
            <h3 className="font-title text-lg font-bold text-expocad-dark">{editingId ? 'Editar' : 'Nueva'} feria</h3>
            {!editingId && (
              <button 
                onClick={goToVerification}
                className="touch-target px-4 py-2 bg-expocad-accent text-white rounded-lg font-title font-bold hover:opacity-90 text-sm flex items-center gap-2"
              >
                <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 12l2 2 4-4m6 2a9 9 0 1 1-18 0 9 9 0 0 1 18 0z" />
                </svg>
                VERIFICAR DISPONIBILIDAD
              </button>
            )}
          </div>

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
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">Pabellones * ({form.pabellonIds?.length || 0} seleccionados)</label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-expocad-line rounded-lg p-2">
              {pavilions.map(p => (
                <label key={p.id} className="flex items-center gap-2 touch-target">
                  <input type="checkbox" checked={form.pabellonIds?.includes(p.id)} onChange={e => {
                    const ids = form.pabellonIds || [];
                    setForm({ ...form, pabellonIds: e.target.checked ? [...ids, p.id] : ids.filter(id => id !== p.id) });
                  }} />
                  <span className="text-sm">{p.nombre} ({p.m2.toLocaleString()} m², {p.tipo})</span>
                </label>
              ))}
            </div>
          </div>

          {validation && validation.hasConflict && (
            <div className="bg-expocad-accent/10 border border-expocad-accent p-3 rounded-lg text-sm">
              <p className="font-bold mb-1 text-expocad-dark"> Conflicto detectado:</p>
              {validation.conflicts.map((c: any, i: number) => (
                <p key={i} className="text-expocad-dark">Choca con «{c.fairNombre}» en {c.pabellonNombre}. Días pisados: {c.fechasPisadas.join(', ')}. Primera fecha disponible: {formatDate(c.primeraFechaDisponible)}</p>
              ))}
            </div>
          )}

          <div className="flex gap-2 pt-2">
            <button onClick={handleSave} className="touch-target flex-1 bg-expocad-primary text-white rounded-lg py-2 font-medium">Guardar</button>
            <button onClick={() => { setShowForm(false); setValidation(null); setPendingFair(null); }} className="touch-target flex-1 border border-expocad-line rounded-lg py-2 font-medium">Cancelar</button>
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

echo "✓ FairsView: botón VERIFICAR + detección de pendingFair"

echo ""
echo "✅ Cambios aplicados:"
echo "   1. App.tsx: listener para cambio de pestaña desde vistas hijas"
echo "   2. Store: añadido pendingFair para transferir datos entre vistas"
echo "   3. VerificationView: botón 'CREAR FERIA' en ventanas fijadas"
echo "   4. FairsView: botón 'VERIFICAR DISPONIBILIDAD' + auto-apertura con datos"
echo ""
echo "🔄 Recarga el navegador (Ctrl+R)"
