/**
 * ConfirmModal — replaces window.confirm() which is blocked on iOS Safari
 * in some contexts (cross-origin iframes, PWA standalone mode).
 */
export default function ConfirmModal({ title, message, confirmLabel = 'Confirm',
                                       confirmClass = 'btn-danger',
                                       onConfirm, onCancel }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center
                    p-4 bg-black/70 backdrop-blur-sm">
      <div className="bg-dark-800 border border-white/10 rounded-2xl p-6
                      w-full max-w-sm shadow-2xl">
        <h2 className="text-white font-bold text-lg mb-2">{title}</h2>
        <p className="text-white/50 text-sm mb-6">{message}</p>
        <div className="flex gap-3">
          <button onClick={onCancel}  className="btn-ghost flex-1">Cancel</button>
          <button onClick={onConfirm} className={`${confirmClass} flex-1`}>{confirmLabel}</button>
        </div>
      </div>
    </div>
  )
}
