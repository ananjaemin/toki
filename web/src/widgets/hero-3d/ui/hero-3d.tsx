'use client';

import { useFrame } from '@react-three/fiber';
import dynamic from 'next/dynamic';
import { Suspense, useEffect, useRef, useState } from 'react';
import type { Mesh } from 'three';

import { HeroFallback } from './hero-fallback';

const DynamicCanvas = dynamic(
  () => import('@react-three/fiber').then((module) => module.Canvas),
  {
    loading: () => <HeroFallback />,
    ssr: false,
  },
);

const constrainedMotionQuery =
  '(max-width: 767px), (prefers-reduced-motion: reduce)';

function RotatingMesh() {
  const meshRef = useRef<Mesh>(null);

  useFrame((_state, delta) => {
    if (!meshRef.current) {
      return;
    }

    meshRef.current.rotation.x += delta * 0.22;
    meshRef.current.rotation.y += delta * 0.38;
  });

  return (
    <mesh ref={meshRef} rotation={[0.35, 0.6, 0]}>
      <icosahedronGeometry args={[1.25, 1]} />
      <meshStandardMaterial color="#d4d4d8" metalness={0.25} roughness={0.42} />
    </mesh>
  );
}

export function Hero3D() {
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
    <div
      aria-hidden="true"
      className="h-72 w-full overflow-hidden rounded-2xl border bg-muted/40 sm:h-80"
      data-hero-canvas
    >
      <Suspense fallback={<HeroFallback />}>
        <DynamicCanvas
          camera={{ fov: 42, position: [0, 0, 4.2] }}
          dpr={[1, 1.5]}
          fallback={<HeroFallback />}
          gl={{
            alpha: true,
            antialias: true,
            powerPreference: 'high-performance',
          }}
        >
          <ambientLight intensity={1.4} />
          <directionalLight intensity={2.6} position={[3, 4, 5]} />
          <directionalLight intensity={0.8} position={[-4, -2, 2]} />
          <RotatingMesh />
        </DynamicCanvas>
      </Suspense>
    </div>
  );
}
