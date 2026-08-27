import Image from 'next/image';

import { GlassCard, Pill, SectionShell } from '@/shared/ui';

type Shot = Readonly<{
  alt: string;
  caption: string;
  src: string;
}>;

const SHOTS: readonly Shot[] = [
  {
    alt: 'Toki Time view',
    caption: 'TIME — DIRECT, DELEGATED, OVERLAP',
    src: '/screenshots/screenshot_time.png',
  },
  {
    alt: 'Toki Projects view',
    caption: 'PROJECTS — ATTRIBUTION IN CONTEXT',
    src: '/screenshots/screenshot_projects.png',
  },
  {
    alt: 'Toki Models view',
    caption: 'MODELS — USAGE AND COST',
    src: '/screenshots/screenshot_models.png',
  },
];

export function ScreenshotStrip() {
  return (
    <section aria-labelledby="screens-title">
      <SectionShell className="py-[6.375rem] lg:py-[8.5rem]">
        <div className="mb-[1.875rem] gap-5 sm:flex sm:items-end sm:justify-between lg:mb-[2.875rem]">
          <div>
            <Pill>Live in the popover</Pill>
            <h2
              className="mt-5 max-w-[31.875rem] text-[clamp(2.4375rem,4.6vw,3.8125rem)] leading-[1.01] font-semibold tracking-[-0.057em] text-balance"
              id="screens-title"
            >
              The context stays close.
            </h2>
          </div>
          <p className="mt-3.5 max-w-[16.25rem] font-mono text-[11px] leading-[1.6] text-[#8d9693] sm:mt-0 sm:text-right">
            SIX FOCUSED VIEWS
            <br />
            ONE MENU-BAR HOME
          </p>
        </div>
        <div className="grid items-end gap-3 md:grid-cols-[1.05fr_0.78fr_0.78fr] md:gap-[1.125rem]">
          {SHOTS.map((shot, index) => (
            <GlassCard
              className={`rounded-[19px] p-2 shadow-[inset_0_1px_rgba(255,255,255,0.06),0_22px_38px_rgba(0,0,0,0.25)] transition-[border-color,transform] duration-300 hover:-translate-y-[7px] hover:border-[rgba(136,112,240,0.35)] sm:p-2.5 ${
                index === 0 ? 'md:-translate-y-[1.8125rem]' : ''
              }`}
              key={shot.src}
            >
              <figure className="m-0">
                <Image
                  alt={shot.alt}
                  className="w-full rounded-[11px]"
                  height={840}
                  sizes="(max-width: 767px) 92vw, 30vw"
                  src={shot.src}
                  width={640}
                />
                <figcaption className="px-1 pt-3 pb-[3px] font-mono text-[10px] tracking-[0.045em] text-[#99a29f]">
                  {shot.caption}
                </figcaption>
              </figure>
            </GlassCard>
          ))}
        </div>
      </SectionShell>
    </section>
  );
}
