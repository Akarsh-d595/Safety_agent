import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import HomePage from './pages/HomePage'
import ContactsPage from './pages/ContactsPage'
import HistoryPage from './pages/HistoryPage'
import SettingsPage from './pages/SettingsPage'
import EmergencyPage from './pages/EmergencyPage'
import { SafetyProvider } from './context/SafetyContext'

export default function App() {
  return (
    <SafetyProvider>
      <Routes>
        {/* Emergency screen is full-screen, no layout chrome */}
        <Route path="/emergency" element={<EmergencyPage />} />

        {/* All other pages share the sidebar layout */}
        <Route element={<Layout />}>
          <Route index element={<HomePage />} />
          <Route path="/contacts" element={<ContactsPage />} />
          <Route path="/history"  element={<HistoryPage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </SafetyProvider>
  )
}
