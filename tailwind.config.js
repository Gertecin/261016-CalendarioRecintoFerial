/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        expocad: {
          primary: '#3F6B4A',
          medium: '#2F6B3A',
          dark: '#1D2E20',
          accent: '#E8842C',
          bg: '#F4F6F4',
          surface: '#FFFFFF',
          line: '#E5E9E6',
          muted: '#6B7A6F',
          month1: '#DCE6F1',
          month2: '#F2F2F2',
        }
      },
      fontFamily: {
        title: ['"Roboto Condensed"', 'sans-serif'],
        body: ['"Inter"', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px rgba(29, 46, 32, 0.06), 0 4px 12px rgba(29, 46, 32, 0.04)',
      }
    },
  },
  plugins: [],
}
