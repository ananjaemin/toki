import type { ComponentProps } from 'react';

import { cn } from '@/shared/lib/cn';

type SectionShellProps = ComponentProps<'div'>;

/** Centered content column with shared responsive landing gutters. */
function SectionShell({ className, ...props }: SectionShellProps) {
  return (
    <div
      data-slot="section-shell"
      className={cn(
        'mx-auto w-full max-w-7xl px-6 sm:px-8 md:px-10 lg:px-14 xl:px-16',
        className,
      )}
      {...props}
    />
  );
}

export { SectionShell };
