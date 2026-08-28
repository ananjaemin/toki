import { ArrowDownToLine, MoveRight } from 'lucide-react';

import { siteConfig } from '@/shared/config';
import { cn } from '@/shared/lib/cn';
import { Button, Pill, SectionShell } from '@/shared/ui';

import { HeroArt } from './hero-art';

type HeroMetricProps = Readonly<{
  className: string;
  label: string;
  value: string;
}>;

function HeroMetric({ className, label, value }: HeroMetricProps) {
  return (
    <div
      className={cn(
        'glass-panel absolute z-[3] rounded-[15px] bg-gradient-to-br from-[rgba(18,20,22,0.82)] to-[rgba(31,38,37,0.63)] px-4 py-3.5 font-mono backdrop-blur-lg',
        className,
      )}
    >
      <span className="block text-[10px] tracking-[0.055em] text-[#9ea8a5]">
        {label}
      </span>
      <strong className="mt-1 block text-xl font-medium tracking-[-0.05em] tabular-nums">
        {value}
      </strong>
    </div>
  );
}

export function Hero3D() {
  return (
    <SectionShell className="relative pt-12 pb-20 lg:pt-[5.8rem] lg:pb-[5.4rem]">
      <div className="grid items-center gap-10 lg:grid-cols-[minmax(0,1.1fr)_minmax(26.25rem,0.9fr)] lg:gap-[clamp(2.5rem,4vw,4.5rem)]">
        <div className="text-left">
          <Pill>Local-first menu bar app</Pill>
          <h1 className="mt-5 mb-7 max-w-[43rem] text-[clamp(2.5rem,4.75vw,4.5rem)] leading-[0.97] font-semibold tracking-[-0.061em] text-balance">
            <span className="block">The work</span>
            <span className="block lg:whitespace-nowrap">
              <span className="text-toki-purple">beneath</span> the output.
            </span>
          </h1>
          <p className="max-w-[34rem] text-[clamp(1.25rem,1.8vw,1.375rem)] leading-[1.45] tracking-[-0.025em] text-[#d3dad7]">
            Toki makes the moving parts of AI-assisted work legible.
          </p>
          <p className="mt-3.5 mb-7 max-w-[31rem] text-[17px] leading-[1.55] tracking-[-0.025em] text-[#aab3b0]">
            Track tokens, cost, project attribution, and the time agents
            actually spend working.
          </p>
          <div className="flex flex-wrap items-center justify-start gap-3">
            <Button asChild size="lg" variant="glow">
              <a href={siteConfig.links.latestRelease}>
                Download Toki
                <ArrowDownToLine aria-hidden="true" />
              </a>
            </Button>
            <Button
              asChild
              className="text-sm font-semibold text-[#d7dedb] hover:text-toki-purple"
              size="lg"
              variant="ghost"
            >
              <a href="#time">
                See how time works
                <MoveRight aria-hidden="true" />
              </a>
            </Button>
          </div>
          <div className="mt-6 flex items-center font-mono text-[11px] text-[#818c88]">
            MACOS · LOCAL DATA · GITHUB RELEASES
          </div>
        </div>
        <div
          aria-label="Visualization of parallel agent activity"
          className="relative min-h-[26rem] sm:min-h-[31rem] lg:min-h-[40.6rem]"
          role="img"
        >
          <HeroArt />
          <HeroMetric
            className="top-[18%] left-0"
            label="AI WORK TIME"
            value="4h 13m"
          />
          <HeroMetric
            className="right-0 bottom-[17%]"
            label="PARALLEL"
            value="1.21×"
          />
        </div>
      </div>
    </SectionShell>
  );
}
