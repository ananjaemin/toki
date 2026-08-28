import { Hero3D } from '@/widgets/hero-3d';
import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';

export function LandingPage() {
  return (
    <div className="luminous flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex-1">
        <Hero3D />
      </main>
      <SiteFooter />
    </div>
  );
}
