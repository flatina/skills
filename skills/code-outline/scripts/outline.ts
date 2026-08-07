#!/usr/bin/env bun
export {};
let ts: typeof import("typescript");
try {
  const mod = await import("typescript");
  ts = ((mod as any).default ?? mod) as typeof import("typescript");
} catch {
  console.error("Error: 'typescript' package not found. Install or skip outline.");
  process.exit(1);
}
if (!ts.createSourceFile || !(ts as any).ScriptTarget) {
  console.error("outline needs typescript 5.x (classic compiler API); resolved typescript lacks it — skip, use LSP.");
  process.exit(1);
}

const path = Bun.argv[2];
if (!path) { console.error("usage: bun outline.ts <file>"); process.exit(1); }

const text = await Bun.file(path).text();
const sf = ts.createSourceFile(path, text, ts.ScriptTarget.Latest, true);

const range = (node: any): string => {
  const s = sf.getLineAndCharacterOfPosition(node.getStart(sf)).line + 1;
  const e = sf.getLineAndCharacterOfPosition(node.getEnd()).line + 1;
  return `${s}-${e}`;
};

const isExp = (node: any): boolean =>
  ts.canHaveModifiers(node) &&
  (ts.getModifiers(node)?.some((m: any) => m.kind === ts.SyntaxKind.ExportKeyword) ?? false);

const print = (r: string, kind: string, name: string, exp: boolean) => {
  console.log(`${r}\t${kind}\t${name}\t${exp ? "e" : ""}`);
};

console.log("line\t(func/iface/class/type/method/default)\tname\t(e=export or empty)");

for (const stmt of sf.statements) {
  const exp = isExp(stmt);

  if (ts.isClassDeclaration(stmt)) {
    const className = stmt.name?.text ?? "default";
    print(range(stmt), "c", className, exp);
    for (const member of stmt.members) {
      if (ts.isMethodDeclaration(member) && ts.isIdentifier(member.name)) {
        print(range(member), "m", `${className}.${member.name.text}`, false);
      }
    }
  } else if (ts.isFunctionDeclaration(stmt)) {
    print(range(stmt), "f", stmt.name?.text ?? "default", exp);
  } else if (ts.isInterfaceDeclaration(stmt)) {
    print(range(stmt), "i", stmt.name.text, exp);
  } else if (ts.isTypeAliasDeclaration(stmt)) {
    print(range(stmt), "t", stmt.name.text, exp);
  } else if (ts.isVariableStatement(stmt)) {
    for (const decl of stmt.declarationList.declarations) {
      if (!decl.initializer || !ts.isIdentifier(decl.name)) continue;
      const init = decl.initializer;
      const isFunc = ts.isArrowFunction(init) || ts.isFunctionExpression(init);
      const isFactoryExport = ts.isCallExpression(init) && exp;
      if (isFunc || isFactoryExport) {
        print(range(decl), "f", decl.name.text, exp);
      }
    }
  } else if (ts.isExportAssignment(stmt)) {
    const e = stmt.expression;
    let name = "default";
    if (ts.isCallExpression(e) && ts.isIdentifier(e.expression)) {
      name = `default(${e.expression.text})`;
    } else if (ts.isIdentifier(e)) {
      name = `default(${e.text})`;
    }
    print(range(stmt), "d", name, true);
  }
}
