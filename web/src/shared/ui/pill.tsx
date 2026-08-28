import type { ComponentProps } from 'react';

import { cn } from '@/shared/lib/cn';

type PillProps = ComponentProps<'span'>;

/** Monospace section eyebrow rendered as a faint glass capsule. */
function Pill({ className, ...props }: PillProps) {
  return (
    <span
      data-slot="pill"
      className={cn(
        'inline-flex min-h-7 items-center rounded-full border border-toki-line bg-white/[0.035] px-2.5 font-mono text-[10px] tracking-[0.06em] text-[#bfc7c4] uppercase',
        className,
      )}
      {...props}
    />
  );
}

export { Pill };
