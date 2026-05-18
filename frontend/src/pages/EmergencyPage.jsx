import { useEffect, useRef, useState } from 'react'
import { AlertTriangle, Phone, MapPin, ShieldCheck, ExternalLink } from 'lucide-react'
import { useSafety } from '../context/SafetyContext'
import { useDevice } from '../hooks/useDevice'
import ConfirmModal from '../components/ConfirmModal'

export default function EmergencyPage() {
  const { location, contacts, reset } = useSafety()
  const { canCall }  = useDevice()
  const pulseRef     = useRef(null)
  const [showCancel, setShowCancel] = useState(false)

  // CSS-driven pulse animation (no JS interval needed)
  // The div uses the Tailwind animate-pulse-fast class defined in tailwind.config

  const alertedContacts = contacts.filter(c => c.notify_on_high)
  const mapsLink = location
    ? `https://www.google.com/maps?q=${location.latitude},${location.longitude}`
    : null

  function handleCallPress() {
    if (canCall) {
      // Mobile — tel: link works
      window.location.href = 'tel:112'
    } else {
      // Desktop — open a new tab with a dialler-style page or just show the number
      window.open('tel:112', '_blank')
    }
  }

  return (
    <div className="min-h-screen bg-red-950 flex flex-col items-center justify-center
                    p-6 sm:p-8 safe-area-top safe-area-bottom">

      {/* Pulsing icon */}
      <div
        ref={pulseRef}
        className="w-32 h-32 sm:w-36 sm:h-36 rounded-full bg-red-800 border-4 border-red-500
                   flex items-center justify-center mb-6 sm:mb-8
                   shadow-[0_0_60px_rgba(239,68,68,0.5)]
                   animate-pulse"
      >
        <AlertTriangle className="w-16 h-16 sm:w-20 sm:h-20 text-white" />
      </div>

      {/* Title */}
      <h1 className="text-3xl sm:text-4xl font-black text-white mb-3
                     tracking-tight text-center leading-tight">
        🚨 EMERGENCY ACTIVATED
      </h1>
      <p className="text-red-200 text-base sm:text-lg text-center mb-6 sm:mb-8 max-w-md">
        Emergency protocol is active.<br />Help is being contacted.
      </p>

      {/* Info cards */}
      <div className="w-full max-w-md space-y-3 mb-6 sm:mb-8">

        {/* Location */}
        <div className="bg-white/10 rounded-2xl p-4 flex items-start gap-3">
          <MapPin className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
          <div className="min-w-0">
            <p className="text-white/60 text-xs font-bold uppercase tracking-wider mb-1">
              Location Shared
            </p>
            {location ? (
              <a
                href={mapsLink}
                target="_blank"
                rel="noreferrer"
                className="text-green-400 text-sm underline underline-offset-2
                           flex items-center gap-1 break-all"
              >
                {location.latitude.toFixed(5)}, {location.longitude.toFixed(5)}
                <ExternalLink className="w-3 h-3 flex-shrink-0" />
              </a>
            ) : (
              <p className="text-white/40 text-sm">Location unavailable</p>
            )}
          </div>
        </div>

        {/* Alerted contacts */}
        <div className="bg-white/10 rounded-2xl p-4">
          <p className="text-white/60 text-xs font-bold uppercase tracking-wider mb-2">
            Contacts Alerted
          </p>
          {alertedContacts.length > 0 ? (
            <ul className="space-y-1.5">
              {alertedContacts.map(c => (
                <li key={c.id} className="flex items-center gap-2 text-sm text-white">
                  <span className="w-2 h-2 rounded-full bg-green-400 flex-shrink-0" />
                  <span className="font-medium">{c.name}</span>
                  <span className="text-white/40 text-xs">{c.phone}</span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-white/40 text-sm">
              No contacts configured. Add contacts in the Contacts page.
            </p>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="w-full max-w-md space-y-3">

        {/* Call button — works on mobile; shows number on desktop */}
        {canCall ? (
          <a
            href="tel:112"
            className="w-full flex items-center justify-center gap-3
                       bg-white/15 hover:bg-white/25 active:bg-white/30
                       border-2 border-white text-white font-bold text-lg
                       py-4 rounded-2xl transition-all duration-200
                       touch-manipulation no-underline"
          >
            <Phone className="w-6 h-6" />
            CALL 112 NOW
          </a>
        ) : (
          /* Desktop fallback — show the number prominently */
          <div className="w-full flex flex-col items-center gap-2
                          bg-white/10 border-2 border-white/30
                          py-4 rounded-2xl text-center">
            <div className="flex items-center gap-2 text-white font-bold text-lg">
              <Phone className="w-6 h-6" />
              Emergency Number: <span className="text-red-300 text-2xl">112</span>
            </div>
            <p className="text-white/40 text-xs">
              Call 112 from your phone or dial your local emergency number
            </p>
          </div>
        )}

        {/* Cancel */}
        <button
          onClick={() => setShowCancel(true)}
          className="w-full text-white/40 hover:text-white/70 text-sm py-3
                     transition-colors underline underline-offset-4
                     touch-manipulation"
        >
          <ShieldCheck className="w-4 h-4 inline mr-2" />
          I'm Safe — Cancel Emergency
        </button>
      </div>

      {/* Cancel confirmation modal (replaces window.confirm) */}
      {showCancel && (
        <ConfirmModal
          title="Are you safe?"
          message="This will cancel the emergency protocol. Only confirm if you are truly safe."
          confirmLabel="Yes, I'm Safe"
          confirmClass="btn-primary"
          onConfirm={() => { setShowCancel(false); reset() }}
          onCancel={() => setShowCancel(false)}
        />
      )}
    </div>
  )
}
