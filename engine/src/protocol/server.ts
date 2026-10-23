import { isAbsolute } from 'node:path';
import { FrameDecoder, MessageWriter } from './framing.js';
import { scanProject, ScanCancelled } from '../discovery/scan.js';

const decoder = new FrameDecoder(), writer = new MessageWriter();
const jobs = new Map<string, AbortController>();
let initialized = false, closing = false;
function fatal(): void {
  if (!closing) process.stderr.write('Protocol session terminated: framing or I/O failure\n');
  closing = true;
  for (const job of jobs.values()) job.abort();
  process.exitCode = 65;
  process.stdin.destroy();
}
function send(message: unknown): Promise<void> { return writer.send(message).catch(() => { fatal(); }); }
function error(id: string | null, code: number, message: string): Promise<void> {
  return send({ jsonrpc:'2.0', id, error:{ code, message } });
}
function result(id: string, value: unknown): Promise<void> { return send({ jsonrpc:'2.0', id, result:value }); }
function object(value: unknown): value is Record<string, unknown> { return !!value && typeof value === 'object' && !Array.isArray(value); }
function handle(line: string): void {
  let request: unknown;
  try { request = JSON.parse(line); }
  catch { void error(null, -32700, 'Parse error'); return; }
  if (!object(request) || request.jsonrpc !== '2.0' || typeof request.id !== 'string' || !request.id.length || request.id.length > 128 || typeof request.method !== 'string') {
    void error(null, -32600, 'Invalid request'); return;
  }
  const { id, method } = request;
  const params = request.params;
  if (jobs.has(id)) { void error(null, -32600, 'Request id already active'); return; }
  if (method === 'initialize') {
    if (!object(params) || params.protocolVersion !== 1) { void error(id, -32602, 'Unsupported protocolVersion'); return; }
    initialized = true;
    void result(id, { protocolVersion:1, engineVersion:'0.2.0', capabilities:['ping','project.scan','cancel','shutdown'], runtime:process.version, architecture:process.arch, executable:process.execPath });
    return;
  }
  if (!initialized) { void error(id, -32002, 'Initialize first'); return; }
  if (method === 'ping') { void result(id, { alive:true }); return; }
  if (method === 'cancel') {
    if (!object(params) || typeof params.requestId !== 'string') { void error(id, -32602, 'Expected requestId'); return; }
    const job = jobs.get(params.requestId);
    job?.abort();
    void result(id, { cancelled:!!job }); return;
  }
  if (method === 'shutdown') {
    closing = true;
    for (const job of jobs.values()) job.abort();
    void result(id, { stopped:true });
    process.stdin.destroy(); return;
  }
  if (method !== 'project.scan') { void error(id, -32601, 'Method not implemented'); return; }
  if (!object(params) || typeof params.root !== 'string' || !isAbsolute(params.root) || params.root.length > 4096 || params.root.includes('\0')) {
    void error(id, -32602, 'Expected absolute root directory'); return;
  }
  if (jobs.size) { void error(id, -32001, 'One scan at a time'); return; }
  const controller = new AbortController();
  jobs.set(id, controller);
  let sequence = 0;
  void scanProject(params.root, controller.signal, async event => {
    await send({ jsonrpc:'2.0', method:`project/${event.kind}`, params:{ requestId:id, sequence:sequence++, ...event } });
  }).then(value => result(id, value), failure => error(id,
    failure instanceof ScanCancelled ? -32800 : -32010,
    failure instanceof ScanCancelled ? 'Cancelled' : 'Could not read selected directory'))
    .finally(() => { jobs.delete(id); });
}
process.stdin.on('data', (chunk: Buffer) => {
  if (closing) return;
  try { for (const frame of decoder.push(chunk)) { if (!closing) handle(frame); } }
  catch { void error(null, -32700, 'Invalid or oversized frame'); fatal(); }
});
process.stdin.on('end', () => {
  for (const job of jobs.values()) job.abort();
  try { decoder.finish(); } catch { void error(null, -32700, 'Truncated frame'); process.exitCode = 65; }
});
process.stdin.on('error', fatal);
process.stdout.on('error', fatal);
