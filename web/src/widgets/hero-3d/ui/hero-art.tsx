'use client';

import dynamic from 'next/dynamic';
import { useEffect, useState } from 'react';

import { HeroFallback } from './hero-fallback';

const AgentsScene = dynamic(
  () => import('./agents-scene').then((module) => module.AgentsScene),
  {
    loading: () => <HeroFallback />,
    ssr: false,
  },
);

const constrainedMotionQuery =
  '(max-width: 767px), (prefers-reduced-motion: reduce)';

/**
 * Client boundary for the hero art: renders the R3F parallel-agents scene
 * on motion-capable desktop viewports and the static glass overview frame
 * everywhere else (small screens, reduced motion, JS loading).
 */
export function HeroArt() {
  const [showFallback, setShowFallback] = useState(true);

  useEffect(() => {
    const mediaQuery = window.matchMedia(constrainedMotionQuery);
    const updatePreference = () => setShowFallback(mediaQuery.matches);

    updatePreference();
    mediaQuery.addEventListener('change', updatePreference);

    return () => mediaQuery.removeEventListener('change', updatePreference);
  }, []);

  if (showFallback) {
    return <HeroFallback />;
  }

  return (
    <div aria-hidden="true" className="absolute inset-0" data-hero-canvas>
      <AgentsScene />
    </div>
  );
}
