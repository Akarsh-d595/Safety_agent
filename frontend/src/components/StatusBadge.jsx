/**
 * Animated status pill that reflects the current app state.
 */
const CONFIG = {
  idle:       { label: '● IDLE',        color: 'text-white/40',    bg: 'bg-white/5',         border: 'border-white/10',    dot: 'bg-white/30',    pulse: false },
  listening:  { label: '🎤 LISTENING',  color: 'text-blue-400',    bg: 'bg-blue-500/10',     border: 'border-blue-500/30', dot: 'bg-blue-400',    pulse: true  },
  processing: { label: '⚙️ PROCESSING', color: 'text-purple-400',  bg: 'bg-purple-500/10',   border: 'border-purple-500/30', dot: 'bg-purple-400', pulse: true },
  safe:       { label: '✅ SAFE',        color: 'text-green-400',   bg: 'bg-green-500/10',    border: 'border-green-500/30', dot: 'bg-green-400',  pulse: false },
  warning:    { label: '⚠️ WARNING',    color: 'text-orange-400',  bg: 'bg-orange-500/10',   border: 'border-orange-500/30', dot: 'bg-orange-400', pulse: true },
  emergency:  { label: '🚨 EMERGENCY',  color: 'text-red-400',     bg: 'bg-red-500/10',      border: 'border-red-500/30',  dot: 'bg-red-400',    pulse: true  },
}

export default function StatusBadge({ state }) {
  const cfg = CONFIG[state] ?? CONFIG.idle

  return (
    <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-full border text-sm font-bold
                     transition-all duration-300 ${cfg.bg} ${cfg.border} ${cfg.color}`}>
      <span className="relative flex h-2.5 w-2.5">
        {cfg.pulse && (
          <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-60 ${cfg.dot}`} />
        )}
        <span className={`relative inline-flex rounded-full h-2.5 w-2.5 ${cfg.dot}`} />
      </span>
      {cfg.label}
    </div>
  )
}
