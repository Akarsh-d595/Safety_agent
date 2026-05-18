/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        dark: {
          900: '#0f0f1a',
          800: '#1a1a2e',
          700: '#16213e',
          600: '#0f3460',
        },
      },
      animation: {
        'pulse-fast': 'pulse 0.8s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'ping-slow':  'ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite',
      },
      // Minimum touch target size (WCAG 2.5.5 — 44×44px)
      minHeight: { touch: '44px' },
      minWidth:  { touch: '44px' },
      // Safe-area spacing tokens
      spacing: {
        'safe-top':    'env(safe-area-inset-top,    0px)',
        'safe-bottom': 'env(safe-area-inset-bottom, 0px)',
        'safe-left':   'env(safe-area-inset-left,   0px)',
        'safe-right':  'env(safe-area-inset-right,  0px)',
      },
    },
  },
  plugins: [],
}
