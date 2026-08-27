import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTypescript from 'eslint-config-next/typescript';

const config = defineConfig([
  ...nextVitals,
  ...nextTypescript,
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
