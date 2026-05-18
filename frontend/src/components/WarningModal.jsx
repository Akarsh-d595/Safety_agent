import { AlertTriangle, ShieldCheck, X } from 'lucide-react'

/**
 * Modal shown when medium danger is detected.
 * Asks the user to confirm before triggering the full emergency protocol.
 */
export default function WarningModal({ onConfirm, onDismiss }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-dark-800 border border-orange-500/30 rounded-2xl p-6 max-w-sm w-full shadow-2xl">
        {/* Icon */}
        <div className="flex justify-center mb-4">
          <div className="w-16 h-16 rounded-full bg-orange-500/10 border border-orange-500/30
                          flex items-center justify-center">
            <AlertTriangle className="w-8 h-8 text-orange-400" />
          </div>
        </div>

        {/* Text */}
        <h2 className="text-white font-bold text-lg text-center mb-2">Potential Danger Detected</h2>
        <p className="text-white/50 text-sm text-center mb-6">
          I sense you might be in danger.<br />
          Do you want to activate emergency support?
        </p>

        {/* Actions */}
        <div className="flex gap-3">
          <button
            onClick={onDismiss}
            className="btn-ghost flex-1 flex items-center justify-center gap-2"
          >
            <ShieldCheck className="w-4 h-4" /> I'm Safe
          </button>
          <button
            onClick={onConfirm}
            className="btn-danger flex-1 flex items-center justify-center gap-2"
          >
            <AlertTriangle className="w-4 h-4" /> Get Help
          </button>
        </div>
      </div>
    </div>
  )
}
