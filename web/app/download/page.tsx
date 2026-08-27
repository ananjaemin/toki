import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Download',
  description: 'Download the latest Toki release for macOS.',
};

export { DownloadPage as default } from '@/_pages/download';
