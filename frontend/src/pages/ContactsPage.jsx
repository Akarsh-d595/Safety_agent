import { useState, useEffect } from 'react'
import { Users, Plus, Trash2, Edit3, Check, X, Bell, BellOff, Phone } from 'lucide-react'
import toast from 'react-hot-toast'
import { useSafety } from '../context/SafetyContext'
import ConfirmModal from '../components/ConfirmModal'

const EMPTY_FORM = { name: '', phone: '', notifyOnHigh: true, notifyOnMedium: false }

export default function ContactsPage() {
  const { contacts, loadContacts, addContact, editContact, removeContact } = useSafety()
  const [showForm, setShowForm]         = useState(false)
  const [form, setForm]                 = useState(EMPTY_FORM)
  const [editingId, setEditingId]       = useState(null)
  const [saving, setSaving]             = useState(false)
  const [loading, setLoading]           = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null) // { id, name }

  useEffect(() => {
    async function load() {
      setLoading(true)
      await loadContacts()
      setLoading(false)
    }
    load()
  }, []) // eslint-disable-line

  function openAdd() {
    setForm(EMPTY_FORM)
    setEditingId(null)
    setShowForm(true)
  }

  function openEdit(contact) {
    setForm({
      name:            contact.name,
      phone:           contact.phone,
      notifyOnHigh:    contact.notify_on_high,
      notifyOnMedium:  contact.notify_on_medium,
    })
    setEditingId(contact.id)
    setShowForm(true)
  }

  function cancelForm() {
    setShowForm(false)
    setEditingId(null)
    setForm(EMPTY_FORM)
  }

  async function handleSave() {
    if (!form.name.trim() || !form.phone.trim()) {
      toast.error('Name and phone are required')
      return
    }
    // Basic E.164 validation
    const phone = form.phone.startsWith('+') ? form.phone : `+${form.phone}`
    if (!/^\+\d{7,15}$/.test(phone)) {
      toast.error('Enter a valid phone number (e.g. +1234567890)')
      return
    }

    setSaving(true)
    try {
      if (editingId) {
        await editContact(editingId, { ...form, phone })
        toast.success('Contact updated')
      } else {
        await addContact({ ...form, phone })
        toast.success('Contact added')
      }
      cancelForm()
    } catch (err) {
      toast.error(`Failed: ${err.message}`)
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(id, name) {
    setDeleteTarget({ id, name })
  }

  async function confirmDelete() {
    if (!deleteTarget) return
    try {
      await removeContact(deleteTarget.id)
      toast.success('Contact removed')
    } catch (err) {
      toast.error(`Failed: ${err.message}`)
    } finally {
      setDeleteTarget(null)
    }
  }

  return (
    <div className="p-4 sm:p-8 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-start sm:items-center justify-between mb-6 sm:mb-8 gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-white mb-1">📞 Emergency Contacts</h1>
          <p className="text-white/40 text-sm">
            Choose who receives your live location and SMS alert when danger is detected.
          </p>
        </div>
        <button onClick={openAdd} className="btn-primary flex items-center gap-2 flex-shrink-0">
          <Plus className="w-4 h-4" /> Add
        </button>
      </div>

      {/* Add / Edit form */}
      {showForm && (
        <div className="card p-6 mb-6 border border-blue-500/20 bg-blue-500/5">
          <h2 className="text-white font-semibold mb-4">
            {editingId ? '✏️ Edit Contact' : '➕ New Contact'}
          </h2>
          <div className="space-y-3">
            <div>
              <label className="section-title">Name</label>
              <input
                className="input"
                placeholder="e.g. Mom"
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              />
            </div>
            <div>
              <label className="section-title">Phone (E.164)</label>
              <input
                className="input"
                placeholder="+1234567890"
                value={form.phone}
                onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                type="tel"
              />
            </div>

            {/* Notification toggles */}
            <div className="space-y-2 pt-1">
              <label className="section-title">Alert when...</label>
              <Toggle
                label="🚨 High danger detected (auto-trigger)"
                checked={form.notifyOnHigh}
                onChange={v => setForm(f => ({ ...f, notifyOnHigh: v }))}
              />
              <Toggle
                label="⚠️ Medium danger detected (after confirmation)"
                checked={form.notifyOnMedium}
                onChange={v => setForm(f => ({ ...f, notifyOnMedium: v }))}
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button onClick={handleSave} disabled={saving} className="btn-primary flex items-center gap-2">
                <Check className="w-4 h-4" />
                {saving ? 'Saving...' : 'Save'}
              </button>
              <button onClick={cancelForm} className="btn-ghost flex items-center gap-2">
                <X className="w-4 h-4" /> Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Contact list */}
      {loading ? (
        <div className="text-center py-16 text-white/30">Loading contacts...</div>
      ) : contacts.length === 0 ? (
        <div className="text-center py-16">
          <Users className="w-12 h-12 text-white/10 mx-auto mb-4" />
          <p className="text-white/40 text-sm">No contacts yet.</p>
          <p className="text-white/25 text-xs mt-1">Add someone to receive your emergency alerts.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {contacts.map(contact => (
            <ContactCard
              key={contact.id}
              contact={contact}
              onEdit={() => openEdit(contact)}
              onDelete={() => handleDelete(contact.id, contact.name)}
            />
          ))}
        </div>
      )}

      {/* Info box */}
      {contacts.length > 0 && (
        <div className="mt-6 card p-4 border border-blue-500/10">
          <p className="text-white/40 text-xs">
            <span className="text-blue-400 font-semibold">
              {contacts.filter(c => c.notify_on_high).length} contact(s)
            </span>{' '}
            will receive an SMS with your live location when a high-danger emergency is triggered.
          </p>
        </div>
      )}

      {/* Delete confirmation modal */}
      {deleteTarget && (
        <ConfirmModal
          title="Remove contact?"
          message={`Remove ${deleteTarget.name} from emergency contacts? They will no longer receive alerts.`}
          confirmLabel="Remove"
          confirmClass="btn-danger"
          onConfirm={confirmDelete}
          onCancel={() => setDeleteTarget(null)}
        />
      )}
    </div>
  )
}

// ── Sub-components ─────────────────────────────────────────────────────────────

function ContactCard({ contact, onEdit, onDelete }) {
  return (
    <div className="card p-4 flex items-center gap-4">
      {/* Avatar */}
      <div className="w-10 h-10 rounded-full bg-blue-600/20 border border-blue-500/20
                      flex items-center justify-center flex-shrink-0">
        <span className="text-blue-400 font-bold text-sm">
          {contact.name.charAt(0).toUpperCase()}
        </span>
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p className="text-white font-medium text-sm truncate">{contact.name}</p>
        <p className="text-white/40 text-xs flex items-center gap-1 mt-0.5">
          <Phone className="w-3 h-3" /> {contact.phone}
        </p>
        <div className="flex gap-2 mt-1.5">
          {contact.notify_on_high && (
            <span className="inline-flex items-center gap-1 text-xs bg-red-500/10 text-red-400
                             border border-red-500/20 rounded-full px-2 py-0.5">
              <Bell className="w-2.5 h-2.5" /> High
            </span>
          )}
          {contact.notify_on_medium && (
            <span className="inline-flex items-center gap-1 text-xs bg-orange-500/10 text-orange-400
                             border border-orange-500/20 rounded-full px-2 py-0.5">
              <Bell className="w-2.5 h-2.5" /> Medium
            </span>
          )}
          {!contact.notify_on_high && !contact.notify_on_medium && (
            <span className="inline-flex items-center gap-1 text-xs bg-white/5 text-white/30
                             border border-white/10 rounded-full px-2 py-0.5">
              <BellOff className="w-2.5 h-2.5" /> No alerts
            </span>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-shrink-0">
        <button
          onClick={onEdit}
          className="w-8 h-8 rounded-lg bg-white/5 hover:bg-white/10 flex items-center justify-center
                     text-white/40 hover:text-white transition-all"
        >
          <Edit3 className="w-3.5 h-3.5" />
        </button>
        <button
          onClick={onDelete}
          className="w-8 h-8 rounded-lg bg-red-500/5 hover:bg-red-500/20 flex items-center justify-center
                     text-red-400/60 hover:text-red-400 transition-all"
        >
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}

function Toggle({ label, checked, onChange }) {
  return (
    <label className="flex items-center gap-3 cursor-pointer group">
      <div
        onClick={() => onChange(!checked)}
        className={`relative w-10 h-5 rounded-full transition-colors duration-200 flex-shrink-0 ${
          checked ? 'bg-blue-600' : 'bg-white/10'
        }`}
      >
        <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow
                          transition-transform duration-200 ${checked ? 'translate-x-5' : ''}`} />
      </div>
      <span className="text-white/60 text-sm group-hover:text-white/80 transition-colors">{label}</span>
    </label>
  )
}
