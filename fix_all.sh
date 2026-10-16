#!/bin/bash
set -e

echo "🔧 Corrigiendo Verificación, Colores, Ocupación y Pabellones..."

# ---------------------------------------------------------
# 1. CORREGIR VERIFICATIONVIEW - Import correcto + lógica
# ---------------------------------------------------------
cat << 'EOF' > src/views/VerificationView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { findConnectedPavilionCombinations, WindowOption, getFairPhases } from '../lib/validation';
import { formatDate, MONTH_NAMES } from '../lib/dates';

const FAIR_COLORS = [
  '#FF00FF', '#00FFFF', '#FFFF00', '#FF1493', '#00FF7F',
  '#FF4500', '#9400D3', '#FFD700', '#00CED1', '#FF69B4',
  '#7FFF00', '#FF6347', '#4169E1', '#32CD32', '#FF8C00',
  '#DC143C', '#00BFFF', '#8A2BE2', '#00FA9A', '#FF1493'
];

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
                        
                        if (fair) {
                          return <div key={dayIdx} className="h-8 rounded-sm" style={{ backgroundColor: fair.color }} title={fair.nombre} />;
                        }
                        return <div key={dayIdx} className={`h-8 rounded-sm ${bgColor}`} />;
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
                const isFixed = fixedOptions.has(wIdx);

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
               Exportar a PDF
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
EOF

echo "✓ VerificationView corregido"

