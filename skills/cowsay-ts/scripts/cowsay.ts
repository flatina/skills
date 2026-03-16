const text = process.argv[2] ?? "Moo!";

const maxWidth = 40;

function wrapText(text: string, width: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let current = "";

  for (const word of words) {
    if (current.length + word.length + 1 > width && current.length > 0) {
      lines.push(current);
      current = word;
    } else {
      current = current.length === 0 ? word : `${current} ${word}`;
    }
  }
  if (current.length > 0) lines.push(current);

  return lines;
}

function buildBubble(lines: string[]): string {
  const width = Math.max(...lines.map((l) => l.length));
  const top = " " + "_".repeat(width + 2);
  const bottom = " " + "-".repeat(width + 2);

  if (lines.length === 1) {
    return [top, `< ${lines[0].padEnd(width)} >`, bottom].join("\n");
  }

  const middle = lines.map((line, i) => {
    const padded = line.padEnd(width);
    if (i === 0) return `/ ${padded} \\`;
    if (i === lines.length - 1) return `\\ ${padded} /`;
    return `| ${padded} |`;
  });

  return [top, ...middle, bottom].join("\n");
}

const cow = `        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||`;

const lines = wrapText(text, maxWidth);
console.log(buildBubble(lines));
console.log(cow);
