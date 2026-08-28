'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { Bloom, EffectComposer } from '@react-three/postprocessing';
import { useEffect, useMemo, useRef, useState } from 'react';
import {
  AdditiveBlending,
  BufferAttribute,
  BufferGeometry,
  CanvasTexture,
  Color,
  type Mesh,
  type Points,
  type Texture,
} from 'three';

import { HeroFallback } from './hero-fallback';

const TWO_PI = Math.PI * 2;

type StreamConfig = Readonly<{
  color: string;
  count: number;
  headOffset: number;
  radius: number;
  size: number;
  speed: number;
  tilt: readonly [number, number, number];
}>;

/**
 * The parallel-agents narrative: a luminous main-agent core, orbited by
 * subagent particle streams on differently inclined planes. Each stream is
 * a single THREE.Points draw call; additive blending makes the brightness
 * visibly stack where orbits overlap, echoing Toki's parallel multiplier.
 */
const ORBIT_STREAMS: readonly StreamConfig[] = [
  {
    color: '#78c898',
    count: 720,
    headOffset: 0.4,
    radius: 2.05,
    size: 0.055,
    speed: 0.16,
    tilt: [0.52, 0, 0.34],
  },
  {
    color: '#78a8f8',
    count: 640,
    headOffset: 2.6,
    radius: 1.58,
    size: 0.05,
    speed: -0.23,
    tilt: [-0.74, 0.42, -0.48],
  },
  {
    color: '#ed87af',
    count: 560,
    headOffset: 4.4,
    radius: 2.5,
    size: 0.046,
    speed: 0.11,
    tilt: [1.16, -0.22, 0.6],
  },
];

const DUST_COUNT = 420;

function createGlowTexture(): Texture {
  const size = 64;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext('2d');
  if (context) {
    const gradient = context.createRadialGradient(32, 32, 0, 32, 32, 32);
    gradient.addColorStop(0, 'rgba(255,255,255,1)');
    gradient.addColorStop(0.32, 'rgba(255,255,255,0.5)');
    gradient.addColorStop(1, 'rgba(255,255,255,0)');
    context.fillStyle = gradient;
    context.fillRect(0, 0, size, size);
  }
  return new CanvasTexture(canvas);
}

function buildOrbitGeometry(config: StreamConfig): BufferGeometry {
  const positions = new Float32Array(config.count * 3);
  const colors = new Float32Array(config.count * 3);
  const base = new Color(config.color);
  for (let index = 0; index < config.count; index += 1) {
    const angle = (index / config.count) * TWO_PI;
    const radius = config.radius + (Math.random() - 0.5) * 0.26;
    positions[index * 3] = Math.cos(angle) * radius;
    positions[index * 3 + 1] = (Math.random() - 0.5) * 0.17;
    positions[index * 3 + 2] = Math.sin(angle) * radius;
    const cometPhase = (Math.cos(angle - config.headOffset) + 1) / 2;
    const brightness = 0.14 + 0.86 * cometPhase ** 3 + Math.random() * 0.1;
    colors[index * 3] = base.r * brightness;
    colors[index * 3 + 1] = base.g * brightness;
    colors[index * 3 + 2] = base.b * brightness;
  }
  const orbit = new BufferGeometry();
  orbit.setAttribute('position', new BufferAttribute(positions, 3));
  orbit.setAttribute('color', new BufferAttribute(colors, 3));
  return orbit;
}

function buildDustGeometry(): BufferGeometry {
  const positions = new Float32Array(DUST_COUNT * 3);
  const colors = new Float32Array(DUST_COUNT * 3);
  const base = new Color('#aa8bff');
  for (let index = 0; index < DUST_COUNT; index += 1) {
    const theta = Math.random() * TWO_PI;
    const phi = Math.acos(2 * Math.random() - 1);
    const radius = 2.6 + Math.random() * 1.9;
    positions[index * 3] = radius * Math.sin(phi) * Math.cos(theta);
    positions[index * 3 + 1] = radius * Math.cos(phi) * 0.62;
    positions[index * 3 + 2] = radius * Math.sin(phi) * Math.sin(theta);
    const brightness = 0.05 + Math.random() * 0.16;
    colors[index * 3] = base.r * brightness;
    colors[index * 3 + 1] = base.g * brightness;
    colors[index * 3 + 2] = base.b * brightness;
  }
  const dust = new BufferGeometry();
  dust.setAttribute('position', new BufferAttribute(positions, 3));
  dust.setAttribute('color', new BufferAttribute(colors, 3));
  return dust;
}

type OrbitStreamProps = Readonly<{
  config: StreamConfig;
  sprite: Texture;
}>;

