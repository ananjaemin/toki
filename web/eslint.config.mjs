import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';

// Biome owns general linting; ESLint keeps only Next.js-specific rules.
const nextOnlyConfig = nextVitals.map((entry) => ({
  ...entry,
  rules: Object.fromEntries(
    Object.entries(entry.rules ?? {}).filter(([rule]) =>
      rule.startsWith('@next/next/'),
    ),
  ),
}));

const config = defineConfig([
  ...nextOnlyConfig,
  globalIgnores([
    '.next/**',
    '.source/**',
    'coverage/**',
    'next-env.d.ts',
    'node_modules/**',
    'out/**',
  ]),
]);

export default config;
