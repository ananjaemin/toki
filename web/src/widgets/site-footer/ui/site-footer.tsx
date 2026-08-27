import Link from 'next/link';

import { siteConfig } from '@/shared/config';

export function SiteFooter() {
  return (
    <footer className="border-t">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 px-6 py-8 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between lg:px-8">
        <p>© {new Date().getFullYear()} Toki.</p>
        <nav aria-label="Footer navigation" className="flex flex-wrap gap-4">
          <Link
            href="/docs"
            className="underline-offset-4 hover:text-foreground hover:underline"
          >
            Docs
          </Link>
          <Link
            href="/download"
            className="underline-offset-4 hover:text-foreground hover:underline"
          >
            Download
          </Link>
          <a
            href={siteConfig.links.github}
            target="_blank"
            rel="noreferrer"
            className="underline-offset-4 hover:text-foreground hover:underline"
          >
            GitHub
          </a>
        </nav>
      </div>
    </footer>
  );
}