function OrbitStream({ config, sprite }: OrbitStreamProps) {
  const pointsRef = useRef<Points>(null);
  const geometry = useMemo(() => buildOrbitGeometry(config), [config]);

  useEffect(() => () => geometry.dispose(), [geometry]);

  useFrame((_state, delta) => {
    if (!pointsRef.current) {
      return;
    }
    pointsRef.current.rotation.y += delta * config.speed;
  });

  return (
    <group rotation={[config.tilt[0], config.tilt[1], config.tilt[2]]}>
      <points ref={pointsRef} geometry={geometry}>
        <pointsMaterial
          blending={AdditiveBlending}
          depthWrite={false}
          map={sprite}
          size={config.size}
          sizeAttenuation
          transparent
          vertexColors
        />
      </points>
    </group>
  );
}

type DustFieldProps = Readonly<{
  sprite: Texture;
}>;

function DustField({ sprite }: DustFieldProps) {
  const pointsRef = useRef<Points>(null);
  const geometry = useMemo(buildDustGeometry, []);

  useEffect(() => () => geometry.dispose(), [geometry]);

  useFrame((_state, delta) => {
    if (!pointsRef.current) {
      return;
    }
    pointsRef.current.rotation.y += delta * 0.014;
  });

  return (
    <points ref={pointsRef} geometry={geometry}>
      <pointsMaterial
        blending={AdditiveBlending}
        depthWrite={false}
        map={sprite}
        size={0.028}
        sizeAttenuation
        transparent
        vertexColors
      />
    </points>
  );
}

type AgentCoreProps = Readonly<{
  sprite: Texture;
}>;

function AgentCore({ sprite }: AgentCoreProps) {
  const coreRef = useRef<Mesh>(null);

  useFrame((state) => {
    if (!coreRef.current) {
      return;
    }
    const pulse = 1 + Math.sin(state.clock.elapsedTime * 1.6) * 0.045;
    coreRef.current.scale.setScalar(pulse);
  });

  return (
    <group>
      <mesh ref={coreRef}>
        <icosahedronGeometry args={[0.4, 4]} />
        <meshBasicMaterial color="#6955a5" toneMapped={false} />
      </mesh>
      <sprite scale={[3, 3, 1]}>
        <spriteMaterial
          blending={AdditiveBlending}
          color="#2e2454"
          depthWrite={false}
          map={sprite}
          opacity={0.36}
          transparent
        />
      </sprite>
    </group>
  );
}

/** Subtle desktop-only camera drift toward the pointer. */
function ParallaxRig() {
  useFrame((state) => {
    const { camera, pointer } = state;
    camera.position.x += (pointer.x * 0.55 - camera.position.x) * 0.045;
    camera.position.y += (0.15 + pointer.y * 0.35 - camera.position.y) * 0.045;
    camera.lookAt(0, 0, 0);
  });
  return null;
}

export function AgentsScene() {
  const canvasWrapperRef = useRef<HTMLDivElement>(null);
  const [isDocumentVisible, setIsDocumentVisible] = useState(false);
  const [isInViewport, setIsInViewport] = useState(false);
  const sprite = useMemo(createGlowTexture, []);
  const frameloop = isDocumentVisible && isInViewport ? 'always' : 'never';

  useEffect(() => () => sprite.dispose(), [sprite]);

  // Stop the render loop unless both the tab and the hero are visible.
  useEffect(() => {
    const syncVisibility = () => setIsDocumentVisible(!document.hidden);
    syncVisibility();
    document.addEventListener('visibilitychange', syncVisibility);
    return () =>
      document.removeEventListener('visibilitychange', syncVisibility);
  }, []);

  useEffect(() => {
    const canvasWrapper = canvasWrapperRef.current;
    if (!canvasWrapper) {
      return;
    }

    if (typeof IntersectionObserver === 'undefined') {
      setIsInViewport(true);
      return;
    }

    const observer = new IntersectionObserver(([entry]) => {
      setIsInViewport(entry?.isIntersecting ?? false);
    });
    observer.observe(canvasWrapper);

    return () => observer.disconnect();
  }, []);

  return (
    <div
      className="absolute inset-0 [mask-image:radial-gradient(ellipse_60%_60%_at_50%_50%,black_20%,transparent_82%)] [-webkit-mask-image:radial-gradient(ellipse_60%_60%_at_50%_50%,black_20%,transparent_82%)]"
      ref={canvasWrapperRef}
    >
      <Canvas
        camera={{ fov: 42, position: [0, 0.15, 6.3] }}
        dpr={[1, 2]}
        fallback={<HeroFallback />}
        frameloop={frameloop}
        gl={{
          alpha: true,
          antialias: false,
          powerPreference: 'high-performance',
        }}
        onCreated={({ gl }) => {
          gl.setClearColor(0x0a0a0c, 0);
          gl.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        }}
      >
        <color args={['#0a0a0c']} attach="background" />
        <ParallaxRig />
        <AgentCore sprite={sprite} />
        {ORBIT_STREAMS.map((config) => (
          <OrbitStream config={config} key={config.color} sprite={sprite} />
        ))}
        <DustField sprite={sprite} />
        <EffectComposer multisampling={0}>
          <Bloom
            intensity={0.55}
            luminanceSmoothing={0.38}
            luminanceThreshold={0.3}
            mipmapBlur
          />
        </EffectComposer>
      </Canvas>
    </div>
  );
}
