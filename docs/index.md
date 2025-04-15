---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "SDI Exercises"
  text: "Documentation for the exercises in the lecture Software-Defined-Infrastructure"
  actions:
    - theme: brand
      text: Markdown Examples
      link: /markdown-examples
    - theme: alt
      text: API Examples
      link: /api-examples

features:
  - title: Feature A
    details: Lorem ipsum dolor sit amet, consectetur adipiscing elit
  - title: Feature B
    details: Lorem ipsum dolor sit amet, consectetur adipiscing elit
  - title: Feature C
    details: Lorem ipsum dolor sit amet, consectetur adipiscing elit
---

<script setup>
import { VPTeamMembers } from 'vitepress/theme'

const members = [
  {
    avatar: 'https://www.github.com/robinsmith-source.png',
    name: 'Robin Schmidt',
    title: 'Creator',
    links: [
      { icon: 'github', link: 'https://www.github.com/robinsmith-source' },
      { icon: 'twitter', link: 'https://robinschmidt.dev' }
    ]
  },
]
</script>

# Our Team

Say hello to our awesome team.

<VPTeamMembers size="small" :members />
