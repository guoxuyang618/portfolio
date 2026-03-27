import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://portfolio-pied-eight-j0edulxe3u.vercel.app',
  base: '/',
  output: 'static',
  build: {
    format: 'directory'
  }
});
