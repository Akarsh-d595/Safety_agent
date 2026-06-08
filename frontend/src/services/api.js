/**
 * API service — all calls go through /api (proxied to FastAPI in dev,
 * or set VITE_API_URL in .env for production).
 */
import axios from 'axios'

const BASE = import.meta.env.VITE_API_URL || 'https://safety-backend-python.onrender.com'

const client = axios.create({
  baseURL: BASE,
  timeout: 10_000,
  headers: { 'Content-Type': 'application/json' },
})

// ── Health ─────────────────────────────────────────────────────────────────────
export async function checkHealth() {
  try {
    const { data } = await client.get('/health')
    return data.status === 'ok'
  } catch {
    return false
  }
}

// ── Analyze ────────────────────────────────────────────────────────────────────
export async function analyzeText(text, userId = null) {
  const { data } = await client.post('/analyze', { text, user_id: userId })
  return data  // { danger, level, reason, trigger }
}

// ── Alert ──────────────────────────────────────────────────────────────────────
export async function sendAlert({ message, level, latitude, longitude, userId, contacts }) {
  const { data } = await client.post('/alert', {
    message,
    level,
    latitude,
    longitude,
    user_id:  userId,
    contacts: contacts ?? [],
  })
  return data  // { success, sms_sent, sms_failed, message }
}

// ── Incidents ──────────────────────────────────────────────────────────────────
export async function logIncident({ text, level, latitude, longitude, userId, triggered }) {
  const { data } = await client.post('/incidents', {
    text,
    level,
    latitude,
    longitude,
    user_id:   userId,
    triggered: triggered ?? false,
  })
  return data  // { incident_id, stored }
}

export async function fetchIncidents(userId = null) {
  const params = userId ? { user_id: userId } : {}
  const { data } = await client.get('/incidents', { params })
  return data  // array of incident records
}

// ── Contacts ───────────────────────────────────────────────────────────────────
export async function fetchContacts(userId) {
  const { data } = await client.get('/contacts', { params: { user_id: userId } })
  return data
}

export async function createContact({ userId, name, phone, notifyOnHigh, notifyOnMedium }) {
  const { data } = await client.post('/contacts', {
    user_id:          userId,
    name,
    phone,
    notify_on_high:   notifyOnHigh   ?? true,
    notify_on_medium: notifyOnMedium ?? false,
  })
  return data
}

export async function updateContact(contactId, userId, updates) {
  const { data } = await client.put(`/contacts/${contactId}`, {
    name:             updates.name,
    phone:            updates.phone,
    notify_on_high:   updates.notifyOnHigh,
    notify_on_medium: updates.notifyOnMedium,
  }, { params: { user_id: userId } })
  return data
}

export async function deleteContact(contactId, userId) {
  const { data } = await client.delete(`/contacts/${contactId}`, {
    params: { user_id: userId },
  })
  return data
}
