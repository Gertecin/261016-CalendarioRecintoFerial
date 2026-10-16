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
