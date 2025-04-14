import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "SDI Exercises",
  description: "Documentation for the exercises in the lecture Software-Defined-Infrastructure",
  themeConfig: {
    search: {
      provider: 'local'
    },

    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Examples', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        text: 'Exercises',
        items: [
          { text: 'Hetzner Cloud', link: '/exercises/01-hetzner-cloud' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/robinsmith-source/sdi' }
    ]
  }
})
