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
