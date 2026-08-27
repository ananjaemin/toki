import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';

import { siteConfig } from '@/shared/config';

export const docsLayoutOptions: BaseLayoutProps = {
  githubUrl: siteConfig.links.github,
  nav: {
    title: siteConfig.name,
    url: '/',
  },
};
