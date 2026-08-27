import { Pill, SectionShell } from '@/shared/ui';

const AGENT_TOOLS: readonly string[] = [
  'Claude Code',
  'Codex',
  'Hermes',
  'Cursor',
  'Gemini CLI',
  'GJC',
  'OpenCode',
  'OpenClaw',
];

export function SupportedAgents() {
  return (
    <section id="agents">
      <SectionShell className="py-[6.375rem] lg:py-[8.5rem]">
        <div className="grid items-start gap-7 lg:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)] lg:gap-[5.25rem]">
          <div>
            <Pill>Supported agents</Pill>
            <h2 className="mt-5 max-w-[43.125rem] text-[clamp(2.3125rem,4.2vw,3.4375rem)] leading-[1.01] font-semibold tracking-[-0.057em] text-balance">
              The tools already in your terminal.
            </h2>
            <p className="mt-5 max-w-[33.75rem] text-[17px] text-toki-mist">
              Toki reads the supported local usage stores. It does not ask you
              to reconstruct a workday from browser tabs and invoices.
            </p>
          </div>
          <ul
            aria-label="Supported agent tools"
            className="m-0 grid list-none grid-cols-1 border-t border-l border-toki-line p-0 sm:grid-cols-2"
          >
            {AGENT_TOOLS.map((tool) => (
              <li
                className="flex min-h-[3.625rem] items-center border-r border-b border-toki-line px-[1.125rem] font-mono text-[13px] tracking-[-0.025em] text-[#d8dfdc] transition-colors duration-200 hover:bg-[rgba(136,112,240,0.11)] hover:text-toki-purple sm:min-h-[4.5625rem]"
                key={tool}
              >
                {tool}
              </li>
            ))}
          </ul>
        </div>
      </SectionShell>
    </section>
  );
}
