import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://yourusername.github.io',
  base: '/',
  output: 'static',
  build: {
    format: 'file',
    outDir: 'dist'
  }
});
