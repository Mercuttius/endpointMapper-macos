export const MAX_FRAME = 64 * 1024;
export class FrameDecoder {
  private pending = Buffer.alloc(0);
  private readonly decoder = new TextDecoder('utf-8', { fatal: true });
  push(chunk: Buffer): string[] {
    const frames: string[] = [];
    let start = 0;
    for (;;) {
      const end = chunk.indexOf(10, start);
      const piece = chunk.subarray(start, end === -1 ? chunk.length : end);
      if (this.pending.length + piece.length > MAX_FRAME) throw new Error('Frame exceeds limit');
      this.pending = Buffer.concat([this.pending, piece]);
      if (end === -1) break;
      frames.push(this.decoder.decode(this.pending));
      this.pending = Buffer.alloc(0);
      start = end + 1;
    }
    return frames;
  }
  finish(): void { if (this.pending.length) throw new Error('Truncated frame'); }
}

// Bounded output queue; write callbacks serialize output and honor pipe pressure.
export class MessageWriter {
  private queuedBytes = 0;
  private chain = Promise.resolve();
  send(message: unknown): Promise<void> {
    const line = JSON.stringify(message) + '\n';
    const bytes = Buffer.byteLength(line);
    if (bytes > MAX_FRAME || this.queuedBytes + bytes > 1024 * 1024) {
      return Promise.reject(new Error('Output limit exceeded'));
    }
    this.queuedBytes += bytes;
    const next = this.chain.then(() => new Promise<void>((resolve, reject) => {
      process.stdout.write(line, error => error ? reject(error) : resolve());
    })).finally(() => { this.queuedBytes -= bytes; });
    this.chain = next.catch(() => {});
    return next;
  }
}
