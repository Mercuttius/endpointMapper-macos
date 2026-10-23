import { opendir, realpath, lstat, open } from 'node:fs/promises';
import { constants } from 'node:fs';
import path from 'node:path';
import ignore, { type Ignore } from 'ignore';

export interface ScanResult {
  files: number; directories: number; ignored: number; symlinks: number;
  languages: Record<string, number>; warnings: string[]; truncated: boolean;
}
export interface ScanEvent {
  kind: 'progress' | 'batch'; files: number; directories: number; paths: string[];
}
const exclusions = new Set(['.git', 'node_modules', 'vendor', '.build', 'dist', 'build', '.venv', 'venv', '__pycache__', 'target']);
const languages: Record<string, string> = { '.js':'JavaScript', '.mjs':'JavaScript', '.cjs':'JavaScript', '.ts':'TypeScript', '.tsx':'TypeScript', '.py':'Python', '.java':'Java', '.cs':'C#', '.php':'PHP', '.go':'Go', '.rb':'Ruby', '.rs':'Rust', '.kt':'Kotlin', '.swift':'Swift' };
interface Rule { base: string; matcher: Ignore }
export class ScanCancelled extends Error {}
export async function scanProject(rootInput: string, signal: AbortSignal,
  notify: (event: ScanEvent) => Promise<void>): Promise<ScanResult> {
  const root = await realpath(rootInput);
  if (!(await lstat(root)).isDirectory()) throw new Error('Expected directory');
  const result: ScanResult = { files:0, directories:0, ignored:0, symlinks:0, languages:{}, warnings:[], truncated:false };
  const warn = (message: string) => { if (result.warnings.length < 100) result.warnings.push(message); };
  const check = () => { if (signal.aborted) throw new ScanCancelled(); };
  const inside = (file: string) => file === root || file.startsWith(root + path.sep);
  let visited = 0;
  let batch: string[] = [];
  const emit = async (kind: 'progress' | 'batch') => {
    check();
    await notify({ kind, files:result.files, directories:result.directories, paths:kind === 'batch' ? batch : [] });
    if (kind === 'batch') batch = [];
    check();
  };
  await emit('progress');
  async function walk(directory: string, inherited: Rule[], depth: number): Promise<void> {
    check();
    if (depth > 64) { result.truncated = true; warn('Limite de profundidade atingido.'); return; }
    if (result.truncated && visited >= 50000) return;
    const resolved = await realpath(directory);
    if (!inside(resolved) || (await lstat(directory)).isSymbolicLink()) { result.symlinks++; return; }
    const rules = [...inherited];
    const ignoreFile = path.join(directory, '.gitignore');
    try {
      // O_NOFOLLOW prevents a symlinked ignore file from loading external content.
      const file = await open(ignoreFile, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK);
      try {
        const stat = await file.stat();
        if (stat.isFile() && stat.size <= 65536) {
          const bytes = Buffer.alloc(65537);
          const read = await file.read(bytes, 0, bytes.length, 0);
          if (read.bytesRead <= 65536) rules.push({ base:directory, matcher:ignore().add(bytes.subarray(0, read.bytesRead).toString('utf8')) });
          else warn('Arquivo .gitignore excedeu o limite de leitura.');
        } else warn('Arquivo .gitignore ignorado: tipo ou tamanho não permitido.');
      } finally { await file.close(); }
    } catch (error) {
      const code = (error as NodeJS.ErrnoException).code;
      if (code !== 'ENOENT') warn('Uma regra .gitignore não pôde ser lida.');
    }
    result.directories++;
    const entries = await opendir(directory);
    for await (const entry of entries) {
      check();
      if (++visited > 50000) { result.truncated = true; warn('Limite de 50.000 entradas atingido.'); return; }
      if (entry.isSymbolicLink()) { result.symlinks++; continue; }
      if (exclusions.has(entry.name)) { result.ignored++; continue; }
      const absolute = path.join(directory, entry.name);
      const relative = path.relative(root, absolute).split(path.sep).join('/');
      if (Buffer.byteLength(relative) > 2048) { result.truncated = true; warn('Caminho muito longo omitido.'); continue; }
      let ignored = false;
      for (const rule of rules) {
        const local = path.relative(rule.base, absolute).split(path.sep).join('/') + (entry.isDirectory() ? '/' : '');
        const match = rule.matcher.test(local);
        if (match.ignored) ignored = true;
        if (match.unignored) ignored = false;
      }
      if (ignored) { result.ignored++; continue; }
      try {
        if (entry.isDirectory()) await walk(absolute, rules, depth + 1);
        else if (entry.isFile()) {
          // Only metadata, never source/configuration execution or writes.
          const actual = await realpath(absolute);
          const stat = await lstat(absolute);
          if (!inside(actual) || stat.isSymbolicLink()) { result.symlinks++; continue; }
          if (!stat.isFile()) continue;
          result.files++;
          const language = languages[path.extname(entry.name)];
          if (language) result.languages[language] = (result.languages[language] ?? 0) + 1;
          batch.push(relative);
          if (batch.length >= 16 || Buffer.byteLength(JSON.stringify(batch)) > 24000) await emit('batch');
        }
      } catch (error) {
        if (error instanceof ScanCancelled || signal.aborted) throw new ScanCancelled();
        warn('Uma entrada não pôde ser lida; inventário parcial.');
      }
      if (visited % 64 === 0) { await emit('progress'); await new Promise<void>(resolve => setImmediate(resolve)); }
    }
  }
  await walk(root, [], 0);
  if (batch.length) await emit('batch');
  await emit('progress');
  return result;
}
