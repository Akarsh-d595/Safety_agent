/**
 * SafetyContext — global state for the entire app.
 * Drives the full pipeline: analyze → alert → log → navigate.
 */
import { createContext, useContext, useReducer, useCallback, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import * as api from '../services/api'

// ── State shape ────────────────────────────────────────────────────────────────
const INITIAL = {
  // App flow
  appState:      'idle',       // idle | listening | processing | safe | warning | emergency
  statusMessage: 'Type or speak to start',
  inputText:     '',
  analysis:      null,         // last AnalyzeResponse from backend
  location:      null,         // { latitude, longitude }
  errorMessage:  null,

  // Data
  incidents:     [],
  contacts:      [],

  // Settings (persisted to localStorage)
  settings: {
    userId:      'user_1',
    backendOnline: false,
  },
}

// ── Reducer ────────────────────────────────────────────────────────────────────
function reducer(state, action) {
  switch (action.type) {
    case 'SET_STATE':
      return { ...state, appState: action.appState, statusMessage: action.message }
    case 'SET_INPUT':
      return { ...state, inputText: action.text }
    case 'SET_ANALYSIS':
      return { ...state, analysis: action.analysis }
    case 'SET_LOCATION':
      return { ...state, location: action.location }
    case 'SET_ERROR':
      return { ...state, errorMessage: action.message }
    case 'CLEAR_ERROR':
      return { ...state, errorMessage: null }
    case 'SET_INCIDENTS':
      return { ...state, incidents: action.incidents }
    case 'SET_CONTACTS':
      return { ...state, contacts: action.contacts }
    case 'SET_BACKEND_ONLINE':
      return { ...state, settings: { ...state.settings, backendOnline: action.online } }
    case 'UPDATE_SETTINGS':
      return { ...state, settings: { ...state.settings, ...action.settings } }
    case 'RESET':
      return {
        ...INITIAL,
        incidents: state.incidents,
        contacts:  state.contacts,
        settings:  state.settings,
      }
    default:
      return state
  }
}

// ── Context ────────────────────────────────────────────────────────────────────
const SafetyContext = createContext(null)

export function SafetyProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, INITIAL)
  const navigate          = useNavigate()
  const processingRef     = useRef(false)
  // Always-current ref so async callbacks never read stale state
  const stateRef          = useRef(state)
  useEffect(() => { stateRef.current = state }, [state])

  // ── Init ─────────────────────────────────────────────────────────────────────
  useEffect(() => {
    async function init() {
      const online = await api.checkHealth()
      dispatch({ type: 'SET_BACKEND_ONLINE', online })
      if (online) {
        // Load contacts first so they're available before any alert fires
        try {
          const contacts = await api.fetchContacts(INITIAL.settings.userId)
          dispatch({ type: 'SET_CONTACTS', contacts })
        } catch { /* silent */ }
        loadIncidents()
      }
    }
    init()
  }, []) // eslint-disable-line

  // ── Location helper ───────────────────────────────────────────────────────────
  function getLocation() {
    return new Promise((resolve) => {
      if (!navigator.geolocation) { resolve(null); return }
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve({ latitude: pos.coords.latitude, longitude: pos.coords.longitude }),
        ()    => resolve(null),
        { timeout: 8000, maximumAge: 30000 }
      )
    })
  }

  // ── Core pipeline ─────────────────────────────────────────────────────────────
  const processInput = useCallback(async (text) => {
    if (!text.trim() || processingRef.current) return
    processingRef.current = true

    dispatch({ type: 'CLEAR_ERROR' })
    dispatch({ type: 'SET_STATE', appState: 'processing', message: 'Analysing...' })

    try {
      // Step 1 — Analyze
      const analysis = await api.analyzeText(text, stateRef.current.settings.userId)
      dispatch({ type: 'SET_ANALYSIS', analysis })

      if (analysis.level === 'high') {
        await handleHighDanger(analysis, text)
      } else if (analysis.level === 'medium') {
        dispatch({ type: 'SET_STATE', appState: 'warning', message: 'Potential danger detected. Please confirm.' })
      } else {
        dispatch({ type: 'SET_STATE', appState: 'safe', message: 'You appear safe.' })
      }
    } catch (err) {
      dispatch({ type: 'SET_ERROR', message: `Error: ${err.message}` })
      dispatch({ type: 'SET_STATE', appState: 'idle', message: 'Type or speak to start' })
    } finally {
      processingRef.current = false
    }
  }, [state.settings, state.contacts]) // eslint-disable-line

  async function handleHighDanger(analysis, text) {
    dispatch({ type: 'SET_STATE', appState: 'emergency', message: 'Emergency detected! Activating protocol...' })

    // Step 2 — Get location
    const loc = await getLocation()
    if (loc) dispatch({ type: 'SET_LOCATION', location: loc })

    // Step 3 — Build alert message
    const mapsLink = loc
      ? `https://www.google.com/maps?q=${loc.latitude},${loc.longitude}`
      : 'Location unavailable'
    const alertMsg = `🚨 EMERGENCY ALERT 🚨\nI may be in danger.\nTrack my location:\n${mapsLink}`

    // Step 4 — Read current contacts/settings from ref (avoids stale closure)
    const currentState    = stateRef.current
    const alertContacts   = currentState.contacts
      .filter(c => c.notify_on_high)
      .map(c => c.phone)

    // Step 5 — Send SMS via backend
    try {
      await api.sendAlert({
        message:   alertMsg,
        level:     'high',
        latitude:  loc?.latitude,
        longitude: loc?.longitude,
        userId:    currentState.settings.userId,
        contacts:  alertContacts,
      })
      toast.success(`Alert sent to ${alertContacts.length} contact(s)`)
    } catch {
      toast.error('SMS alert failed — check backend/Twilio config')
    }

    // Step 6 — Log incident
    try {
      await api.logIncident({
        text,
        level:     'high',
        latitude:  loc?.latitude,
        longitude: loc?.longitude,
        userId:    currentState.settings.userId,
        triggered: true,
      })
    } catch { /* non-critical */ }

    // Step 7 — Navigate to emergency screen
    navigate('/emergency')
  }

  const confirmEmergency = useCallback(async () => {
    await handleHighDanger(
      { level: 'high', danger: true, reason: 'User manually confirmed', trigger: true },
      'User manually confirmed emergency'
    )
  }, [state.settings, state.contacts, state.location]) // eslint-disable-line

  const dismissWarning = useCallback(() => {
    dispatch({ type: 'SET_STATE', appState: 'safe', message: 'Dismissed. Stay safe.' })
  }, [])

  const reset = useCallback(() => {
    dispatch({ type: 'RESET' })
    navigate('/')
  }, [navigate])

  // ── Contacts CRUD ─────────────────────────────────────────────────────────────
  const loadContacts = useCallback(async () => {
    try {
      const data = await api.fetchContacts(stateRef.current.settings.userId)
      dispatch({ type: 'SET_CONTACTS', contacts: data })
    } catch { /* silent */ }
  }, [])

  const addContact = useCallback(async (contact) => {
    const created = await api.createContact({ userId: stateRef.current.settings.userId, ...contact })
    dispatch({ type: 'SET_CONTACTS', contacts: [...stateRef.current.contacts, created] })
    return created
  }, [])

  const editContact = useCallback(async (id, updates) => {
    const updated = await api.updateContact(id, stateRef.current.settings.userId, updates)
    dispatch({
      type: 'SET_CONTACTS',
      contacts: stateRef.current.contacts.map(c => c.id === id ? updated : c),
    })
  }, [])

  const removeContact = useCallback(async (id) => {
    await api.deleteContact(id, stateRef.current.settings.userId)
    dispatch({ type: 'SET_CONTACTS', contacts: stateRef.current.contacts.filter(c => c.id !== id) })
  }, [])

  // ── Incidents ─────────────────────────────────────────────────────────────────
  const loadIncidents = useCallback(async () => {
    try {
      const data = await api.fetchIncidents(stateRef.current.settings.userId)
      dispatch({ type: 'SET_INCIDENTS', incidents: data })
    } catch { /* silent */ }
  }, [])

  // ── Settings ──────────────────────────────────────────────────────────────────
  const updateSettings = useCallback(async (newSettings) => {
    dispatch({ type: 'UPDATE_SETTINGS', settings: newSettings })
    const online = await api.checkHealth()
    dispatch({ type: 'SET_BACKEND_ONLINE', online })
    if (online) {
      // Re-fetch with the new userId immediately
      try {
        const contacts = await api.fetchContacts(newSettings.userId ?? stateRef.current.settings.userId)
        dispatch({ type: 'SET_CONTACTS', contacts })
      } catch { /* silent */ }
      loadIncidents()
    }
  }, [loadIncidents])

  const value = {
    ...state,
    processInput,
    confirmEmergency,
    dismissWarning,
    reset,
    loadContacts,
    addContact,
    editContact,
    removeContact,
    loadIncidents,
    updateSettings,
    dispatch,
  }

  return <SafetyContext.Provider value={value}>{children}</SafetyContext.Provider>
}

export function useSafety() {
  const ctx = useContext(SafetyContext)
  if (!ctx) throw new Error('useSafety must be used inside SafetyProvider')
  return ctx
}
