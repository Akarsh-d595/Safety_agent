/**
 * useSpeech — cross-browser speech recognition hook.
 *
 * Supports:
 *   - Chrome / Edge (desktop + Android): webkitSpeechRecognition
 *   - Safari 14.1+ (iOS + macOS): SpeechRecognition
 *   - Firefox / unsupported: graceful degradation (isSupported = false)
 */
import { useState, useRef, useCallback } from 'react'

export function useSpeech({ onResult, onFinalResult }) {
  const [listening,   setListening]   = useState(false)
  const [isSupported, setIsSupported] = useState(
    () => !!(window.SpeechRecognition || window.webkitSpeechRecognition)
  )
  const recRef = useRef(null)

  const start = useCallback(() => {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SR) { setIsSupported(false); return }

    // Stop any existing session first
    recRef.current?.abort()

    const rec = new SR()
    rec.lang            = navigator.language || 'en-US'
    rec.interimResults  = true
    rec.continuous      = false
    rec.maxAlternatives = 1

    rec.onstart  = () => setListening(true)
    rec.onend    = () => setListening(false)
    rec.onerror  = (e) => {
      setListening(false)
      // 'not-allowed' = mic permission denied
      // 'no-speech'   = timeout, not an error
      if (e.error !== 'no-speech' && e.error !== 'aborted') {
        console.warn('SpeechRecognition error:', e.error)
      }
    }

    rec.onresult = (e) => {
      const transcript = Array.from(e.results)
        .map(r => r[0].transcript)
        .join('')
      onResult?.(transcript)
      if (e.results[e.results.length - 1].isFinal) {
        onFinalResult?.(transcript)
      }
    }

    recRef.current = rec
    rec.start()
  }, [onResult, onFinalResult])

  const stop = useCallback(() => {
    recRef.current?.stop()
    setListening(false)
  }, [])

  return { listening, isSupported, start, stop }
}
