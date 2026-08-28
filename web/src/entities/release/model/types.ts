export type TokiReleaseAsset = Readonly<{
  downloadCount: number;
  downloadUrl: string;
  size: number;
}>;

export type TokiRelease = Readonly<{
  asset: TokiReleaseAsset | null;
  name: string | null;
  notes: string;
  publishedAt: string | null;
  releaseUrl: string;
  tagName: string;
}>;

export type TokiReleaseData = Readonly<{
  isFallback: boolean;
  latest: TokiRelease;
  releases: readonly TokiRelease[];
}>;
