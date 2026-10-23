import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, symlink, rm, readdir } from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { scanProject, ScanCancelled } from '../dist/discovery/scan.js';
async function fixture(t) {
  const directory = await mkdtemp(path.join(os.tmpdir(),'endpointmapper-scan-'));
  t.after(() => rm(directory,{recursive:true,force:true})); return directory;
}
test('inventory honors ignore rules, nested negation, excludes dependencies and never executes sources', async t => {
  const root = await fixture(t);
  await mkdir(path.join(root,'src'));
  await mkdir(path.join(root,'node_modules'));
  await writeFile(path.join(root,'.gitignore'),'*.tmp\nsrc/*.js\n');
  await writeFile(path.join(root,'src','.gitignore'),'!keep.js\n');
  await writeFile(path.join(root,'src','keep.js'),'throw new Error("MUST NEVER EXECUTE");');
  await writeFile(path.join(root,'src','skip.js'),'secret');
  await writeFile(path.join(root,'src','api.ts'),'const x = ; // invalid source is only inventoried');
  await writeFile(path.join(root,'ignored.tmp'),'secret');
  await writeFile(path.join(root,'node_modules','dep.js'),'ignored');
  const before = await readFile(path.join(root,'src','keep.js'));
  const events=[];
  const result=await scanProject(root,new AbortController().signal,async event => { events.push(event); });
  assert.equal(result.files,4); // two ignore files + keep.js + api.ts
  assert.deepEqual(result.languages, {JavaScript:1,TypeScript:1});
  assert.equal(result.ignored,3);
  assert.ok(events.some(e=>e.kind==='progress'));
  assert.ok(events.some(e=>e.paths.includes('src/api.ts')));
  assert.deepEqual(await readFile(path.join(root,'src','keep.js')),before);
  assert.deepEqual((await readdir(root)).sort(),['.gitignore','ignored.tmp','node_modules','src']);
});
test('symlink to external directory and symlinked ignore file are not followed',async t=>{
  const root=await fixture(t), outside=await fixture(t);
  await writeFile(path.join(outside,'secret.js'),'secret');
  await writeFile(path.join(outside,'rules'),'*');
  await symlink(outside,path.join(root,'outside'));
  await symlink(path.join(outside,'rules'),path.join(root,'.gitignore'));
  await writeFile(path.join(root,'local.py'),'pass');
  const result=await scanProject(root,new AbortController().signal,async()=>{});
  assert.equal(result.files,1); assert.equal(result.symlinks,2);
  assert.deepEqual(result.languages,{Python:1});
});
test('cancel interrupts incremental inventory',async t=>{
  const root=await fixture(t);
  for(let i=0;i<40;i++) await writeFile(path.join(root,`${i}.ts`),'');
  const controller=new AbortController(); let batches=0;
  await assert.rejects(scanProject(root,controller.signal,async event=>{
    if(event.kind==='batch') { batches++; controller.abort(); }
  }),ScanCancelled);
  assert.equal(batches,1);
});
test('non-directory fails explicitly',async t=>{
  const root=await fixture(t); const file=path.join(root,'file'); await writeFile(file,'');
  await assert.rejects(scanProject(file,new AbortController().signal,async()=>{}));
});
