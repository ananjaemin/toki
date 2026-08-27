import { Code2 } from 'lucide-react';
import Link from 'next/link';

import { ThemeToggle } from '@/features/theme-toggle';
import { siteConfig } from '@/shared/config';
import { Button } from '@/shared/ui';

export function SiteHeader() {
  return (
    <header className="border-b bg-background/95">
      <div className="mx-auto flex h-16 max-w-6xl items-center gap-4 px-4 sm:px-6 lg:px-8">
        <Link
          href="/"
          className="font-semibold tracking-tight"
          aria-label="Toki home"
        >
          {siteConfig.name}
        </Link>
        <nav
          aria-label="Primary navigation"
          className="ml-auto flex items-center gap-1 sm:gap-2"
        >
          <Button asChild variant="ghost" className="hidden sm:inline-flex">
            <Link href="/docs">Docs</Link>
          </Button>
          <Button asChild variant="ghost" className="hidden sm:inline-flex">
            <Link href="/download">Download</Link>
          </Button>
          <Button asChild variant="ghost" size="icon">
            <a
              href={siteConfig.links.github}
              target="_blank"
              rel="noreferrer"
              aria-label="Open Toki on GitHub"
              title="GitHub"
            >
              <Code2 aria-hidden="true" />
            </a>
          </Button>
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
