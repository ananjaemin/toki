import { ThemeToggle } from '@/features/theme-toggle';

export function LandingPage() {
  return (
    <main className="relative grid min-h-dvh place-items-center px-6 py-16">
      <div className="absolute right-4 top-4">
        <ThemeToggle />
      </div>
      <div className="max-w-xl text-center">
        <h1 className="text-5xl font-semibold tracking-tight">Toki</h1>
        <p className="mt-4 text-pretty text-lg text-zinc-400">
          Understand your AI coding usage from the macOS menu bar.
        </p>
      </div>
    </main>
  );
}
