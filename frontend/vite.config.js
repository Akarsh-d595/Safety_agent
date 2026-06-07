import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    // Expose on all network interfaces so phones/tablets on the same
    // WiFi can reach the dev server at http://<your-LAN-IP>:3000
    host: '0.0.0.0',
    proxy: {
      // Proxy /api/* → FastAPI backend (localhost:8000) during development.
      // On a phone, set VITE_API_URL=http://<LAN-IP>:8000 in .env instead.
      '/api': {
        target: 'https://safety-backend-python.onrender.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
  // Ensure the build works on all browsers including older Android WebView
  build: {
    target: 'es2015',
    sourcemap: false,
  },
})
