import Image from 'next/image';

/** Static hero art: the sketch's glass overview frame under a purple halo. */
export function HeroFallback() {
  return (
    <div
      aria-hidden="true"
      className="absolute inset-0 grid place-items-center"
      data-hero-fallback
    >
      <div className="absolute top-0 left-1/2 aspect-square w-[min(38rem,100%)] -translate-x-1/2 rounded-full bg-[radial-gradient(circle,rgba(136,112,240,0.26),rgba(136,112,240,0.07)_32%,transparent_68%)] blur-[4px]" />
      <div className="relative z-[2] w-[min(21rem,70vw)] rotate-3 rounded-[25px] border border-white/[0.12] bg-gradient-to-br from-white/[0.17] via-white/[0.045] to-[rgba(120,168,248,0.11)] p-[9px] shadow-[0_40px_75px_rgba(0,0,0,0.52),0_0_0_1px_rgba(0,0,0,0.35),0_0_72px_rgba(136,112,240,0.17)] backdrop-blur-lg">
        <Image
          alt=""
          className="rounded-[17px]"
          height={840}
          sizes="(max-width: 767px) 70vw, 336px"
          src="/screenshots/screenshot_overview.png"
          width={640}
        />
      </div>
    </div>
  );
}
