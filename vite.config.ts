import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/261016-CalendarioRecintoFerial/',
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
  },
});
