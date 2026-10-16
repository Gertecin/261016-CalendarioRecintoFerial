#!/bin/bash
set -e

echo "🚀 Completando vistas del Recinto Ferial Cruceño v3..."

# ---------------------------------------------------------
# 1. ELIMINAR LEYENDA DE CALENDARIO
# ---------------------------------------------------------
sed -i '/<div className="bg-white rounded-xl shadow-card p-4 flex flex-wrap gap-x-4 gap-y-2 items-center text-sm">/,/<\/div>/d' src/views/CalendarView.tsx
echo "✓ Leyenda eliminada"

# ---------------------------------------------------------
# 2. VISTA VERIFICACIÓN COMPLETA
# ---------------------------------------------------------
cat << 'VIEWEOF' > src/views/VerificationView.tsx
import React, { useState, useMemo } from 'react';
import { useStore } from '../state/store';
import { findConnectedPavilionCombinations, WindowOption, PavilionCombination } from '../lib/validation';
import { formatDate, MONTH_NAMES, addDays, generateSpanGrid } from '../lib/dates';
import { CalendarGrid } from '../components/CalendarGrid';

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
            <h3 className="font-title text-xl font-bold text-expocad-dark mb-4">Ventanas disponibles</h3>
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
VIEWEOF

echo "✓ Vista Verificación creada"

# ---------------------------------------------------------
# 3. VISTA FERIAS COMPLETA
# ---------------------------------------------------------
cat << 'VIEWEOF' > src/views/FairsView.tsx
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
    nombre: '', sector: '', color: '#3F6B4A', fechaInicioMontaje: `${selectedYear}-03-01`,
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
                    <td className="p-3 font-medium"><div className="flex items-center gap-2"><span className="w-3 h-3 rounded-sm" style={{ backgroundColor: f.color }}></span>{f.nombre}</div></td>
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
VIEWEOF

echo "✓ Vista Ferias creada"

# ---------------------------------------------------------
# 4. VISTA OCUPACIÓN COMPLETA
# ---------------------------------------------------------
cat << 'VIEWEOF' > src/views/OccupancyView.tsx
import React, { useState } from 'react';
import { useStore } from '../state/store';
import { getAvailablePavilionsByTypeForDay, getFairPhases } from '../lib/validation';
import { formatDate, MONTH_NAMES, generateYearGrid } from '../lib/dates';
import { CalendarGrid } from '../components/CalendarGrid';

