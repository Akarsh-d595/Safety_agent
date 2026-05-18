/**
 * useDevice — detects screen size and platform capabilities.
 * Used to render mobile-optimised UI vs desktop UI.
 */
import { useState, useEffect } from 'react'

function getInfo() {
  const ua      = navigator.userAgent || ''
  const isMobile = /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(ua)
  const isIOS    = /iPhone|iPad|iPod/i.test(ua)
  const isSafari = /^((?!chrome|android).)*safari/i.test(ua)
  const canCall  = isMobile   // tel: links only work reliably on mobile
  const isNarrow = window.innerWidth < 768

  return { isMobile, isIOS, isSafari, canCall, isNarrow }
}

export function useDevice() {
  const [info, setInfo] = useState(getInfo)

  useEffect(() => {
    const handler = () => setInfo(getInfo())
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  return info
}
