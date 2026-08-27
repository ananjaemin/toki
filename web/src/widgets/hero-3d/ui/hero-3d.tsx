import { ArrowDownToLine, MoveRight } from 'lucide-react';

import { siteConfig } from '@/shared/config';
import { Button, Pill, SectionShell } from '@/shared/ui';

import { HeroArt } from './hero-art';

export function Hero3D() {
  return (
    <SectionShell className="relative pt-12 pb-20 lg:pt-[5.8rem] lg:pb-[5.4rem]">
      <div className="grid items-center gap-10 lg:grid-cols-[minmax(0,0.9fr)_minmax(26.25rem,1.1fr)] lg:gap-[clamp(2.6rem,7vw,6.9rem)]">
        <div className="text-center lg:text-left">
          <Pill>Local-first menu bar app</Pill>
          <h1 className="mx-auto mt-5 mb-6 max-w-[39.4rem] text-[clamp(3.25rem,6.45vw,5.5rem)] leading-[0.99] font-semibold tracking-[-0.061em] text-balance lg:mx-0">
            The work beneath{' '}
            <span className="text-toki-green">the output.</span>
          </h1>
          <p className="mx-auto mb-7 max-w-[30.3rem] text-lg leading-[1.55] tracking-[-0.025em] text-[#bec6c3] lg:mx-0">
            Toki makes the moving parts of AI-assisted work legible: tokens,
            cost, project attribution, and the time agents actually spend
            working.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3 lg:justify-start">
            <Button asChild size="lg" variant="glow">
              <a href={siteConfig.links.latestRelease}>
                Download free release
                <ArrowDownToLine aria-hidden="true" />
              </a>
            </Button>
            <Button
              asChild
              className="text-sm font-semibold text-[#d7dedb] hover:text-toki-blue"
              size="lg"
              variant="ghost"
            >
              <a href="#time">
                See how time works
                <MoveRight aria-hidden="true" />
              </a>
            </Button>
          </div>
          <div className="mt-11 flex items-center justify-center gap-3 font-mono text-[11px] text-[#818c88] before:h-px before:w-[2.125rem] before:bg-toki-line before:content-[''] lg:justify-start">
            MACOS · LOCAL DATA · GITHUB RELEASES
          </div>
        </div>
        <div
          aria-label="Visualization of parallel agent activity"
          className="relative min-h-[26rem] sm:min-h-[31rem] lg:min-h-[40.6rem]"
          role="img"
        >
          <HeroArt />
          <div className="glass-panel absolute top-[18%] left-0 z-[3] rounded-[15px] bg-gradient-to-br from-[rgba(18,20,22,0.82)] to-[rgba(31,38,37,0.63)] px-4 py-3.5 font-mono backdrop-blur-lg">
            <span className="block text-[10px] tracking-[0.055em] text-[#9ea8a5]">
              AI WORK TIME
            </span>
            <strong className="mt-1 block text-xl font-medium tracking-[-0.05em] tabular-nums">
              4h 13m
            </strong>
          </div>
          <div className="glass-panel absolute right-0 bottom-[17%] z-[3] rounded-[15px] bg-gradient-to-br from-[rgba(18,20,22,0.82)] to-[rgba(31,38,37,0.63)] px-4 py-3.5 font-mono backdrop-blur-lg">
            <span className="block text-[10px] tracking-[0.055em] text-[#9ea8a5]">
              PARALLEL
            </span>
            <strong className="mt-1 block text-xl font-medium tracking-[-0.05em] text-toki-blue tabular-nums">
              1.21×
            </strong>
          </div>
        </div>
      </div>
    </SectionShell>
  );
}
