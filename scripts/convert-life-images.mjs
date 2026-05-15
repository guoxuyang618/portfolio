// 一次性脚本：把 public/about/life/ 下所有 jpg/png 转 webp + 重命名 life-01..NN.webp
// 用法：node scripts/convert-life-images.mjs
import { readdir, rm, stat } from 'node:fs/promises';
import { join } from 'node:path';
import sharp from 'sharp';

sharp.cache(false); // 防止 Windows 下文件句柄占用导致 unlink EPERM

const DIR = new URL('../public/about/life/', import.meta.url).pathname.replace(/^\/(\w:)/, '$1');

const MAX_EDGE = 1920;
const QUALITY  = 80;

async function rmRetry(path, tries = 6) {
  for (let i = 0; i < tries; i++) {
    try { await rm(path, { force: true }); return; }
    catch (e) {
      if (i === tries - 1) throw e;
      await new Promise(r => setTimeout(r, 200 * (i + 1)));
    }
  }
}

async function main() {
  const files = (await readdir(DIR))
    .filter(f => /\.(jpe?g|png)$/i.test(f))
    .sort();

  if (!files.length) { console.log('no source images'); return; }
  console.log(`Found ${files.length} source files\n`);

  // Pass 1: 全部转码
  const mapping = [];
  let i = 0;
  for (const name of files) {
    i++;
    const src = join(DIR, name);
    const dstName = `life-${String(i).padStart(2, '0')}.webp`;
    const dst = join(DIR, dstName);
    const srcSize = (await stat(src)).size;

    await sharp(src)
      .rotate()
      .resize({ width: MAX_EDGE, height: MAX_EDGE, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: QUALITY, effort: 5 })
      .toFile(dst);

    const dstSize = (await stat(dst)).size;
    console.log(
      `[${i}/${files.length}] ${name}  ->  ${dstName}` +
      `   ${(srcSize/1024/1024).toFixed(2)}MB -> ${(dstSize/1024/1024).toFixed(2)}MB` +
      `   (${Math.round((1 - dstSize/srcSize) * 100)}% smaller)`
    );
    mapping.push({ src, srcName: name });
  }

  // Pass 2: 统一删除原文件（带重试）
  console.log('\nCleaning up source files...');
  for (const m of mapping) {
    try { await rmRetry(m.src); console.log(`  removed ${m.srcName}`); }
    catch (e) { console.error(`  FAILED to remove ${m.srcName}: ${e.message}`); }
  }
  console.log('\nDone.');
}
main().catch(e => { console.error(e); process.exit(1); });
