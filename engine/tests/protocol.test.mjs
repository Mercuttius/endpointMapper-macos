import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { FrameDecoder } from '../dist/protocol/framing.js';
const server = fileURLToPath(new URL('../dist/protocol/server.js', import.meta.url));
const initialize = {jsonrpc:'2.0', id:'init', method:'initialize', params:{protocolVersion:1}};
function run(input) { return spawnSync(process.execPath, [server], { input, encoding:'utf8', timeout:3000, env:{PATH:'/usr/bin:/bin'} }); }
const line = value => JSON.stringify(value) + '\n';
test('handshake declares inventory, never endpoint support', () => {
  const result = run(line(initialize));
  assert.equal(result.status, 0);
  const response = JSON.parse(result.stdout);
  assert.equal(response.result.protocolVersion, 1);
  assert.deepEqual(response.result.capabilities, ['ping','project.scan','cancel','shutdown']);
});
test('multiple frames stay separate', () => assert.equal(run(line(initialize).repeat(3)).stdout.trim().split('\n').length, 3));
for (const [name, input, code] of [
  ['malformed JSON','{\n',-32700], ['array request','[]\n',-32600],
  ['unknown method',line(initialize)+line({...initialize,id:'other',method:'analyze'}),-32601],
  ['version mismatch',line({...initialize,params:{protocolVersion:2}}),-32602],
  ['initialization required',line({...initialize,method:'ping'}),-32002],
  ['relative root rejected',line(initialize)+line({...initialize,id:'scan',method:'project.scan',params:{root:'../project'}}),-32602]
]) test(name, () => assert.equal(JSON.parse(run(input).stdout.trim().split('\n').at(-1)).error.code, code));
test('oversized input terminates', () => assert.equal(run('x'.repeat(65537)).status,65));
test('partial EOF fails', () => assert.equal(run('{').status,65));
test('fragmented UTF8 preserves characters', () => {
  const parser = new FrameDecoder();
  const bytes = Buffer.from('árvore 🌳\n{"ok":true}\n');
  const frames = Array.from(bytes).flatMap(byte => parser.push(Buffer.from([byte])));
  assert.deepEqual(frames,['árvore 🌳','{"ok":true}']);
  parser.finish();
});
test('invalid UTF8 rejected', () => assert.throws(() => new FrameDecoder().push(Buffer.from([255,10]))));
test('fragmented oversize bounded', () => {
  const parser = new FrameDecoder(); parser.push(Buffer.alloc(65536,97));
  assert.throws(() => parser.push(Buffer.from('a')));
});
