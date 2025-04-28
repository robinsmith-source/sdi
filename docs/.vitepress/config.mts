import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "SDI Exercises",
  description: "Documentation for the exercises in the lecture Software-Defined-Infrastructure",
  base: '/sdi/',
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    search: {
      provider: 'local'
    },
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Exercises', link: '/exercises/hetzner-cloud' }
    ],

    sidebar: [
      {
        text: 'Exercises',
        items: [
          { text: 'Hetzner Cloud', link: '/exercises/hetzner-cloud' },
          { text: 'Working with Terraform', link: '/exercises/working-with-terraform' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/robinsmith-source/sdi' }
    ]
  }
})
