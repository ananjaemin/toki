import { DownloadCta } from '@/widgets/download-cta';
import { Hero3D } from '@/widgets/hero-3d';
import { PrivacyPanel } from '@/widgets/privacy-panel';
import { ScreenshotStrip } from '@/widgets/screenshot-strip';
import { SiteFooter } from '@/widgets/site-footer';
import { SiteHeader } from '@/widgets/site-header';
import { SupportedAgents } from '@/widgets/supported-agents';
import { WorkTimeShowcase } from '@/widgets/work-time-showcase';
import { SectionShell } from '@/shared/ui';

export function LandingPage() {
  return (
    <div className="luminous flex min-h-dvh flex-col">
      <SiteHeader />
      <main className="flex-1">
        <Hero3D />
        <SectionShell>
          <div className="h-px bg-toki-line" />
        </SectionShell>
        <WorkTimeShowcase />
        <ScreenshotStrip />
        <SupportedAgents />
        <PrivacyPanel />
        <DownloadCta />
      </main>
      <SiteFooter />
    </div>
  );
}
