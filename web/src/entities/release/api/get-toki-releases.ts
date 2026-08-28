import type {
  TokiRelease,
  TokiReleaseAsset,
  TokiReleaseData,
} from '../model/types';

const GITHUB_RELEASES_URL =
  'https://api.github.com/repos/choi138/toki/releases';
const LATEST_RELEASE_URL = 'https://github.com/choi138/toki/releases/latest';
const MACOS_ARCHIVE_NAME = 'Toki-macOS.zip';

export const RELEASES_REVALIDATE_SECONDS = 3600;

const fallbackRelease: TokiRelease = {
  asset: null,
  name: 'Latest Toki release',
  notes: 'See the latest Toki release and download for macOS on GitHub.',
  publishedAt: null,
  releaseUrl: LATEST_RELEASE_URL,
  tagName: 'latest',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function getOptionalString(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function parseAsset(value: unknown): TokiReleaseAsset | null {
  if (!isRecord(value) || value.name !== MACOS_ARCHIVE_NAME) {
    return null;
  }

  const downloadUrl = getOptionalString(value.browser_download_url);
  const size = value.size;

  if (downloadUrl === null || typeof size !== 'number' || size < 0) {
    return null;
  }

  return {
    downloadCount:
      typeof value.download_count === 'number' && value.download_count >= 0
        ? value.download_count
        : 0,
    downloadUrl,
    size,
  };
}

function parseRelease(value: unknown): TokiRelease | null {
  if (!isRecord(value) || value.draft === true || value.prerelease === true) {
    return null;
  }

  const tagName = getOptionalString(value.tag_name);
  const releaseUrl = getOptionalString(value.html_url);

  if (tagName === null || releaseUrl === null) {
    return null;
  }

  const assets = Array.isArray(value.assets) ? value.assets : [];
  const asset = assets.map(parseAsset).find((item) => item !== null) ?? null;

  return {
    asset,
    name: getOptionalString(value.name),
    notes: getOptionalString(value.body) ?? '',
    publishedAt: getOptionalString(value.published_at),
    releaseUrl,
    tagName,
  };
}

function parseReleases(value: unknown): TokiRelease[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.flatMap((release) => {
    const parsedRelease = parseRelease(release);

    return parsedRelease === null ? [] : [parsedRelease];
  });
}

function createFallbackData(): TokiReleaseData {
  return {
    isFallback: true,
    latest: fallbackRelease,
    releases: [fallbackRelease],
  };
}

/**
 * Fetches public GitHub releases on the server. Any unavailable or malformed
 * response falls back to GitHub's stable latest-release page.
 */
export async function getTokiReleaseData(): Promise<TokiReleaseData> {
  try {
    const response = await fetch(GITHUB_RELEASES_URL, {
      headers: {
        Accept: 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      next: { revalidate: RELEASES_REVALIDATE_SECONDS },
    });

    if (!response.ok) {
      return createFallbackData();
    }

    const releases = parseReleases(await response.json());
    const latest = releases.find((release) => release.asset !== null);

    if (latest === undefined) {
      return createFallbackData();
    }

    return {
      isFallback: false,
      latest,
      releases,
    };
  } catch {
    return createFallbackData();
  }
}
