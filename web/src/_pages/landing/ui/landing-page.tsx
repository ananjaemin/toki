import { ExternalLink } from 'lucide-react';

import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';
import { siteConfig } from '@/shared/config';
import { Badge, Button } from '@/shared/ui';

export function LandingPage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex flex-1 items-center">
        <section className="mx-auto w-full max-w-6xl px-6 py-20 sm:py-28 lg:px-8">
          <div className="max-w-2xl">
            <Badge variant="outline">macOS menu bar app</Badge>
            <h1 className="mt-6 text-5xl font-semibold tracking-tight text-balance sm:text-7xl">
              {siteConfig.name}
            </h1>
            <p className="mt-6 max-w-xl text-lg leading-8 text-pretty text-muted-foreground sm:text-xl">
              {siteConfig.tagline}
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Button asChild size="lg">
                <a
                  href={siteConfig.links.github}
                  target="_blank"
                  rel="noreferrer"
                >
                  View on GitHub
                  <ExternalLink aria-hidden="true" />
                </a>
              </Button>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
