import { readFileSync } from 'fs';
import { join } from 'path';

const SKILL_DIRECTORY = join(__dirname, '..', '..');

function readSkillFile(relativePath: string): string {
  return readFileSync(join(SKILL_DIRECTORY, relativePath), 'utf8');
}

function extractSectionTwoCodeBlock(rulesMarkdown: string): string {
  const sectionTwo = rulesMarkdown.split('## §2')[1].split('## §3')[0];
  const codeBlock = sectionTwo.match(/```tsx\n([\s\S]*?)```/);
  if (!codeBlock) throw new Error('RULES.md §2 has no tsx code block');
  return codeBlock[1];
}

describe('RULES.md §2 snippet', () => {
  it('equals examples/windowWidthClass.tsx verbatim', () => {
    expect(extractSectionTwoCodeBlock(readSkillFile('RULES.md'))).toBe(
      readSkillFile('examples/windowWidthClass.tsx'),
    );
  });
});
