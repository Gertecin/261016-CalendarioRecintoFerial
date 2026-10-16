#!/bin/bash
set -e

echo "🔧 Ajustando Verificación (colores por ventana + input inicio) y Ocupación (altura + amarillo)..."

# ---------------------------------------------------------
# 1. VERIFICACIÓN: colores distintos por ventana, input de inicio, sombreado intenso
# ---------------------------------------------------------
cat << 'EOF' > src/views/VerificationView.tsx
import React, { useState, useRef } from 'react';
import { useStore } from '../state/store';
import { findConnectedPavilionCombinations, WindowOption, getFairPhases } from '../lib/validation';
import { formatDate, MONTH_NAMES, addDays, diffDays } from '../lib/dates';
import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';

// Colores distintos para cada ventana (marco + botón + sombreado)
const WINDOW_COLORS = ['#E8842C', '#4682B4', '#8A2BE2'];

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
      alert('Elija una ventana');
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
    // Validar que la fecha esté dentro de la ventana
    const win = windows[windowIdx];
    if (startInputValue < win.start || startInputValue > win.end) {
      alert(`La fecha debe estar entre ${formatDate(win.start)} y ${formatDate(win.end)}`);
      return;
    }
    // Validar que quepa la duración total
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
                        
                        // Buscar si este día está en una ventana FIJADA (sombreado intenso)
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
                        
                        // Borde sutil para días dentro de cualquier ventana no fijada
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
                      <div className="text-center py-2 font-title font-bold" style={{ color }}>
                        ✓ Ventana fijada correctamente
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

echo "✓ VerificationView: colores por ventana + input inicio + sombreado intenso"

# ---------------------------------------------------------
# 2. OCUPACIÓN: altura reducida + amarillo para cerrado
# ---------------------------------------------------------
cat << 'EOF' > src/views/OccupancyView.tsx
import React from 'react';
import { useStore } from '../state/store';
import { getFairPhases, getAvailablePavilionsByTypeForDay } from '../lib/validation';
import { MONTH_NAMES, addDays } from '../lib/dates';

const TIPO_COLORS: Record<string, string> = {
  'cerrado': '#F5C518',      // Amarillo
  'semicubierto': '#E8842C',  // Naranja
  'aire libre': '#4682B4',    // Azul
  'playón': '#8A2BE2',        // Violeta
  'salón': '#FF6347'          // Tomate
};

const TIPO_LIGHT_COLORS: Record<string, string> = {
  'cerrado': '#FFF3B0',
  'semicubierto': '#F5D5B5',
  'aire libre': '#B8D4E8',
  'playón': '#D5C5F0',
  'salón': '#FFD5CC'
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

  const getDayOccupiedByType = (year: number, month: number, day: number) => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const result: Record<string, { occupied: number; total: number }> = {};
    
    tipos.forEach(tipo => {
      const pavilionsOfType = pavilions.filter(p => p.tipo === tipo);
      result[tipo] = { occupied: 0, total: pavilionsOfType.length };
    });

    fairs.forEach(f => {
      const p = getFairPhases(f);
      if (dateStr >= p.inicioMontaje && dateStr <= p.finOcupacion) {
        f.pabellonIds.forEach(pid => {
          const pav = pavilions.find(p => p.id === pid);
          if (pav && result[pav.tipo]) {
            result[pav.tipo].occupied++;
          }
        });
      }
    });

    return result;
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

      {/* Gráfico anular */}
      <div className="bg-white rounded-xl shadow-card p-5">
        <h3 className="font-title font-bold text-expocad-dark mb-4">Ocupación anual por tipo de pabellón</h3>
        <div className="flex flex-wrap justify-around gap-8">
          {occupancyByTipo.map((item) => {
            const percentage = parseFloat(item.percentage);
            const radius = 70;
            const strokeWidth = 20;
            const circumference = 2 * Math.PI * radius;
            const strokeDashoffset = circumference - (percentage / 100) * circumference;
            const color = TIPO_COLORS[item.tipo] || '#F5C518';
            const lightColor = TIPO_LIGHT_COLORS[item.tipo] || '#FFF3B0';

            return (
              <div key={item.tipo} className="flex flex-col items-center flex-1 min-w-[160px]">
                <svg width="200" height="200" className="transform -rotate-90">
                  <circle cx="100" cy="100" r={radius} stroke={lightColor} strokeWidth={strokeWidth} fill="none" />
                  <circle
                    cx="100"
                    cy="100"
                    r={radius}
                    stroke={color}
                    strokeWidth={strokeWidth}
                    fill="none"
                    strokeDasharray={circumference}
                    strokeDashoffset={strokeDashoffset}
                    strokeLinecap="round"
                  />
                  <text x="100" y="100" textAnchor="middle" dominantBaseline="central" className="transform rotate-90 origin-center" style={{ fontSize: '24px', fontWeight: 'bold', fill: '#1D2E20' }}>
                    {item.percentage}%
                  </text>
                </svg>
                <div className="mt-2 text-center">
                  <div className="font-title font-bold text-expocad-dark capitalize text-base">{item.tipo}</div>
                  <div className="text-sm text-expocad-muted">{item.occupiedDays} días</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Calendario unificado */}
      <div className="bg-white rounded-xl shadow-card p-4">
        <h3 className="font-title font-bold text-expocad-dark mb-3">Calendario de ocupación {selectedYear}</h3>
        
        <div className="overflow-x-auto">
          <div className="min-w-[800px]">
            <div className="grid grid-cols-[50px_repeat(31,1fr)] gap-px mb-1">
              <div className="text-[10px] font-bold text-expocad-muted">Mes</div>
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
                    if (day > daysInMonth) return <div key={dayIdx} className="bg-gray-100 h-10" />;
                    const dow = getDayOfWeek(selectedYear, monthIdx, day);
                    const occupiedByType = getDayOccupiedByType(selectedYear, monthIdx, day);
                    const isSaturday = dow === 6;
                    const isSunday = dow === 0;
                    
                    let bgColor = 'bg-white';
                    if (isSunday) bgColor = 'bg-expocad-primary/15';
                    else if (isSaturday) bgColor = 'bg-expocad-primary/5';
                    
                    const occupiedTypes = tipos.filter(t => occupiedByType[t].occupied > 0);
                    
                    if (occupiedTypes.length === 0) {
                      return <div key={dayIdx} className={`h-10 rounded-sm ${bgColor}`} />;
                    }
                    
                    const stripeHeight = 100 / occupiedTypes.length;
                    return (
                      <div key={dayIdx} className="h-10 rounded-sm overflow-hidden flex flex-col" title={occupiedTypes.map(t => `${t}: ${occupiedByType[t].occupied}/${occupiedByType[t].total}`).join('\n')}>
                        {occupiedTypes.map(tipo => {
                          const { occupied, total } = occupiedByType[tipo];
                          const opacity = 0.4 + (occupied / total) * 0.6;
                          return (
                            <div 
                              key={tipo}
                              className="flex-1"
                              style={{ 
                                backgroundColor: TIPO_COLORS[tipo], 
                                opacity,
                                height: `${stripeHeight}%`
                              }}
                            />
                          );
                        })}
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
EOF

echo "✓ OccupancyView: altura h-10 + amarillo para cerrado"

echo ""
echo "✅ Correcciones aplicadas"
echo "🔄 Recarga el navegador (Ctrl+R)"