export const OccupancyView = () => {
  const { selectedYear, setSelectedYear, pavilions, fairs } = useStore();
  const [selectedTipo, setSelectedTipo] = useState<string | null>(null);
  const [showGlobe, setShowGlobe] = useState<string | null>(null);

  const tipos = [...new Set(pavilions.map(p => p.tipo))];
  const totalM2 = pavilions.reduce((sum, p) => sum + p.m2, 0);

  const getStatsForTipo = (tipo: string) => {
    const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
    const totalPavM2 = pavilionsOfType.reduce((sum, p) => sum + p.m2, 0);
    const yearStart = `${selectedYear}-01-01`;
    const yearEnd = `${selectedYear}-12-31`;
    const totalDays = (selectedYear % 4 === 0 && selectedYear % 100 !== 0) || selectedYear % 400 === 0 ? 366 : 365;

    let occupiedDays = 0;
    for (let d = 0; d < totalDays; d++) {
      const date = new Date(yearStart);
      date.setUTCDate(date.getUTCDate() + d);
      const dateStr = date.toISOString().split('T')[0];
      const available = getAvailablePavilionsByTypeForDay(dateStr, fairs, pavilions, tipo);
      if (available.length < pavilionsOfType.length) occupiedDays++;
    }

    return {
      totalPavilions: pavilionsOfType.length,
      totalM2: totalPavM2,
      occupiedDays,
      percentage: ((occupiedDays / totalDays) * 100).toFixed(1)
    };
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
            <h3 className="font-title text-lg font-bold text-expocad-dark">Detalle: {selectedTipo}</h3>
            <button onClick={() => setSelectedTipo(null)} className="text-expocad-muted hover:text-expocad-dark text-sm">← Volver</button>
          </div>
          <p className="text-sm text-expocad-muted mb-4">Se muestran el nº de pabellones <strong>{selectedTipo.toUpperCase()}</strong> y el total de m² disponibles</p>
          <CalendarGrid year={selectedYear} fairs={fairs} pavilions={pavilions.filter(p => p.tipo === selectedTipo)} compact />
        </div>
      )}

      {!selectedTipo && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {tipos.map(tipo => {
            const stats = getStatsForTipo(tipo);
            const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
            const today = new Date().toISOString().split('T')[0];
            const availableToday = getAvailablePavilionsByTypeForDay(today, fairs, pavilions, tipo);
            const todayM2 = availableToday.reduce((sum, p) => sum + p.m2, 0);
            const dayOfMonth = new Date().getUTCDate();

            return (
              <div key={tipo} className="relative">
                <div
                  onClick={() => setShowGlobe(showGlobe === tipo ? null : tipo)}
                  className="bg-white rounded-xl shadow-card p-5 cursor-pointer hover:shadow-elevated transition-shadow border-2 border-transparent hover:border-expocad-primary"
                >
                  <div className="text-xs text-expocad-muted font-medium uppercase tracking-wider mb-1">{availableToday.length} DISPONIBLES</div>
                  <div className="font-title font-bold text-5xl text-expocad-dark my-3">{dayOfMonth}</div>
                  <div className="text-sm text-expocad-muted">TOTAL <span className="font-bold text-expocad-dark">{todayM2.toLocaleString()}</span> m²</div>
                </div>

                {showGlobe === tipo && (
                  <div className="fixed inset-0 bg-expocad-dark/60 z-50 flex items-center justify-center p-4" onClick={() => setShowGlobe(null)}>
                    <div className="bg-white rounded-xl p-6 max-w-sm w-full" onClick={e => e.stopPropagation()}>
                      <h4 className="font-title text-xl font-bold text-expocad-dark mb-3 capitalize">{tipo}</h4>
                      <div className="space-y-2 text-sm mb-4">
                        <div className="flex justify-between"><span className="text-expocad-muted">Pabellones:</span><span className="font-bold">{stats.totalPavilions}</span></div>
                        <div className="flex justify-between"><span className="text-expocad-muted">Capacidad total:</span><span className="font-bold">{stats.totalM2.toLocaleString()} m²</span></div>
                        <div className="flex justify-between"><span className="text-expocad-muted">Días ocupados:</span><span className="font-bold">{stats.occupiedDays}</span></div>
                        <div className="flex justify-between"><span className="text-expocad-muted">Ocupación anual:</span><span className="font-bold text-expocad-primary">{stats.percentage}%</span></div>
                      </div>
                      <button onClick={() => { setSelectedTipo(tipo); setShowGlobe(null); }} className="touch-target w-full bg-expocad-primary text-white rounded-lg py-2 font-medium">
                        Toca para ir al detalle
                      </button>
                      <p className="text-xs text-expocad-muted text-center mt-2">o fuera del globo para volver</p>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
VIEWEOF

echo "✓ Vista Ocupación creada"

# ---------------------------------------------------------
# 5. VISTA PABELLONES COMPLETA
# ---------------------------------------------------------
cat << 'VIEWEOF' > src/views/PavilionsView.tsx
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
              ⚠ {validationError}
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
              Vecinos (máx: {form.tipo === 'aire libre' ? 4 : 3})
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-expocad-line rounded-lg p-2">
              {pavilions.filter(p => p.id !== editingId).map(p => (
                <label key={p.id} className="flex items-center gap-2 touch-target">
                  <input type="checkbox" checked={form.vecinos?.includes(p.id)} onChange={() => handleVecinoChange(p.id)} />
                  <span className="text-sm">{p.nombre}</span>
                </label>
              ))}
            </div>
            <p className="text-xs text-expocad-muted mt-1">Seleccionados: {form.vecinos?.length || 0}</p>
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
VIEWEOF

echo "✓ Vista Pabellones creada"

echo ""
echo "✅ Todas las vistas creadas exitosamente"
echo " La app está lista. Recarga el navegador para ver los cambios."
