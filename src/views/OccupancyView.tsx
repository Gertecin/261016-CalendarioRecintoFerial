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
