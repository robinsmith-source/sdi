---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "SDI Exercises"
  tagline: "Documentation for the exercises in the lecture Software-Defined-Infrastructure"
  actions:
    - theme: brand
      text: Exercises
      link: /exercises/hetzner-cloud
---

<script setup>
import { VPTeamMembers } from 'vitepress/theme';

const personalWebsite = '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20M2 12h20"/></g></svg>';


const members = [
  {
    avatar: 'https://www.github.com/robinsmith-source.png',
    name: 'Robin Schmidt',
    title: 'Creator',
    links: [
      { icon: 'github', link: 'https://www.github.com/robinsmith-source' },
      { icon: { svg: personalWebsite }, link: 'https://robinschmidt.dev' }
    ]
  },
]
</script>

<VPTeamMembers size="small" :members />
