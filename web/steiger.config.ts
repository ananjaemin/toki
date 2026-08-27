import fsd from '@feature-sliced/steiger-plugin';
import { defineConfig } from 'steiger';

export default defineConfig([
  ...fsd.configs.recommended,
  {
    files: ['./src/_app/**', './src/_pages/**'],
    rules: {
      // Next.js owns the root app/ and pages/ names, so FSD layers use the
      // official underscore aliases to avoid collisions.
      'fsd/typo-in-layer-name': 'off',
    },
  },
  {
    files: ['./src/_app/**'],
    rules: {
      // Providers and global styles are mandated App-layer integration points.
      'fsd/segments-by-purpose': 'off',
    },
  },
  {
    files: ['./src/features/theme-toggle/**'],
    rules: {
      // This intentionally small feature has one host in the site header.
      'fsd/insignificant-slice': 'off',
    },
  },
]);
