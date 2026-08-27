import { Download, ExternalLink } from 'lucide-react';

import type { GitHubRelease } from '@/entities/release';
import { siteConfig } from '@/shared/config';
import { Button } from '@/shared/ui';
import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';

const latestRelease: Pick<GitHubRelease, 'html_url'> = {
  html_url: siteConfig.links.latestRelease,
};

export function DownloadPage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 py-16 sm:py-24 lg:px-8">
          <h1 className="text-4xl font-semibold tracking-tight text-balance sm:text-5xl">
            Download Toki
          </h1>
          <p className="mt-5 max-w-2xl text-lg leading-8 text-muted-foreground">
            Get the latest macOS release from GitHub, move Toki to Applications,
            and launch it from your menu bar.
          </p>
          <Button asChild size="lg" className="mt-8">
            <a href={latestRelease.html_url} target="_blank" rel="noreferrer">
              <Download aria-hidden="true" />
              Latest release
              <ExternalLink aria-hidden="true" />
            </a>
          </Button>

          <div className="mt-14">
            <h2 className="text-xl font-semibold">First launch on macOS</h2>
            <p className="mt-3 leading-7 text-muted-foreground">
              Toki is not yet signed with an Apple Developer ID. If macOS says
              the app is damaged or from an unidentified developer, clear the
              quarantine flag once:
            </p>
            <pre className="mt-5 max-w-full overflow-x-auto rounded-lg border bg-muted p-4 text-sm">
              <code>xattr -dr com.apple.quarantine /Applications/Toki.app</code>
            </pre>
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
