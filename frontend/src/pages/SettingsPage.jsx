import { useState } from 'react'
import { Save, Wifi, WifiOff, User, Server, Info } from 'lucide-react'
import toast from 'react-hot-toast'
import { useSafety } from '../context/SafetyContext'
import * as api from '../services/api'

export default function SettingsPage() {
  const { settings, updateSettings } = useSafety()

  const [userId,     setUserId]     = useState(settings.userId     ?? 'user_1')
  const [backendUrl, setBackendUrl] = useState(
    // Show the real URL being used (env override or current origin/api)
    import.meta.env.VITE_API_URL || 'http://localhost:8000'
  )
  const [testing,    setTesting]    = useState(false)
  const [testResult, setTestResult] = useState(null)
  const [saving,     setSaving]     = useState(false)

  async function testConnection() {
    setTesting(true)
    setTestResult(null)
    try {
      // Direct fetch avoids the Vite proxy so we can test any URL the user typed
      const res = await fetch(`${backendUrl}/health`, { signal: AbortSignal.timeout(5000) })
      const json = await res.json()
      setTestResult(json?.status === 'ok')
    } catch {
      setTestResult(false)
    } finally {
      setTesting(false)
    }
  }

  async function handleSave() {
    if (!userId.trim()) { toast.error('User ID cannot be empty'); return }
    setSaving(true)
    try {
      await updateSettings({ userId: userId.trim() })
      toast.success('Settings saved')
    } catch (err) {
      toast.error(`Failed: ${err.message}`)
    } finally {
      setSaving(false)
    }
  }

  // Detect likely LAN IP hint for mobile users
  const isLocalhost = backendUrl.includes('localhost') || backendUrl.includes('127.0.0.1')

  return (
    <div className="p-4 sm:p-8 max-w-xl mx-auto">
      <div className="mb-6 sm:mb-8">
        <h1 className="text-xl sm:text-2xl font-bold text-white mb-1">⚙️ Settings</h1>
        <p className="text-white/40 text-sm">Configure your identity and backend connection.</p>
      </div>

      <div className="space-y-5">

        {/* ── User ID ── */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <User className="w-4 h-4 text-blue-400" />
            <h2 className="text-white font-semibold text-sm">User Identity</h2>
          </div>
          <label className="section-title">User ID</label>
          <input
            className="input text-base"
            value={userId}
            onChange={e => setUserId(e.target.value)}
            placeholder="e.g. alice or user_1"
            autoCapitalize="none"
            autoCorrect="off"
          />
          <p className="text-white/30 text-xs mt-2">
            Used to associate incidents and contacts with your account.
          </p>
        </div>

        {/* ── Backend URL ── */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <Server className="w-4 h-4 text-blue-400" />
            <h2 className="text-white font-semibold text-sm">Backend API</h2>
          </div>

          {/* Status pill */}
          <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs
                           font-medium mb-4 ${
            settings.backendOnline
              ? 'bg-green-500/10 text-green-400 border border-green-500/20'
              : 'bg-orange-500/10 text-orange-400 border border-orange-500/20'
          }`}>
            {settings.backendOnline
              ? <><Wifi    className="w-3.5 h-3.5" /> Connected</>
              : <><WifiOff className="w-3.5 h-3.5" /> Unreachable</>
            }
          </div>

          <label className="section-title">Backend URL</label>
          <input
            className="input text-base mb-2"
            value={backendUrl}
            onChange={e => { setBackendUrl(e.target.value); setTestResult(null) }}
            placeholder="http://192.168.1.x:8000"
            type="url"
            autoCapitalize="none"
            autoCorrect="off"
          />

          {/* Mobile hint */}
          {isLocalhost && (
            <div className="flex items-start gap-2 bg-yellow-500/5 border border-yellow-500/20
                            rounded-xl p-3 mb-3">
              <Info className="w-4 h-4 text-yellow-400 flex-shrink-0 mt-0.5" />
              <p className="text-yellow-300/80 text-xs leading-relaxed">
                <strong>On a phone or tablet?</strong> Replace{' '}
                <code className="text-yellow-200">localhost</code> with your computer's
                LAN IP address (e.g. <code className="text-yellow-200">192.168.1.42</code>).
                Find it by running <code className="text-yellow-200">ipconfig</code> on Windows
                or <code className="text-yellow-200">ifconfig</code> on Mac/Linux.
              </p>
            </div>
          )}

          <div className="flex items-center gap-3">
            <button
              onClick={testConnection}
              disabled={testing}
              className="btn-ghost flex items-center gap-2 text-sm touch-manipulation"
            >
              <Wifi className="w-4 h-4" />
              {testing ? 'Testing...' : 'Test Connection'}
            </button>
            {testResult !== null && (
              <span className={`text-sm font-medium ${
                testResult ? 'text-green-400' : 'text-red-400'
              }`}>
                {testResult ? '✅ Connected' : '❌ Unreachable'}
              </span>
            )}
          </div>

          <p className="text-white/25 text-xs mt-3">
            In development the Vite proxy handles <code>/api → localhost:8000</code>.
            Set <code>VITE_API_URL</code> in <code>.env</code> for production.
          </p>
        </div>

        {/* ── Twilio info ── */}
        <div className="card p-5 border border-yellow-500/10 bg-yellow-500/5">
          <h2 className="text-yellow-400 font-semibold text-sm mb-2">📱 SMS Alerts (Twilio)</h2>
          <p className="text-white/40 text-xs leading-relaxed mb-3">
            SMS alerts are sent server-side. Configure in{' '}
            <code className="text-white/60">backend/.env</code>:
          </p>
          <pre className="text-xs text-white/50 bg-black/20 rounded-lg p-3 overflow-x-auto
                          whitespace-pre-wrap break-all">
{`TWILIO_ACCOUNT_SID=ACxxxxxxxx
TWILIO_AUTH_TOKEN=your_token
TWILIO_FROM_NUMBER=+17433477403`}
          </pre>
        </div>

        {/* ── Save ── */}
        <button
          onClick={handleSave}
          disabled={saving}
          className="btn-primary w-full flex items-center justify-center gap-2
                     py-3 touch-manipulation"
        >
          <Save className="w-4 h-4" />
          {saving ? 'Saving...' : 'Save Settings'}
        </button>

      </div>
    </div>
  )
}
