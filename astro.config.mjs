import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://portfolio-pied-eight-j0edulxe3u.vercel.app',
  base: '/',
  output: 'static',
  build: {
    format: 'directory'
  },
  server: {
    port: 4321,
    host: true,
    // 端口被占时直接报错而不是飘到 4322/4323，避免越积越多
    strictPort: true
  }
});
