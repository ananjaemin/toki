import { Pill, Reveal, SectionShell } from '@/shared/ui';

export function PrivacyPanel() {
  return (
    <section
      className="relative overflow-hidden py-[4.875rem] lg:py-[7.4375rem]"
      id="privacy"
    >
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_64%_56%_at_74%_50%,rgba(136,112,240,0.12),transparent_70%)]"
      />
      <SectionShell className="relative border-y border-toki-line py-[1.125rem] pb-[2.125rem] lg:py-[2.8125rem]">
        <Reveal className="grid items-center gap-9 lg:grid-cols-[minmax(0,1fr)_minmax(17.5rem,0.78fr)] lg:gap-20">
          <div>
            <Pill>Private by default</Pill>
            <h2 className="mt-5 mb-[1.125rem] max-w-[36.25rem] text-[clamp(2.375rem,4.4vw,3.625rem)] leading-[1.02] font-semibold tracking-[-0.055em] text-balance">
              Your usage stays yours.
            </h2>
            <p className="max-w-[32.5rem] text-base text-toki-mist lg:text-[17px]">
              Local collection stays on-device. Toki reads supported local
              stores to build its view; no hosted account is required for local
              use.
            </p>
          </div>
          <div
            aria-hidden="true"
            className="grid h-[6.75rem] w-40 place-items-center justify-self-center rounded-full border border-[rgba(136,112,240,0.3)] bg-[rgba(136,112,240,0.05)] shadow-[inset_0_0_50px_rgba(136,112,240,0.09),0_0_80px_rgba(136,112,240,0.09)] lg:h-[11.5rem] lg:w-[17rem] lg:justify-self-end"
          >
            <svg
              className="w-[6.25rem] fill-none stroke-toki-purple stroke-[1.25] lg:w-[9.5rem]"
              role="presentation"
              viewBox="0 0 120 72"
            >
              <path className="opacity-45" d="M9 36h19" />
              <path className="opacity-45" d="M92 36h19" />
              <circle className="opacity-45" cx="5" cy="36" r="1.25" />
              <circle className="opacity-45" cx="115" cy="36" r="1.25" />
              <path d="M60 14 80 21.5v10.8c0 10.7-8.25 18.2-20 25.2-11.75-7-20-14.5-20-25.2V21.5L60 14Z" />
              <path d="m50 36.5 5.6 5.4 12.3-12.1" />
            </svg>
          </div>
        </Reveal>
      </SectionShell>
    </section>
  );
}
