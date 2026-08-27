'use client';

import { RootProvider } from 'fumadocs-ui/provider/next';
import type { ReactNode } from 'react';

type AppProvidersProps = Readonly<{
  children: ReactNode;
}>;

export function AppProviders({ children }: AppProvidersProps) {
  return (
    <RootProvider
      search={{ enabled: false }}
      theme={{
        attribute: 'class',
        defaultTheme: 'system',
        disableTransitionOnChange: true,
        enableSystem: true,
        storageKey: 'toki-theme',
      }}
    >
      {children}
    </RootProvider>
  );
}
