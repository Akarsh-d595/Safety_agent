import { useEffect, useState } from 'react'
import { History, RefreshCw, MapPin, AlertTriangle, CheckCircle, Clock } from 'lucide-react'
import { useSafety } from '../context/SafetyContext'

const LEVEL_CONFIG = {
  high:   { label: '🚨 HIGH',   color: 'text-red-400',    bg: 'bg-red-500/10',    border: 'border-red-500/30'    },
  medium: { label: '⚠️ MEDIUM', color: 'text-orange-400', bg: 'bg-orange-500/10', border: 'border-orange-500/30' },
  low:    { label: '🔔 LOW',    color: 'text-yellow-400', bg: 'bg-yellow-500/10', border: 'border-yellow-500/30' },
  none:   { label: '✅ SAFE',   color: 'text-green-400',  bg: 'bg-green-500/10',  border: 'border-green-500/30'  },
}

export default function HistoryPage() {
  const { incidents, loadIncidents, settings } = useSafety()
  const [loading, setLoading] = useState(false)

  useEffect(() => { refresh() }, []) // eslint-disable-line

  async function refresh() {
    setLoading(true)
    await loadIncidents()
    setLoading(false)
  }

  return (
    <div className="p-4 sm:p-8 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6 sm:mb-8">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-white mb-1">📋 Incident History</h1>
          <p className="text-white/40 text-sm">
            All detected events for user{' '}
            <span className="text-white/60">{settings.userId}</span>
          </p>
        </div>
        <button
          onClick={refresh}
          disabled={loading}
          className="btn-ghost flex items-center gap-2 text-sm"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Backend offline warning */}
      {!settings.backendOnline && (
        <div className="card p-4 border border-orange-500/20 bg-orange-500/5 mb-6">
          <p className="text-orange-400 text-sm">
            Backend is offline. History requires a backend connection.
          </p>
        </div>
      )}

      {/* List */}
      {loading ? (
        <div className="text-center py-16 text-white/30">Loading incidents...</div>
      ) : incidents.length === 0 ? (
        <div className="text-center py-16">
          <History className="w-12 h-12 text-white/10 mx-auto mb-4" />
          <p className="text-white/40 text-sm">No incidents recorded yet.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {incidents.map(inc => (
            <IncidentCard key={inc.id} incident={inc} />
          ))}
        </div>
      )}
    </div>
  )
}

function IncidentCard({ incident }) {
  const cfg = LEVEL_CONFIG[incident.level] ?? LEVEL_CONFIG.none
  const date = new Date(incident.timestamp)

  return (
    <div className={`card p-4 border ${cfg.border} ${cfg.bg}`}>
      {/* Top row */}
      <div className="flex items-center justify-between mb-3">
        <span className={`text-xs font-bold ${cfg.color} uppercase tracking-wider`}>
          {cfg.label}
        </span>
        <span className="text-white/30 text-xs flex items-center gap-1">
          <Clock className="w-3 h-3" />
          {date.toLocaleDateString()} {date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </span>
      </div>

      {/* Text */}
      <p className="text-white text-sm mb-3 line-clamp-3">{incident.text}</p>

      {/* Footer */}
      <div className="flex items-center gap-4 text-xs text-white/30">
        {incident.latitude != null && (
          <span className="flex items-center gap-1">
            <MapPin className="w-3 h-3 text-green-400" />
            <a
              href={`https://www.google.com/maps?q=${incident.latitude},${incident.longitude}`}
              target="_blank"
              rel="noreferrer"
              className="text-green-400 hover:underline"
            >
              {incident.latitude.toFixed(4)}, {incident.longitude.toFixed(4)}
            </a>
          </span>
        )}
        {incident.triggered && (
          <span className="flex items-center gap-1 text-red-400">
            <AlertTriangle className="w-3 h-3" /> Emergency triggered
          </span>
        )}
        {!incident.triggered && (
          <span className="flex items-center gap-1 text-green-400">
            <CheckCircle className="w-3 h-3" /> Not triggered
          </span>
        )}
      </div>
    </div>
  )
}
