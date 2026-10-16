# 261016-CalendarioRecintoFerial
Tablero de operaciones móvil para la gestión de ferias y pabellones del Recinto Ferial Cruceño, Santa Cruz de la Sierra, Bolivia (React, TypeScript y TailwindCSS).

## Descripción
Aplicación web de operaciones que administra más de 20 ferias por año sobre un conjunto de pabellones compartidos. Evita que dos ferias se superpongan en un mismo pabellón y muestra qué ventanas libres quedan para vender nuevas ferias o eventos. La usa el equipo de operaciones y la gerencia, no el público.

## Características
✅ Calendario perpetuo anual con vista de 365/366 días y todos los pabellones superpuestos.
✅ Validación central: una feria no ocupa un pabellón solo los días abiertos al público, también los de montaje, desmontaje y 1 día de limpieza.
✅ Verificación de disponibilidad con búsqueda de combinaciones de pabellones vecinos conectados.
✅ Exportación a PDF del calendario con las ventanas fijadas.
✅ Flujo bidireccional Verificación ↔ Ferias (crear feria desde ventana fijada / verificar desde formulario).
✅ Ocupación anual por tipo de pabellón con gráficos anulares y calendario Gantt unificado.
✅ Catálogo de pabellones con topología de vecinos (máx. 3 vecinos para cerrados, 4 para aire libre).
✅ Persistencia en `localStorage` con clave versionada.
✅ Mobile-first, optimizado para 360 px.
✅ Paleta institucional Cruceña: verde campo, naranja acento.
✅ Tipografías: Roboto Condensed (títulos) e Inter (texto).

## URL de previsualización
 **GitHub Pages**: https://gertecin.github.io/261016-CalendarioRecintoFerial/

