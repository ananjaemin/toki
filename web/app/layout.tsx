import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';

import { AppProviders } from '@/_app/providers';
import '@/_app/styles/globals.css';

export const metadata: Metadata = {
    title: {
        default: 'Toki',
        template: '%s | Toki',
    },
    description: 'A local-first macOS menu bar app for AI coding usage.',
};

export const viewport: Viewport = {
    colorScheme: 'dark light',
    initialScale: 1,
    themeColor: [
        { media: '(prefers-color-scheme: light)', color: '#fafafa' },
        { media: '(prefers-color-scheme: dark)', color: '#09090b' },
    ],
    width: 'device-width',
};

type RootLayoutProps = Readonly<{
    children: ReactNode;
}>;

export default function RootLayout({ children }: RootLayoutProps) {
    return (
        <html lang="en" suppressHydrationWarning>
            <body>
                <AppProviders>{children}</AppProviders>
            </body>
        </html>
    );
}
