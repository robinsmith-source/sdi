import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "SDI Exercises",
  description:
    "Documentation for the exercises in the lecture Software-Defined-Infrastructure",
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    search: {
      provider: "local",
    },
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Chapters", link: "/chapters/hetzner-cloud" },
      { text: "Utils", link: "/utils/ssh" },
    ],

    sidebar: [
      {
        text: "Chapters",
        items: [
          { text: "Hetzner Cloud", link: "/chapters/01-hetzner-cloud" },
          { text: "Using SSH", link: "/chapters/02-using-ssh" },
          {
            text: "Working with Terraform",
            link: "/chapters/03-working-with-terraform",
          },
          {
            text: "Server Initialization",
            link: "/chapters/04-server-initialization",
          },
          {
            text: "Attaching Volumes",
            link: "/chapters/05-attaching-volumes",
          },   {
            text: "Terraform Modules",
            link: "/chapters/06-terraform-modules",
          },
        ],
      },
      {
        text: "Knowledge",
        items: [
          { text: "SSH", link: "/knowledge/ssh" },
          { text: "Terraform", link: "/knowledge/terraform" },
          { text: "Cloud-Init", link: "/knowledge/cloud-init" },
          { text: "Volumes", link: "/knowledge/volumes" },
          { text: "Modules", link: "/knowledge/modules" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/robinsmith-source/sdi" },
    ],
  },
});