# ---------------------------------------------------------
# 2. CORREGIR CALENDARVIEW - Sin distinción de fases, colores sólidos
# ---------------------------------------------------------
cat << 'EOF' > src/views/CalendarView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { CalendarGrid } from '../components/CalendarGrid';
import { getFairPhases, getFreeM2ForDay } from '../lib/validation';
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
    fairs: fairs.filter(f => {
      const p = getFairPhases(f);
      return selectedDay >= p.inicioMontaje && selectedDay <= p.finOcupacion;
    })
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
            <input type="number" value={selectedYear} onChange={e => setSelectedYear(Math.min(2200, Math.max(1900, Number(e.target.value) || selectedYear)))} className="w-24 text-center font-title font-bold text-2xl border border-expocad-line rounded-lg py-1" min="1900" max="2200" />
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
                  <div className="absolute bottom-0 w-full bg-expocad-primary rounded-t-lg transition-all" style={{ height: `${height}%` }} />
                </div>
                <div className="text-[10px] text-expocad-muted mt-2 text-center truncate w-full" title={p.nombre}>{p.nombre.split(' ').slice(0, 2).join(' ')}</div>
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
                <div className="w-16 h-16 mx-auto rounded-full bg-expocad-bg flex items-center justify-center mb-3"><span className="text-2xl">🟢</span></div>
                <p className="font-title font-bold text-lg text-expocad-primary">Día libre en todos los pabellones</p>
              </div>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-expocad-muted">{dayDetail.fairs.length} {dayDetail.fairs.length === 1 ? 'feria activa' : 'ferias activas'} en el recinto.</p>
                {dayDetail.fairs.map(f => {
                  const p = getFairPhases(f);
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
                        <span className="text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded" style={{ backgroundColor: f.color, color: 'white' }}>ACTIVA</span>
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

echo "✓ CalendarView corregido"

# ---------------------------------------------------------
# 3. CORREGIR CALENDARGRID - Sin distinción de fases, un solo color sólido
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
  const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

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
          <div key={d} className="px-2 py-2 text-center font-title font-semibold text-[10px] sm:text-xs tracking-wider">{d.toUpperCase()}</div>
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
                      <div className="text-[8px] sm:text-[10px] text-expocad-muted font-medium mb-0.5">Libre: {freePercent}%</div>
                    )}

                    {dayFairs.length === 0 ? (
                      !isFullyOccupied && <div className="text-[8px] sm:text-[10px] text-expocad-muted font-medium italic opacity-60 mt-0.5">LIBRE</div>
                    ) : (
                      <div className="space-y-px">
                        {dayFairs.slice(0, compact ? 2 : 3).map(({ fair }) => {
                          const fairM2 = fair.pabellonIds.reduce((sum, pid) => {
                            const pav = pavilions.find(p => p.id === pid);
                            return sum + (pav?.m2 || 0);
                          }, 0);
                          const percentOfRecinto = totalM2 > 0 ? ((fairM2 / totalM2) * 100).toFixed(1) : '0';
                          return (
                            <div
                              key={fair.id}
                              className="h-2 sm:h-3 rounded"
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

echo "✓ CalendarGrid corregido (sin fases, color sólido)"

# ---------------------------------------------------------
# 4. CORREGIR OCCUPANCYVIEW - Anillos grandes, 5 calendarios juntos
# ---------------------------------------------------------
cat << 'EOF' > src/views/OccupancyView.tsx
import React, { useState } from 'react';
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

      {/* Gráfico anular - anillos grandes distribuidos al ancho */}
      <div className="bg-white rounded-xl shadow-card p-5">
        <h3 className="font-title font-bold text-expocad-dark mb-4">Ocupación anual por tipo de pabellón</h3>
        <div className="flex flex-wrap justify-around gap-6">
          {occupancyByTipo.map((item, idx) => {
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
                  <div className="text-xs text-expocad-muted">{item.occupiedDays} días ocupados</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Calendarios Gantt - 5 tipos juntos, 2 por fila */}
      <div className="space-y-4">
        {tipos.map(tipo => {
          const color = TIPO_COLORS[tipo] || '#3F6B4A';
          const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
          const today = new Date();
          const todayStr = today.toISOString().split('T')[0];
          const availableToday = getAvailablePavilionsByTypeForDay(todayStr, fairs, pavilions, tipo);
          const todayM2 = availableToday.reduce((sum, p) => sum + p.m2, 0);
          const dayOfMonth = today.getUTCDate();

          return (
            <div key={tipo} className="bg-white rounded-xl shadow-card p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-4 h-4 rounded" style={{ backgroundColor: color }} />
                  <h3 className="font-title font-bold text-expocad-dark capitalize">{tipo}</h3>
                  <span className="text-xs text-expocad-muted">({pavilionsOfType.length} pabellones · {todayM2.toLocaleString()} m² disponibles hoy)</span>
                </div>
                <div className="text-xs text-expocad-muted">
                  <span className="font-semibold">{availableToday.length}</span> DISPONIBLES · Día <span className="font-bold">{dayOfMonth}</span> · TOTAL <span className="font-bold">{todayM2.toLocaleString()}</span> m²
                </div>
              </div>
              
              <div className="overflow-x-auto">
                <div className="min-w-[700px]">
                  <div className="grid grid-cols-[50px_repeat(31,1fr)] gap-px mb-1">
                    <div className="text-[10px] font-bold text-expocad-muted">Día</div>
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
                          if (day > daysInMonth) return <div key={dayIdx} className="bg-gray-100 h-6" />;
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
                                className="h-6 rounded-sm flex items-center justify-center text-[8px] font-bold text-white"
                                style={{ backgroundColor: color, opacity }}
                                title={`${occupied}/${total} pabellones ocupados`}
                              >
                                {occupied}
                              </div>
                            );
                          }
                          
                          return <div key={dayIdx} className={`h-6 rounded-sm ${bgColor}`} />;
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

echo "✓ OccupancyView corregido (anillos grandes + 5 calendarios juntos)"

# ---------------------------------------------------------
# 5. CORREGIR PAVILIONSVIEW - Mostrar vecinos al crear
# ---------------------------------------------------------
cat << 'EOF' > src/views/PavilionsView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { Pavilion } from '../lib/validation';

export const PavilionsView = () => {
  const { pavilions, setPavilions, fairs } = useStore();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<Partial<Pavilion>>({ nombre: '', m2: 0, tipo: 'cerrado', vecinos: [], tieneParedExterior: true });
  const [validationError, setValidationError] = useState<string>('');

  const handleSave = () => {
    if (!form.nombre || !form.m2) {
      setValidationError('Nombre y m² son obligatorios');
      return;
    }

    const maxVecinos = form.tipo === 'aire libre' ? 4 : 3;
    if ((form.vecinos?.length || 0) > maxVecinos) {
      setValidationError(`Un pabellón ${form.tipo} no puede tener más de ${maxVecinos} vecinos`);
      return;
    }

    setValidationError('');
    const newP: Pavilion = {
      id: editingId || `p${Date.now()}`,
      nombre: form.nombre,
      m2: form.m2,
      tipo: form.tipo as any,
      vecinos: form.vecinos || [],
      tieneParedExterior: form.tieneParedExterior ?? true
    };

    if (editingId) setPavilions(pavilions.map(p => p.id === editingId ? newP : p));
    else setPavilions([...pavilions, newP]);
    setShowForm(false); setEditingId(null); setForm({ nombre: '', m2: 0, tipo: 'cerrado', vecinos: [], tieneParedExterior: true });
  };

  const handleDelete = (id: string) => {
    const hasFairs = fairs.some(f => f.pabellonIds.includes(id));
    if (hasFairs) {
      alert('No se puede eliminar: este pabellón tiene ferias asignadas.');
      return;
    }
    if (confirm('¿Eliminar este pabellón?')) setPavilions(pavilions.filter(p => p.id !== id));
  };

  const handleVecinoChange = (vecinoId: string) => {
    const current = form.vecinos || [];
    const maxVecinos = form.tipo === 'aire libre' ? 4 : 3;
    
    if (current.includes(vecinoId)) {
      setForm({ ...form, vecinos: current.filter(id => id !== vecinoId) });
    } else {
      if (current.length >= maxVecinos) {
        setValidationError(`No puede añadir más de ${maxVecinos} vecinos`);
        return;
      }
      setForm({ ...form, vecinos: [...current, vecinoId] });
    }
    setValidationError('');
  };

  // CORRECCIÓN: Mostrar todos los pabellones excepto el que se está editando
  const availableNeighbors = pavilions.filter(p => p.id !== editingId);

  return (
    <div className="space-y-5">
      <div className="flex justify-between items-center">
        <h2 className="font-title text-2xl sm:text-3xl font-bold text-expocad-dark">Catálogo de pabellones</h2>
        <button onClick={() => { setShowForm(true); setEditingId(null); setForm({ nombre: '', m2: 0, tipo: 'cerrado', vecinos: [], tieneParedExterior: true }); setValidationError(''); }} className="touch-target px-4 py-2 bg-expocad-primary text-white rounded-lg font-medium hover:opacity-90 text-sm">+ Nuevo pabellón</button>
      </div>

      {showForm && (
        <div className="bg-white p-5 rounded-xl shadow-card space-y-4 border border-expocad-line">
          <h3 className="font-title text-lg font-bold">{editingId ? 'Editar' : 'Nuevo'} pabellón</h3>
          
          {validationError && (
            <div className="bg-expocad-accent/10 border border-expocad-accent p-3 rounded-lg text-sm text-expocad-dark">
               {validationError}
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Nombre *</label><input className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} /></div>
            <div><label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Superficie (m²) *</label><input type="number" className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.m2} onChange={e => setForm({ ...form, m2: Number(e.target.value) })} /></div>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-1">Tipo *</label>
              <select className="w-full border border-expocad-line rounded-lg p-2 touch-target" value={form.tipo} onChange={e => setForm({ ...form, tipo: e.target.value as any, vecinos: [] })}>
                <option value="cerrado">Cerrado</option>
                <option value="semicubierto">Semicubierto</option>
                <option value="aire libre">Aire Libre</option>
                <option value="playón">Playón</option>
                <option value="salón">Salón</option>
              </select>
            </div>
            <div className="flex items-end">
              <label className="flex items-center gap-2 touch-target">
                <input type="checkbox" checked={form.tieneParedExterior} onChange={e => setForm({ ...form, tieneParedExterior: e.target.checked })} />
                <span className="text-sm">Tiene pared exterior</span>
              </label>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-expocad-muted mb-2">
              Vecinos (máx: {form.tipo === 'aire libre' ? 4 : 3}) - Seleccionados: {form.vecinos?.length || 0}
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-expocad-line rounded-lg p-2">
              {availableNeighbors.map(p => (
                <label key={p.id} className="flex items-center gap-2 touch-target">
                  <input type="checkbox" checked={form.vecinos?.includes(p.id)} onChange={() => handleVecinoChange(p.id)} />
                  <span className="text-sm">{p.nombre} ({p.m2}m², {p.tipo})</span>
                </label>
              ))}
            </div>
          </div>

          <div className="flex gap-2">
            <button onClick={handleSave} className="touch-target flex-1 bg-expocad-primary text-white rounded-lg py-2 font-medium">Guardar</button>
            <button onClick={() => { setShowForm(false); setValidationError(''); }} className="touch-target flex-1 border border-expocad-line rounded-lg py-2 font-medium">Cancelar</button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead className="bg-expocad-dark text-white font-title">
              <tr>
                <th className="p-3">Nombre</th>
                <th className="p-3 text-right">m²</th>
                <th className="p-3">Tipo</th>
                <th className="p-3 text-center">Vecinos</th>
                <th className="p-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-expocad-line">
              {pavilions.map(p => (
                <tr key={p.id} className="hover:bg-expocad-bg/60">
                  <td className="p-3 font-medium">{p.nombre}</td>
                  <td className="p-3 text-right">{p.m2.toLocaleString()}</td>
                  <td className="p-3 capitalize text-expocad-muted">{p.tipo}</td>
                  <td className="p-3 text-center">{p.vecinos.length}</td>
                  <td className="p-3 text-right space-x-2">
                    <button onClick={() => { setForm(p); setEditingId(p.id); setShowForm(true); setValidationError(''); }} className="text-expocad-primary hover:underline text-xs">Editar</button>
                    <button onClick={() => handleDelete(p.id)} className="text-expocad-accent hover:underline font-medium text-xs">Eliminar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
EOF

echo "✓ PavilionsView corregido (vecinos visibles al crear)"

echo ""
echo "✅ Todas las correcciones aplicadas"
echo "🔄 Recarga el navegador (Ctrl+R) para ver los cambios"
