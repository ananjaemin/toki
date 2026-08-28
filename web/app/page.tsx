import type { Metadata } from 'next';

import { getTokiReleaseData } from '@/entities/release';
import { LandingPage } from '@/_pages/landing';

export const metadata: Metadata = {
  alternates: {
    canonical: '/',
    languages: {
      en: '/',
      ko: '/ko',
    },
  },
  openGraph: {
    alternateLocale: ['ko_KR'],
    locale: 'en_US',
  },
};

export const revalidate = 3600;

export default async function HomePage() {
  const { latest } = await getTokiReleaseData();

  return <LandingPage latestRelease={latest} locale="en" />;
}
