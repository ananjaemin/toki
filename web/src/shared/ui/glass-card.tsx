import type { ComponentProps } from 'react';

import { cn } from '@/shared/lib/cn';

type GlassCardProps = ComponentProps<'div'>;

/** Translucent glass surface used across the luminous landing sections. */
function GlassCard({ className, ...props }: GlassCardProps) {
  return (
    <div
      data-slot="glass-card"
      className={cn('glass-panel rounded-2xl', className)}
      {...props}
    />
  );
}

export { GlassCard };
