import { ArrowDownToLine, MoveRight } from 'lucide-react';

import { siteConfig } from '@/shared/config';
import { Button, Pill, SectionShell } from '@/shared/ui';

export function DownloadCta() {
  return (
    <SectionShell className="py-[5.5rem] pb-[4.875rem] text-center lg:pt-[9.25rem] lg:pb-28">
      <Pill>Ready when the work starts</Pill>
      <h2 className="mx-auto mt-5 max-w-[50rem] text-[clamp(2.75rem,6vw,4.875rem)] leading-[0.99] font-semibold tracking-[-0.06em] text-balance">
        Put the whole run in view.
      </h2>
      <p className="mx-auto mt-[1.3125rem] mb-7 max-w-[31.875rem] text-[17px] text-[#a9b2af]">
        Download the free macOS release from GitHub and let Toki keep the
        activity behind your agents close at hand.
      </p>
      <div className="mb-10 flex flex-wrap items-center justify-center gap-3">
        <Button asChild size="lg" variant="glow">
          <a href={siteConfig.links.latestRelease}>
            Download Toki
            <ArrowDownToLine aria-hidden="true" />
          </a>
        </Button>
        <Button
          asChild
          className="text-sm font-semibold text-[#d7dedb] hover:text-toki-blue"
          size="lg"
          variant="ghost"
        >
          <a href={siteConfig.links.github} rel="noreferrer" target="_blank">
            View source
            <MoveRight aria-hidden="true" />
          </a>
        </Button>
      </div>
      <div className="glass-panel mx-auto max-w-[33.75rem] rounded-2xl p-5 text-left">
        <p className="m-0 font-mono text-[10px] tracking-[0.055em] text-[#9ea8a5] uppercase">
          If macOS flags the unsigned app, clear quarantine once
        </p>
        <pre className="m-0 mt-3 overflow-x-auto rounded-lg bg-black/40 p-3.5 font-mono text-[12px] leading-relaxed text-toki-green">
          <code>xattr -dr com.apple.quarantine /Applications/Toki.app</code>
        </pre>
      </div>
    </SectionShell>
  );
}
