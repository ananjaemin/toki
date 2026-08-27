import type { MetadataRoute } from 'next';

import { siteConfig } from '@/shared/config';

export default function sitemap(): MetadataRoute.Sitemap {
  return ['/', '/download', '/docs'].map((pathname) => ({
    changeFrequency: pathname === '/' ? 'weekly' : 'monthly',
    priority: pathname === '/' ? 1 : 0.8,
    url: new URL(pathname, `${siteConfig.url}/`).toString(),
  }));
}
