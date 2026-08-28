import type { ComponentProps } from 'react';

import { cn } from '@/shared/lib/cn';

type SectionShellProps = ComponentProps<'div'>;

/** Centered content column matching the luminous sketch's 1200px shell. */
function SectionShell({ className, ...props }: SectionShellProps) {
  return (
    <div
      data-slot="section-shell"
      className={cn(
        'mx-auto w-[calc(100%-2rem)] max-w-[75rem] sm:w-[calc(100%-3rem)]',
        className,
      )}
      {...props}
    />
  );
}

export { SectionShell };
