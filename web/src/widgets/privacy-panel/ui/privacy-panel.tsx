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
            className="grid aspect-square w-[8.25rem] place-items-center justify-self-start rounded-full border border-[rgba(136,112,240,0.3)] bg-[rgba(136,112,240,0.05)] shadow-[inset_0_0_50px_rgba(136,112,240,0.09),0_0_80px_rgba(136,112,240,0.09)] lg:w-[13.75rem] lg:justify-self-end"
          >
            <svg
              className="w-12 fill-none stroke-toki-purple stroke-[1.25] lg:w-[4.3125rem]"
              role="presentation"
              viewBox="0 0 80 80"
            >
              <path d="M40 10 60 18v17c0 15-8.5 27-20 34-11.5-7-20-19-20-34V18l20-8Z" />
              <path d="M31 40l6 6 13-14" />
            </svg>
          </div>
        </Reveal>
      </SectionShell>
    </section>
  );
}
