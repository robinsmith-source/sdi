---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "SDI Exercises"
  text: "Software-Defined Infrastructure"
  tagline: "Explore practical exercises and essential utilities for mastering Software-Defined Infrastructure concepts."
  actions:
    - theme: brand
      text: View Chapters
      link: /chapters/01-hetzner-cloud
    - theme: alt
      text: Explore Knowledge
      link: /knowledge/ssh

features:
  - icon: 🛠️
    title: Hands-On Exercises
    details: Step-by-step guides for practical infrastructure setup using tools like Terraform and Ansible.
    link: /chapters/01-hetzner-cloud
  - icon: ⚙️
    title: Essential Knowledge
    details: Documentation for crucial tools and techniques like SSH, Git, and command-line basics.
    link: /knowledge/ssh
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
