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
