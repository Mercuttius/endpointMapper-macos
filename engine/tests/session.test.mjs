import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
const server=fileURLToPath(new URL('../dist/protocol/server.js',import.meta.url));
async function client(t) {
  const child=spawn(process.execPath,[server],{env:{PATH:'/usr/bin:/bin'},stdio:['pipe','pipe','pipe']});
  t.after(()=>{ child.stdin.end(); child.kill(); });
  let text=''; const messages=[], waiters=[];
  child.stdout.on('data',chunk=>{
    text+=chunk;
    let end;
    while((end=text.indexOf('\n'))>=0){
      const message=JSON.parse(text.slice(0,end)); text=text.slice(end+1);
      const index=waiters.findIndex(w=>w.filter(message));
      if(index>=0){const [waiter]=waiters.splice(index,1);clearTimeout(waiter.timer);waiter.resolve(message);}
      else messages.push(message);
    }
  });
  function next(filter){
    const index=messages.findIndex(filter);
    if(index>=0)return Promise.resolve(messages.splice(index,1)[0]);
    return new Promise((resolve,reject)=>{
      const waiter={filter,resolve,timer:setTimeout(()=>{const i=waiters.indexOf(waiter);if(i>=0)waiters.splice(i,1);reject(new Error('Protocol response timeout'));},3000)};
      waiters.push(waiter);
    });
  }
  const send=(id,method,params={})=>child.stdin.write(JSON.stringify({jsonrpc:'2.0',id,method,params})+'\n');
  send('init','initialize',{protocolVersion:1});await next(m=>m.id==='init');
  return {child,send,next};
}
test('one persistent process serves ping and inventory with ordered batches',async t=>{
  const root=await mkdtemp(path.join(os.tmpdir(),'endpointmapper-rpc-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  for(let i=0;i<35;i++)await writeFile(path.join(root,`${i}.js`),'throw new Error("not executed")');
  const c=await client(t);
  c.send('ping','ping');assert.equal((await c.next(m=>m.id==='ping')).result.alive,true);
  c.send('scan','project.scan',{root});
  let sequence=0, files=[];
  for(;;){const message=await c.next(m=>m.id==='scan'||m.params?.requestId==='scan');
    if(message.id){assert.equal(message.result.files,35);break;}
    assert.equal(message.params.sequence,sequence++);files.push(...message.params.paths);
  }
  assert.equal(new Set(files).size,35);
  c.send('shutdown','shutdown');assert.equal((await c.next(m=>m.id==='shutdown')).result.stopped,true);
});
test('cancel has correlated terminal error and session remains usable',async t=>{
  const root=await mkdtemp(path.join(os.tmpdir(),'endpointmapper-cancel-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  for(let i=0;i<100;i++)await writeFile(path.join(root,`${i}.ts`),'');
  const c=await client(t);
  c.send('scan','project.scan',{root});await c.next(m=>m.method==='project/progress');
  c.send('cancel','cancel',{requestId:'scan'});
  assert.equal((await c.next(m=>m.id==='cancel')).result.cancelled,true);
  assert.equal((await c.next(m=>m.id==='scan')).error.code,-32800);
  c.send('ping','ping');assert.equal((await c.next(m=>m.id==='ping')).result.alive,true);
});
