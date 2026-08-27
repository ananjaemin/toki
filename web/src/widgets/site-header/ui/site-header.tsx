import { ArrowDownToLine } from 'lucide-react';
import Image from 'next/image';
import Link from 'next/link';

import { siteConfig } from '@/shared/config';
import { Button, SectionShell } from '@/shared/ui';

const NAV_LINKS: readonly Readonly<{ href: string; label: string }>[] = [
  { href: '/#time', label: 'Work time' },
  { href: '/#agents', label: 'Agents' },
  { href: '/#privacy', label: 'Privacy' },
  { href: '/docs', label: 'Docs' },
];

export function SiteHeader() {
  return (
    <header>
      <SectionShell className="flex h-[4.1875rem] items-center justify-between gap-6 sm:h-[4.75rem]">
        <Link
          aria-label="Toki home"
          className="inline-flex items-center gap-2.5 font-semibold tracking-[-0.035em]"
          href="/"
        >
          <Image
            alt=""
            className="size-[1.8125rem] rounded-lg shadow-[0_0_20px_rgba(120,200,152,0.25)]"
            height={29}
            src="/icon.png"
            width={29}
          />
          {siteConfig.name}
        </Link>
        <nav
          aria-label="Primary"
          className="flex items-center gap-7 text-[13px] text-[#cdd3d1]"
        >
          {NAV_LINKS.map((link) => (
            <Link
              className="hidden transition-colors hover:text-toki-green sm:inline"
              href={link.href}
              key={link.href}
            >
              {link.label}
            </Link>
          ))}
          <Button asChild variant="glow">
            <a href={siteConfig.links.latestRelease}>
              Get Toki
              <ArrowDownToLine aria-hidden="true" />
            </a>
          </Button>
        </nav>
      </SectionShell>
    </header>
  );
}
