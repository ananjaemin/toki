import Link from 'next/link';

import { siteConfig } from '@/shared/config';
import { SectionShell } from '@/shared/ui';

export function SiteFooter() {
  return (
    <footer>
      <SectionShell className="flex flex-col gap-1.5 border-t border-toki-line py-[1.625rem] pb-9 font-mono text-[10px] text-[#74807b] sm:flex-row sm:justify-between sm:gap-[1.125rem]">
        <span>© TOKI · LOCAL-FIRST OBSERVABILITY</span>
        <span className="flex gap-4">
          <Link
            className="transition-colors hover:text-toki-green"
            href="/docs"
          >
            DOCS
          </Link>
          <Link
            className="transition-colors hover:text-toki-green"
            href="/download"
          >
            DOWNLOAD
          </Link>
          <a
            className="transition-colors hover:text-toki-green"
            href={siteConfig.links.github}
            rel="noreferrer"
            target="_blank"
          >
            github.com/choi138/toki
          </a>
        </span>
      </SectionShell>
    </footer>
  );
}
