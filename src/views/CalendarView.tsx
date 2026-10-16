import React, { useState } from 'react';
import { useStore } from '../state/store';
import { CalendarGrid } from '../components/CalendarGrid';
import { getFairPhases, getFreeM2ForDay } from '../lib/validation';
import { formatDate, MONTH_NAMES, addDays } from '../lib/dates';

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
      cur = addDays(cur, 1);
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
        cur = addDays(cur, 1);
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
