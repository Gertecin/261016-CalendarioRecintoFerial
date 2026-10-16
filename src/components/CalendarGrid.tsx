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
  const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

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
          <div key={d} className="px-2 py-2 text-center font-title font-semibold text-xs tracking-wider">{d}</div>
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
                if (!dateStr) return <div key={dIdx} className={`border-r border-expocad-line bg-expocad-bg/40 ${compact ? 'h-10' : 'h-14 sm:h-16'}`} />;
                const month = new Date(dateStr + 'T12:00:00Z').getUTCMonth();
                const bgMonth = month % 2 === 0 ? 'bg-expocad-month1' : 'bg-expocad-month2';
                const dayFairs = getFairsForDay(dateStr);
                const highlight = isHighlighted(dateStr);
                const freeM2 = getFreeM2ForDay ? getFreeM2ForDay(dateStr) : 0;
                const isFullyOccupied = freeM2 === 0;
                const freePercent = totalM2 > 0 ? Math.round((freeM2 / totalM2) * 100) : 0;
                const hasOccupation = dayFairs.length > 0;

                return (
                  <div
                    key={dateStr}
                    onClick={() => onDayClick?.(dateStr)}
                    className={`relative border-r border-expocad-line p-1 transition-colors ${isFullyOccupied ? 'bg-gray-300 opacity-60' : bgMonth} ${onDayClick ? 'cursor-pointer hover:ring-2 hover:ring-expocad-accent hover:ring-inset' : ''}`}
                    style={highlight ? { boxShadow: `inset 0 0 0 2px ${highlight.color}` } : undefined}
                  >
                    <div className="flex justify-between items-start">
                      <span className="font-title font-bold text-sm sm:text-base text-expocad-dark leading-none">
                        {new Date(dateStr + 'T12:00:00Z').getUTCDate()}
                      </span>
                      {hasOccupation && (
                        <span className="font-title font-bold text-sm sm:text-base text-expocad-primary leading-none">
                          {freePercent}%
                        </span>
                      )}
                    </div>

                    {dayFairs.length > 0 && (
                      <div className="space-y-px mt-1">
                        {dayFairs.slice(0, 3).map(({ fair }) => (
                          <div
                            key={fair.id}
                            className="h-2 sm:h-2.5 rounded"
                            style={{ backgroundColor: fair.color }}
                            title={fair.nombre}
                          />
                        ))}
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
