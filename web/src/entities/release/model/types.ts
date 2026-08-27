export type GitHubReleaseAsset = {
  id: number;
  name: string;
  browser_download_url: string;
  content_type: string;
  size: number;
};

export type GitHubRelease = {
  id: number;
  tag_name: string;
  name: string | null;
  html_url: string;
  published_at: string | null;
  assets: GitHubReleaseAsset[];
};
