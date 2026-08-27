import { ArrowDownToLine, ExternalLink } from 'lucide-react';

import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';
import type { GitHubRelease } from '@/entities/release';
import { siteConfig } from '@/shared/config';
import { Button, GlassCard, Pill, SectionShell } from '@/shared/ui';

const latestRelease: Pick<GitHubRelease, 'html_url'> = {
  html_url: siteConfig.links.latestRelease,
};

export function DownloadPage() {
  return (
    <div className="luminous flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex-1">
        <SectionShell className="py-16 sm:py-24">
          <Pill>macOS · GitHub releases</Pill>
          <h1 className="mt-5 text-4xl font-semibold tracking-[-0.055em] text-balance sm:text-5xl">
            Download Toki
          </h1>
          <p className="mt-5 max-w-2xl text-lg leading-8 text-toki-mist">
            Get the latest macOS release from GitHub, move Toki to Applications,
            and launch it from your menu bar.
          </p>
          <Button asChild className="mt-8" size="lg" variant="glow">
            <a href={latestRelease.html_url} target="_blank" rel="noreferrer">
              <ArrowDownToLine aria-hidden="true" />
              Latest release
              <ExternalLink aria-hidden="true" />
            </a>
          </Button>

          <GlassCard className="mt-14 max-w-2xl p-6">
            <h2 className="text-xl font-semibold">First launch on macOS</h2>
            <p className="mt-3 leading-7 text-toki-mist">
              Toki is not yet signed with an Apple Developer ID. If macOS says
              the app is damaged or from an unidentified developer, clear the
              quarantine flag once:
            </p>
            <pre className="mt-5 max-w-full overflow-x-auto rounded-lg bg-black/40 p-4 font-mono text-sm text-toki-green">
              <code>xattr -dr com.apple.quarantine /Applications/Toki.app</code>
            </pre>
          </GlassCard>
        </SectionShell>
      </main>
      <SiteFooter />
    </div>
  );
}
