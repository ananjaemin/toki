import { ArrowDownToLine, ExternalLink } from 'lucide-react';

import type { TokiRelease } from '@/entities/release';
import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';
import { Button, GlassCard, Pill, SectionShell } from '@/shared/ui';

const megabyte = 1024 * 1024;
const releaseDateFormatter = new Intl.DateTimeFormat('en', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
});

type DownloadPageProps = Readonly<{
  latestRelease: TokiRelease;
  releases: readonly TokiRelease[];
}>;

function formatFileSize(size: number): string {
  return `${(size / megabyte).toFixed(1)} MB`;
}

function formatReleaseDate(publishedAt: string | null): string {
  if (publishedAt === null) {
    return 'Latest release';
  }

  const date = new Date(publishedAt);

  return Number.isNaN(date.getTime())
    ? 'Latest release'
    : releaseDateFormatter.format(date);
}

function summarizeReleaseNotes(notes: string): string {
  const summary = notes
    .split(/\r?\n/)
    .map((line) =>
      line
        .replace(/^\s{0,3}#{1,6}\s+/, '')
        .replace(/^\s*(?:[-*+] |\d+\. )/, '')
        .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
        .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
        .replace(/[`*_~]/g, '')
        .trim(),
    )
    .filter(Boolean)
    .slice(0, 3)
    .join(' ');

  if (summary.length <= 280) {
    return summary || 'Release notes are available on GitHub.';
  }

  return `${summary.slice(0, 277).trimEnd()}…`;
}

export function DownloadPage({ latestRelease, releases }: DownloadPageProps) {
  const downloadUrl =
    latestRelease.asset?.downloadUrl ?? latestRelease.releaseUrl;
  const fileSize =
    latestRelease.asset === null
      ? null
      : formatFileSize(latestRelease.asset.size);

  return (
    <div className="luminous flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex-1">
        <SectionShell className="py-16 sm:py-24">
          <Pill>macOS · GitHub releases</Pill>
          <h1 className="mt-5 text-4xl font-semibold tracking-[-0.04em] text-balance sm:text-5xl">
            Download Toki
          </h1>
          <p className="mt-5 max-w-2xl text-lg leading-8 text-toki-mist">
            Get the latest macOS release from GitHub, move Toki to Applications,
            and launch it from your menu bar.
          </p>
          <GlassCard className="mt-10 max-w-3xl p-6 sm:p-8">
            <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
              <div className="min-w-0">
                <p className="font-mono text-[11px] tracking-[0.08em] text-toki-purple uppercase">
                  Current macOS release
                </p>
                <h2 className="mt-3 text-2xl font-semibold tracking-[-0.04em] sm:text-3xl">
                  {latestRelease.name ?? `Toki ${latestRelease.tagName}`}
                </h2>
                <p className="mt-2 text-sm text-toki-mist">
                  {formatReleaseDate(latestRelease.publishedAt)}
                  {fileSize === null ? '' : ` · ${fileSize}`}
                </p>
              </div>
              <Button asChild className="shrink-0" size="lg" variant="glow">
                <a href={downloadUrl}>
                  <ArrowDownToLine aria-hidden="true" />
                  Download Toki {latestRelease.tagName}
                  {fileSize === null ? null : ` · ${fileSize}`}
                </a>
              </Button>
            </div>
          </GlassCard>

          <section
            className="mt-14 max-w-3xl"
            aria-labelledby="download-requirements"
          >
            <h2
              className="text-2xl font-semibold tracking-[-0.04em]"
              id="download-requirements"
            >
              Before you install
            </h2>
            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <GlassCard className="p-5">
                <p className="font-mono text-[11px] tracking-[0.08em] text-toki-purple uppercase">
                  Requirement
                </p>
                <p className="mt-3 font-medium">macOS 13.0 or later</p>
              </GlassCard>
              <GlassCard className="p-5">
                <p className="font-mono text-[11px] tracking-[0.08em] text-toki-purple uppercase">
                  Install
                </p>
                <p className="mt-3 font-medium">
                  Move Toki.app to Applications
                </p>
              </GlassCard>
            </div>
          </section>

          <GlassCard className="mt-6 max-w-3xl p-6">
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

          <section
            className="mt-20 max-w-4xl"
            aria-labelledby="release-history"
          >
            <h2
              className="text-3xl font-semibold tracking-[-0.04em] sm:text-4xl"
              id="release-history"
            >
              Version history
            </h2>
            <p className="mt-4 max-w-2xl leading-7 text-toki-mist">
              A short look at the latest improvements. Read the full notes on
              GitHub for each release.
            </p>
            <GlassCard className="mt-7 overflow-hidden">
              <ol className="divide-y divide-toki-line">
                {releases.slice(0, 5).map((release) => (
                  <li
                    className="grid gap-5 p-6 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-start sm:p-7"
                    key={release.releaseUrl}
                  >
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
                        <h3 className="font-mono text-sm font-medium text-toki-purple">
                          {release.tagName}
                        </h3>
                        <time
                          className="text-sm text-toki-mist"
                          dateTime={release.publishedAt ?? undefined}
                        >
                          {formatReleaseDate(release.publishedAt)}
                        </time>
                      </div>
                      {release.name === null ||
                      release.name === release.tagName ? null : (
                        <p className="mt-2 font-medium">{release.name}</p>
                      )}
                      <p className="mt-3 max-w-2xl break-words text-sm leading-6 text-toki-mist">
                        {summarizeReleaseNotes(release.notes)}
                      </p>
                    </div>
                    <a
                      className="inline-flex items-center gap-2 self-start text-sm font-medium text-toki-ink transition-colors hover:text-toki-purple focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-toki-purple"
                      href={release.releaseUrl}
                      rel="noreferrer"
                      target="_blank"
                    >
                      Full notes
                      <ExternalLink aria-hidden="true" className="size-4" />
                    </a>
                  </li>
                ))}
              </ol>
            </GlassCard>
          </section>
        </SectionShell>
      </main>
      <SiteFooter />
    </div>
  );
}
