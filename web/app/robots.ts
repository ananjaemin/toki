import type { MetadataRoute } from 'next';

import { siteConfig } from '@/shared/config';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      allow: '/',
      userAgent: '*',
    },
    sitemap: new URL('/sitemap.xml', `${siteConfig.url}/`).toString(),
  };
}
