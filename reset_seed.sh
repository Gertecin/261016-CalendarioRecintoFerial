#!/bin/bash
set -e

echo "🔄 Reiniciando datos de ejemplo con 15 pabellones y 22 ferias..."

cat << 'EOF' > src/data/seed.ts
import { Pavilion, Fair } from '../lib/validation';
import { addDays } from '../lib/dates';

// 15 Pabellones según briefing original
export const PAVILIONS: Pavilion[] = [
  // Pabellones principales (cerrados)
  { id: 'p1', nombre: 'Pabellón Principal', m2: 8000, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p2', 'p3', 'p7'] },
  { id: 'p2', nombre: 'Pabellón Internacional', m2: 4500, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p4'] },
  
  // Pabellones 1-8 (1.200 y 2.500 m², solo 2 tamaños)
  { id: 'p3', nombre: 'Pabellón 1', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p5'] },
  { id: 'p4', nombre: 'Pabellón 2', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p2', 'p6'] },
  { id: 'p5', nombre: 'Pabellón 3', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p3', 'p7'] },
  { id: 'p6', nombre: 'Pabellón 4', m2: 1200, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p4', 'p8'] },
  { id: 'p7', nombre: 'Pabellón 5', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p1', 'p5', 'p9'] },
  { id: 'p8', nombre: 'Pabellón 6', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p6', 'p10'] },
  { id: 'p9', nombre: 'Pabellón 7', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p7', 'p11'] },
  { id: 'p10', nombre: 'Pabellón 8', m2: 2500, tipo: 'semicubierto', tieneParedExterior: true, vecinos: ['p8', 'p12'] },
  
  // Sectores exteriores
  { id: 'p11', nombre: 'Sector Aire Libre A', m2: 5000, tipo: 'aire libre', tieneParedExterior: true, vecinos: ['p9', 'p12', 'p13', 'p14'] },
  { id: 'p12', nombre: 'Sector Aire Libre B', m2: 5000, tipo: 'aire libre', tieneParedExterior: true, vecinos: ['p10', 'p11', 'p13', 'p14'] },
  { id: 'p13', nombre: 'Playón de Maquinaria', m2: 10000, tipo: 'playón', tieneParedExterior: true, vecinos: ['p11', 'p12', 'p14'] },
  { id: 'p14', nombre: 'Salón de Convenciones', m2: 3000, tipo: 'salón', tieneParedExterior: true, vecinos: ['p11', 'p12', 'p13'] },
  { id: 'p15', nombre: 'Pabellón 9', m2: 1800, tipo: 'cerrado', tieneParedExterior: true, vecinos: ['p1', 'p2'] },
];

// Colores basados en tipo de pabellón (anulares)
const TIPO_COLORS: Record<string, string> = {
  'cerrado': '#3F6B4A',
  'semicubierto': '#E8842C',
  'aire libre': '#4682B4',
  'playón': '#8A2BE2',
  'salón': '#FF6347'
};

// 22 Ferias según briefing original
// Duraciones: montaje / feria / desmontaje
// Desplazamientos desde 15 de enero del año
export const generateSeedFairs = (year: number): Fair[] => {
  const base = `${year}-01-15`;
  const mk = (id: string, nombre: string, sector: string, offset: number, m: number, f: number, d: number, pavs: string[]): Fair => ({
    id, nombre, sector,
    color: TIPO_COLORS['cerrado'], // Se asignará según pabellón principal
    fechaInicioMontaje: addDays(base, offset),
    diasMontaje: m, diasFeria: f, diasDesmontaje: d, pabellonIds: pavs
  });

  // Asignar color según tipo de pabellón principal
  const getColorForPavs = (pavs: string[]): string => {
    const pav = PAVILIONS.find(p => p.id === pavs[0]);
    return pav ? TIPO_COLORS[pav.tipo] : TIPO_COLORS['cerrado'];
  };

  const fairs: Fair[] = [
    // 1. Feria Internacional Multisectorial 7/10/5
    { ...mk('f1', 'Feria Internacional Multisectorial', 'Multisectorial', 260, 7, 10, 5, ['p1', 'p2', 'p3', 'p4', 'p15']), color: getColorForPavs(['p1', 'p2', 'p3', 'p4', 'p15']) },
    
    // 2. Feria de la Construcción (desmontaje 3 días, Pabellón Principal)
    { ...mk('f2', 'Feria de la Construcción', 'Construcción', 45, 5, 7, 3, ['p1']), color: getColorForPavs(['p1']) },
    
    // 3. Feria Agropecuaria (aire libre A y B y playón)
    { ...mk('f3', 'Feria Agropecuaria', 'Agro', 120, 4, 8, 4, ['p11', 'p12', 'p13']), color: getColorForPavs(['p11', 'p12', 'p13']) },
    
    // 4. Feria de Tecnología
    { ...mk('f4', 'Feria de Tecnología', 'Tecnología', 75, 5, 6, 2, ['p5', 'p6']), color: getColorForPavs(['p5', 'p6']) },
    
    // 5. Feria del Mueble
    { ...mk('f5', 'Feria del Mueble', 'Hogar', 95, 6, 9, 3, ['p7', 'p8']), color: getColorForPavs(['p7', 'p8']) },
    
    // 6. Feria Gastronómica
    { ...mk('f6', 'Feria Gastronómica', 'Gastronomía', 150, 3, 10, 2, ['p14']), color: getColorForPavs(['p14']) },
    
    // 7. Expo Automotriz
    { ...mk('f7', 'Expo Automotriz', 'Automotriz', 180, 7, 8, 4, ['p13']), color: getColorForPavs(['p13']) },
    
    // 8. Minería e Hidrocarburos
    { ...mk('f8', 'Minería e Hidrocarburos', 'Industria', 200, 5, 5, 3, ['p2', 'p14']), color: getColorForPavs(['p2', 'p14']) },
    
    // 9. Turismo
    { ...mk('f9', 'Expo Turismo', 'Servicios', 220, 4, 6, 2, ['p9', 'p10']), color: getColorForPavs(['p9', 'p10']) },
    
    // 10. Salud y Bienestar
    { ...mk('f10', 'Salud y Bienestar', 'Salud', 240, 3, 5, 2, ['p3', 'p4']), color: getColorForPavs(['p3', 'p4']) },
    
    // 11. Educación y Empleo
    { ...mk('f11', 'Educación y Empleo', 'Educación', 30, 4, 4, 2, ['p14']), color: getColorForPavs(['p14']) },
    
    // 12. Artesanía
    { ...mk('f12', 'Artesanía', 'Cultura', 300, 5, 12, 3, ['p11']), color: getColorForPavs(['p11']) },
    
    // 13. Expo Ganadera
    { ...mk('f13', 'Expo Ganadera', 'Agro', 130, 6, 7, 4, ['p12', 'p13']), color: getColorForPavs(['p12', 'p13']) },
    
    // 14. Maquinaria Agrícola
    { ...mk('f14', 'Maquinaria Agrícola', 'Agro', 145, 5, 6, 3, ['p13']), color: getColorForPavs(['p13']) },
    
    // 15. Moda
    { ...mk('f15', 'Moda', 'Textil', 280, 4, 5, 2, ['p2', 'p14']), color: getColorForPavs(['p2', 'p14']) },
    
    // 16. Hogar y Decoración
    { ...mk('f16', 'Hogar y Decoración', 'Hogar', 100, 5, 8, 3, ['p7', 'p8']), color: getColorForPavs(['p7', 'p8']) },
    
    // 17. Energías Renovables
    { ...mk('f17', 'Energías Renovables', 'Energía', 170, 4, 5, 2, ['p9', 'p10']), color: getColorForPavs(['p9', 'p10']) },
    
    // 18. Logística y Transporte
    { ...mk('f18', 'Logística y Transporte', 'Logística', 190, 5, 6, 3, ['p13']), color: getColorForPavs(['p13']) },
    
    // 19. Franquicias y Emprendimiento
    { ...mk('f19', 'Franquicias y Emprendimiento', 'Negocios', 210, 3, 4, 2, ['p14']), color: getColorForPavs(['p14']) },
    
    // 20. Finanzas y Seguros
    { ...mk('f20', 'Finanzas y Seguros', 'Finanzas', 230, 3, 4, 2, ['p2']), color: getColorForPavs(['p2']) },
    
    // 21. Feria del Libro
    { ...mk('f21', 'Feria del Libro', 'Cultura', 250, 6, 10, 3, ['p14']), color: getColorForPavs(['p14']) },
    
    // 22. Juguetes y Regalos de Navidad
    { ...mk('f22', 'Juguetes y Regalos de Navidad', 'Comercio', 315, 5, 12, 4, ['p1', 'p2', 'p3']), color: getColorForPavs(['p1', 'p2', 'p3']) },
  ];

  return fairs;
};
EOF

echo "✅ Datos de ejemplo reiniciados:"
echo "   - 15 pabellones (Principal, Internacional, 1-8, Aire Libre A/B, Playón, Salón, Pabellón 9)"
echo "   - 22 ferias con duraciones plausibles"
echo "   - Colores basados en tipo de pabellón (anulares)"
echo "   - Topología válida (máx 3-4 vecinos según tipo)"
echo ""
echo "️  IMPORTANTE: Borra el localStorage del navegador para cargar los nuevos datos:"
echo "   1. Abre DevTools (F12)"
echo "   2. Ve a Application > Local Storage"
echo "   3. Elimina la clave 'recinto-ferial:v3'"
echo "   4. Recarga la página"
