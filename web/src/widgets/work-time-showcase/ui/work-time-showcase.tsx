import {
  Pill,
  Reveal,
  RevealList,
  RevealListItem,
  SectionShell,
} from '@/shared/ui';

type Metric = Readonly<{
  detail: string;
  label: string;
  value: string;
  valueClassName: string;
}>;

const METRICS: readonly Metric[] = [
  {
    detail: 'Wall-clock time with overlap counted once.',
    label: 'AI Work Time',
    value: '4h 13m',
    valueClassName: 'text-toki-green',
  },
  {
    detail: 'Total work divided by AI Work Time.',
    label: 'Parallel multiplier',
    value: '1.21×',
    valueClassName: 'text-toki-purple',
  },
  {
    detail: 'The work on the primary stream.',
    label: 'Main-agent work',
    value: 'Direct',
    valueClassName: 'text-toki-pink',
  },
  {
    detail: 'Work occurring on separate streams.',
    label: 'Subagent work',
    value: 'Delegated',
    valueClassName: 'text-[#e7eceb]',
  },
];

export function WorkTimeShowcase() {
  return (
    <section id="time">
      <SectionShell className="py-[6.375rem] lg:py-[8.5rem]">
        <div className="grid items-end gap-9 lg:grid-cols-[minmax(0,0.82fr)_minmax(0,1.18fr)] lg:gap-[3.125rem]">
          <Reveal>
            <Pill>Time view</Pill>
            <h2 className="mt-5 max-w-[43.125rem] text-[clamp(2.4375rem,4.6vw,3.8125rem)] leading-[1.01] font-semibold tracking-[-0.057em] text-balance">
              A total that knows what happened in parallel.
            </h2>
            <p className="mt-5 max-w-[33.75rem] text-[17px] text-toki-mist">
              Toki distinguishes direct work, delegated work, and overlapping
              streams—then counts overlap once so AI Work Time means something
              useful.
            </p>
          </Reveal>
          <RevealList
            aria-label="Toki time measurements"
            className="m-0 grid list-none gap-2.5 p-0 sm:grid-cols-2 sm:gap-3.5"
          >
            {METRICS.map((metric) => (
              <RevealListItem
                className="glass-panel min-h-[8.875rem] rounded-2xl p-5 transition-[border-color,transform] duration-200 hover:-translate-y-[3px] hover:border-[rgba(136,112,240,0.4)] sm:min-h-[11.125rem] sm:p-6"
                key={metric.label}
              >
                <b
                  className={`block font-mono text-[clamp(1.75rem,3vw,2.75rem)] font-medium tracking-[-0.07em] tabular-nums ${metric.valueClassName}`}
                >
                  {metric.value}
                </b>
                <span className="mt-3 block text-sm font-semibold text-[#d6dcda] sm:mt-[1.1875rem]">
                  {metric.label}
                </span>
                <p className="mt-[5px] text-xs leading-[1.45] text-[#8e9895]">
                  {metric.detail}
                </p>
              </RevealListItem>
            ))}
          </RevealList>
        </div>
      </SectionShell>
    </section>
  );
}
