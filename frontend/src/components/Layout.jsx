import { Outlet, NavLink } from 'react-router-dom'
import { Shield, Home, Users, History, Settings, Wifi, WifiOff } from 'lucide-react'
import { useSafety } from '../context/SafetyContext'
import { useDevice } from '../hooks/useDevice'

const NAV = [
  { to: '/',         icon: Home,     label: 'Home'     },
  { to: '/contacts', icon: Users,    label: 'Contacts' },
  { to: '/history',  icon: History,  label: 'History'  },
  { to: '/settings', icon: Settings, label: 'Settings' },
]

export default function Layout() {
  const { settings } = useSafety()
  const { isNarrow }  = useDevice()
  const online        = settings.backendOnline

  return isNarrow
    ? <MobileLayout online={online} />
    : <DesktopLayout online={online} />
}

/* ── Desktop: sidebar ──────────────────────────────────────────────────────── */
function DesktopLayout({ online }) {
  return (
    <div className="flex h-screen overflow-hidden bg-dark-900">
      <aside className="w-64 flex-shrink-0 bg-dark-800 border-r border-white/5 flex flex-col">
        <Logo />
        <nav className="flex-1 p-4 space-y-1">
          {NAV.map(({ to, icon: Icon, label }) => (
            <SidebarLink key={to} to={to} icon={Icon} label={label} />
          ))}
        </nav>
        <BackendBadge online={online} />
      </aside>
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>
    </div>
  )
}

/* ── Mobile: bottom tab bar ────────────────────────────────────────────────── */
function MobileLayout({ online }) {
  return (
    <div className="flex flex-col h-screen bg-dark-900">
      {/* Top bar */}
      <header className="flex-shrink-0 bg-dark-800 border-b border-white/5
                         flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-2">
          <Shield className="w-5 h-5 text-blue-400" />
          <span className="font-bold text-white text-sm">AI Safety</span>
        </div>
        <div className={`flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full ${
          online
            ? 'bg-green-500/10 text-green-400'
            : 'bg-orange-500/10 text-orange-400'
        }`}>
          {online ? <Wifi className="w-3 h-3" /> : <WifiOff className="w-3 h-3" />}
          {online ? 'Online' : 'Offline'}
        </div>
      </header>

      {/* Page content — scrollable */}
      <main className="flex-1 overflow-y-auto pb-20">
        <Outlet />
      </main>

      {/* Bottom tab bar */}
      <nav className="fixed bottom-0 inset-x-0 bg-dark-800 border-t border-white/5
                      flex items-center tab-bar-safe z-40">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex-1 flex flex-col items-center gap-1 pt-3 pb-1 text-xs font-medium
               min-h-touch transition-colors duration-150 touch-manipulation ${
                isActive ? 'text-blue-400' : 'text-white/40 active:text-white/70'
              }`
            }
          >
            <Icon className="w-5 h-5" />
            {label}
          </NavLink>
        ))}
      </nav>
    </div>
  )
}

/* ── Shared sub-components ─────────────────────────────────────────────────── */
function Logo() {
  return (
    <div className="p-6 border-b border-white/5">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-blue-600/20 border border-blue-500/30
                        flex items-center justify-center">
          <Shield className="w-5 h-5 text-blue-400" />
        </div>
        <div>
          <p className="font-bold text-white text-sm leading-tight">AI Safety</p>
          <p className="text-white/40 text-xs">Emergency System</p>
        </div>
      </div>
    </div>
  )
}

function SidebarLink({ to, icon: Icon, label }) {
  return (
    <NavLink
      to={to}
      end={to === '/'}
      className={({ isActive }) =>
        `flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium
         transition-all duration-150 ${
          isActive
            ? 'bg-blue-600/20 text-blue-400 border border-blue-500/20'
            : 'text-white/50 hover:text-white hover:bg-white/5'
        }`
      }
    >
      <Icon className="w-4 h-4" />
      {label}
    </NavLink>
  )
}

function BackendBadge({ online }) {
  return (
    <div className="p-4 border-t border-white/5">
      <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium ${
        online
          ? 'bg-green-500/10 text-green-400'
          : 'bg-orange-500/10 text-orange-400'
      }`}>
        {online
          ? <><Wifi className="w-3.5 h-3.5" /> Backend connected</>
          : <><WifiOff className="w-3.5 h-3.5" /> Backend offline</>
        }
      </div>
    </div>
  )
}
