import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Mic, MicOff, Send, AlertTriangle, CheckCircle, Loader2, RotateCcw } from 'lucide-react'
import { useSafety } from '../context/SafetyContext'
import { useSpeech } from '../hooks/useSpeech'
import StatusBadge from '../components/StatusBadge'
import WarningModal from '../components/WarningModal'

export default function HomePage() {
  const {
    appState, statusMessage, inputText, analysis, errorMessage,
    processInput, confirmEmergency, dismissWarning, reset, dispatch,
  } = useSafety()

  const navigate = useNavigate()
  const [text, setText] = useState('')

  // Navigate to emergency screen when state flips to emergency
  useEffect(() => {
    if (appState === 'emergency') navigate('/emergency')
  }, [appState, navigate])

  // ── Speech hook ───────────────────────────────────────────────────────────
  const handleResult      = useCallback((t) => {
    setText(t)
    dispatch({ type: 'SET_INPUT', text: t })
  }, [dispatch])

  const handleFinalResult = useCallback((t) => {
    processInput(t)
  }, [processInput])

  const { listening, isSupported, start, stop } = useSpeech({
    onResult:      handleResult,
    onFinalResult: handleFinalResult,
  })

  function toggleMic() {
    if (listening) stop()
    else           start()
  }

  function handleSubmit(e) {
    e.preventDefault()
    if (text.trim()) processInput(text)
  }

  const isProcessing = appState === 'processing'
  const isWarning    = appState === 'warning'

  return (
    <div className="p-4 sm:p-8 max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-6 sm:mb-8">
        <h1 className="text-xl sm:text-2xl font-bold text-white mb-1">🛡️ Safety Monitor</h1>
        <p className="text-white/40 text-sm">
          Speak or type — the AI detects danger and alerts your contacts.
        </p>
      </div>

      {/* Status row */}
      <div className="flex items-center justify-between mb-4">
        <StatusBadge state={appState} />
        {appState !== 'idle' && (
          <button
            onClick={reset}
            className="flex items-center gap-1.5 text-white/40 hover:text-white
                       text-xs transition-colors py-1 px-2"
          >
            <RotateCcw className="w-3.5 h-3.5" /> Reset
          </button>
        )}
      </div>

      <p className="text-white/60 text-sm mb-6 text-center">{statusMessage}</p>

      {/* ── Mic button — large touch target ── */}
      <div className="flex justify-center mb-4">
        <button
          onClick={toggleMic}
          disabled={isProcessing || !isSupported}
          aria-label={listening ? 'Stop listening' : 'Start listening'}
          className={`
            relative w-32 h-32 sm:w-28 sm:h-28 rounded-full
            flex items-center justify-center
            transition-all duration-300 focus:outline-none
            focus-visible:ring-4 focus-visible:ring-blue-500/50
            touch-manipulation
            ${listening
              ? 'bg-blue-600 shadow-[0_0_40px_rgba(37,99,235,0.6)]'
              : isProcessing
              ? 'bg-purple-700 cursor-not-allowed opacity-70'
              : !isSupported
              ? 'bg-slate-800 cursor-not-allowed opacity-50'
              : 'bg-slate-700 hover:bg-slate-600 active:scale-95'
            }
          `}
        >
          {listening && (
            <span className="absolute inset-0 rounded-full bg-blue-500 animate-ping opacity-25" />
          )}
          {isProcessing
            ? <Loader2 className="w-12 h-12 sm:w-10 sm:h-10 text-white animate-spin" />
            : listening
            ? <MicOff  className="w-12 h-12 sm:w-10 sm:h-10 text-white" />
            : <Mic     className="w-12 h-12 sm:w-10 sm:h-10 text-white" />
          }
        </button>
      </div>

      {/* Mic hint */}
      <p className="text-center text-white/30 text-xs mb-6">
        {!isSupported
          ? 'Voice not supported in this browser — use text input below'
          : listening
          ? 'Tap to stop'
          : 'Tap to speak'
        }
      </p>

      {/* ── Text input ── */}
      <form onSubmit={handleSubmit} className="flex gap-2 sm:gap-3 mb-5">
        <input
          className="input flex-1 text-base"   /* text-base prevents iOS zoom on focus */
          placeholder="Or type your message here..."
          value={text}
          onChange={e => setText(e.target.value)}
          disabled={isProcessing}
          autoComplete="off"
          autoCorrect="off"
          spellCheck="false"
        />
        <button
          type="submit"
          disabled={isProcessing || !text.trim()}
          className="btn-primary flex items-center gap-2 px-4 touch-manipulation"
        >
          {isProcessing
            ? <Loader2 className="w-4 h-4 animate-spin" />
            : <Send    className="w-4 h-4" />
          }
        </button>
      </form>

      {/* ── Recognised speech ── */}
      {inputText && (
        <div className="card p-4 mb-5">
          <p className="text-white/40 text-xs font-bold uppercase tracking-wider mb-2">
            🎤 Recognised
          </p>
          <p className="text-white text-sm">{inputText}</p>
        </div>
      )}

      {/* ── Analysis result ── */}
      {analysis && (
        <div className={`card p-4 mb-5 border ${
          analysis.level === 'high'   ? 'border-red-500/40    bg-red-500/5'    :
          analysis.level === 'medium' ? 'border-orange-500/40 bg-orange-500/5' :
          analysis.level === 'low'    ? 'border-yellow-500/40 bg-yellow-500/5' :
                                        'border-green-500/40  bg-green-500/5'
        }`}>
          <div className="flex items-start gap-3">
            {analysis.danger
              ? <AlertTriangle className="w-5 h-5 text-orange-400 mt-0.5 flex-shrink-0" />
              : <CheckCircle   className="w-5 h-5 text-green-400  mt-0.5 flex-shrink-0" />
            }
            <div>
              <p className="text-white text-sm font-medium mb-1">
                Level: <span className="uppercase font-bold">{analysis.level}</span>
              </p>
              <p className="text-white/50 text-xs">{analysis.reason}</p>
            </div>
          </div>
        </div>
      )}

      {/* ── Error banner ── */}
      {errorMessage && (
        <div className="card p-4 border border-red-500/30 bg-red-500/5 mb-5">
          <p className="text-red-400 text-sm">{errorMessage}</p>
        </div>
      )}

      {/* ── Warning modal ── */}
      {isWarning && (
        <WarningModal onConfirm={confirmEmergency} onDismiss={dismissWarning} />
      )}
    </div>
  )
}
