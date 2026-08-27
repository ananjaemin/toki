const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';

export const siteConfig = {
  name: 'Toki',
  description: 'A local-first macOS menu bar app for AI coding usage.',
  tagline: 'Understand your AI coding usage from the macOS menu bar.',
  url: siteUrl.replace(/\/$/, ''),
  links: {
    github: 'https://github.com/choi138/toki',
    latestRelease: 'https://github.com/choi138/toki/releases/latest',
  },
} as const;