## Cómo arrancar en local
### Requisitos
- Node.js 18+ (descargar en https://nodejs.org)
- npm (viene incluido con Node.js)
### Pasos
```bash
# 1. Clonar el repositorio
git clone https://github.com/Gertecin/261016-CalendarioRecintoFerial.git
cd 261016-CalendarioRecintoFerial
# 2. Instalar dependencias
npm install
# 3. Iniciar servidor de desarrollo
npm run dev
# 4. Compilar para producción
npm run build
# 5. Ejecutar tests
npm run test
# 6. Previsualizar build de producción
npm run preview

# Configuración importante para el despliegue
El archivo vite.config.ts tiene base: '/261016-CalendarioRecintoFerial/' para funcionar correctamente en GitHub Pages. Si se despliega en un dominio propio, cambiar a base: '/'.

# Gestión de claves usadas en LocalStorage
## Claves que se usa
Clave | Contenido | Ejemplo
recinto-ferial:v1 | Array JSON de ferias, pabellones y año seleccionado | {"pavilions":[...],"fairs":[...],"selectedYear":2026}
## Cómo ver las claves
Abre el sitio en tu navegador.
Presiona F12 (o clic derecho → Inspeccionar).
Ve a la pestaña Application (Aplicación).
En el panel izquierdo, expande Local Storage y selecciona el dominio.
Verás la clave recinto-ferial:v1 con su valor actual.
## Cómo vaciar / reiniciar las claves
Abre la pestaña Console (dentro de las herramientas de desarrollador) y ejecuta:
Intervalo = Montaje + Feria + Desmontaje + 1 día de Limpieza
Ejemplo: Feria con montaje=5, feria=7, desmontaje=3
Montaje: días 1-5
Feria: días 6-12
Desmontaje: días 13-15
Limpieza: día 16 (automático, no editable)
Total ocupado: 16 días
2. Día de limpieza
Constante del sistema: LIMPIEZA_DIAS = 1
No es editable por el usuario
Se agrega automáticamente al final del desmontaje
Regla crítica: Si el desmontaje termina un domingo, el lunes es limpieza y la siguiente feria recién puede empezar el montaje el martes.
3. Conflicto
Dos ferias distintas que comparten al menos un pabellón y cuyos intervalos ocupados tienen algún día en común.
Ejemplo de conflicto:
Feria A: desmontaje termina el domingo 15
Feria B: quiere montar el lunes 16
❌ CONFLICTO: el lunes 16 es día de limpieza de Feria A
✅ VÁLIDO: Feria B monta el martes 17
Validación al guardar:
Se revisan TODOS los pabellones de la feria contra las demás ferias
Si hay conflicto, no se guarda y se muestra:
Con qué feria choca
En qué pabellón
Qué días se pisan
Cuál sería la primera fecha de montaje posible
4. Ventanas libres
Período entre intervalos ocupados consecutivos de un pabellón, incluyendo:
El tramo antes de la primera feria del año
El tramo después de la última feria del año
Los huecos entre ferias
Criterio: Solo se muestran ventanas cuya duración en días sea ≥ los días pedidos (montaje + feria + desmontaje + 1 limpieza).
Búsqueda de combinaciones conectadas:
El sistema busca grupos de pabellones vecinos físicos que sumen los m² necesarios
Prioriza: (1) usar todos los tipos seleccionados, (2) más tipos distintos, (3) pabellones más grandes
Si hay >15 combinaciones, alerta al usuario para que fije fecha o limite tipos
5. Ocupación
Días del año dentro de algún intervalo ocupado (unión de intervalos, sin contar dos veces los solapados, recortada al año consultado) / días del año.
1
Las ferias que cruzan fin de año cuentan solo la parte que cae dentro del año consultado
Se calcula por pabellón individual y por tipo de pabellón
Calendario perpetuo y años bisiestos
Calendario perpetuo
No hardcodea ningún año específico
Selector de año con flechas anterior/siguiente y campo numérico
Rango razonable: 1900–2200
El año inicial al abrir la app es el año actual
La grilla se regenera completamente al cambiar de año
Años bisiestos (regla gregoriana)
123
Ejemplos:
✅ 2024: bisiesto (divisible por 4, no por 100)
❌ 2100: NO bisiesto (divisible por 100, no por 400)
✅ 2000: bisiesto (divisible por 400)
✅ 2028: bisiesto (febrero tiene 29 días)
✅ 2032: bisiesto (febrero tiene 29 días)
Implementación:
Fechas como strings YYYY-MM-DD en UTC
Aritmética en días calendario usando Date con hora fija T12:00:00Z para evitar errores de huso horario
Función isLeapYear(year) aplica la regla gregoriana completa
Estructura de la grilla
La semana empieza el lunes
El 1 de enero cae en su día de la semana real
Las filas anteriores a esa fecha quedan en blanco
Los meses no empiezan en una fila nueva: un mismo renglón puede tener días de dos meses
Sombreado alterno por mes: azul muy claro (#DCE6F1) y gris muy claro (#F2F2F2)
Datos de ejemplo y restauración
Datos precargados
15 pabellones con topología válida:
Pabellón Principal (8.000 m², cerrado)
Pabellón Internacional (4.500 m², cerrado)
Pabellones 1-4 (1.200 m², cerrado)
Pabellones 5-8 (2.500 m², semicubierto)
Sector Aire Libre A y B (5.000 m² cada uno)
Playón de Maquinaria (10.000 m²)
Salón de Convenciones (3.000 m²)
Pabellón 9 (1.800 m², cerrado)
22 ferias con duraciones plausibles:
Feria Internacional Multisectorial (7/10/5)
Feria de la Construcción (5/7/3)
Feria Agropecuaria (4/8/4)
... (22 en total)
Restauración de datos
Botón "Restaurar seed" en la pestaña Ferias
Borra todos los cambios y vuelve a los datos de ejemplo
Confirmación requerida antes de restaurar


### Paleta de colores

| Color | Código | Uso |
|-------|--------|-----|
| 🟢 Verde campo profundo | `#3F6B4A` | Primario, headers, botones principales |
|  Verde medio | `#2F6B3A` | Hover states, acentos secundarios |
| 🟢 Verde oscuro | `#1D2E20` | Texto principal, headers de tablas |
| 🟠 Naranja acento | `#E8842C` | Acciones principales, alertas, botones de fijar |
| ⚪ Fondo | `#F4F6F4` | Background general |
|  Blanco | `#FFFFFF` | Cards, superficies |
| 🔲 Gris línea | `#E5E9E6` | Bordes, separadores |
| 🔘 Gris muted | `#6B7A6F` | Texto secundario, labels |
| 🔵 Azul mes par | `#DCE6F1` | Sombreado calendario (meses pares) |
| ⚫ Gris mes impar | `#F2F2F2` | Sombreado calendario (meses impares) |

### Colores por tipo de pabellón (anulares)

| Tipo | Color | Uso |
|------|-------|-----|
| 🟡 Cerrado | `#F5C518` (amarillo) | Anillo ocupación, calendario Gantt |
| 🟠 Semicubierto | `#E8842C` (naranja) | Anillo ocupación, calendario Gantt |
| 🔵 Aire libre | `#4682B4` (azul) | Anillo ocupación, calendario Gantt |
| 🟣 Playón | `#8A2BE2` (violeta) | Anillo ocupación, calendario Gantt |
| 🔴 Salón | `#FF6347` (tomate) | Anillo ocupación, calendario Gantt |

### Tipografía

| Elemento | Tipografía | Pesos | Carga |
|----------|-----------|-------|-------|
| **Títulos y números destacados** | Roboto Condensed | 500, 600, 700 | Google Fonts (`index.html`) |
| **Texto y formularios** | Inter | 400, 500, 600, 700 | Google Fonts (`index.html`) |

**Cómo cambiar la tipografía:**
1. Editar `index.html` para cargar nuevas fuentes de Google Fonts
2. Editar `tailwind.config.js`:
```javascript
fontFamily: {
  title: ['"Nueva Fuente Títulos"', 'sans-serif'],
  body: ['"Nueva Fuente Texto"', 'sans-serif'],
