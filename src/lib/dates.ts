export const LIMPIEZA_DIAS = 1;

export const isLeapYear = (year: number): boolean =>
  (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;

export const getDaysInYear = (year: number): number => (isLeapYear(year) ? 366 : 365);

export const addDays = (dateStr: string, days: number): string => {
  const date = new Date(dateStr + 'T12:00:00Z');
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().split('T')[0];
};

export const diffDays = (from: string, to: string): number => {
  const a = new Date(from + 'T12:00:00Z');
  const b = new Date(to + 'T12:00:00Z');
  return Math.round((b.getTime() - a.getTime()) / (1000 * 60 * 60 * 24));
};

export const formatDate = (dateStr: string): string => {
  const [y, m, d] = dateStr.split('-');
  return `${d}/${m}/${y}`;
};

export const getDayOfWeek = (dateStr: string): number => {
  const date = new Date(dateStr + 'T12:00:00Z');
  return date.getUTCDay();
};

export const getMonthIndex = (dateStr: string): number =>
  new Date(dateStr + 'T12:00:00Z').getUTCMonth();

export const MONTH_NAMES = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

export const generateYearGrid = (year: number): (string | null)[][] => {
  const weeks: (string | null)[][] = [];
  const firstDay = `${year}-01-01`;
  const dow = getDayOfWeek(firstDay);
  const padding = dow === 0 ? 6 : dow - 1;

  let currentWeek: (string | null)[] = Array(padding).fill(null);
  const current = new Date(`${year}-01-01T12:00:00Z`);
  const daysInYear = getDaysInYear(year);

  for (let i = 0; i < daysInYear; i++) {
    currentWeek.push(current.toISOString().split('T')[0]);
    if (currentWeek.length === 7) {
      weeks.push(currentWeek);
      currentWeek = [];
    }
    current.setUTCDate(current.getUTCDate() + 1);
  }
  if (currentWeek.length > 0) {
    while (currentWeek.length < 7) currentWeek.push(null);
    weeks.push(currentWeek);
  }
  return weeks;
};

export const generateSpanGrid = (startDate: string, totalDays: number): (string | null)[][] => {
  const weeks: (string | null)[][] = [];
  let currentWeek: (string | null)[] = [];
  const current = new Date(startDate + 'T12:00:00Z');

  for (let i = 0; i < totalDays; i++) {
    currentWeek.push(current.toISOString().split('T')[0]);
    if (currentWeek.length === 7) {
      weeks.push(currentWeek);
      currentWeek = [];
    }
    current.setUTCDate(current.getUTCDate() + 1);
  }
  if (currentWeek.length > 0) {
    while (currentWeek.length < 7) currentWeek.push(null);
    weeks.push(currentWeek);
  }
  return weeks;
};
