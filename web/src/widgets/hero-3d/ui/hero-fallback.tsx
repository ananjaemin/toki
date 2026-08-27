export function HeroFallback() {
  return (
    <div
      aria-hidden="true"
      className="grid h-72 w-full place-items-center overflow-hidden rounded-2xl border bg-muted/40 sm:h-80"
      data-hero-fallback
    >
      <div className="grid size-32 rotate-12 place-items-center rounded-3xl border bg-background text-5xl font-semibold shadow-lg">
        T
      </div>
    </div>
  );
}
