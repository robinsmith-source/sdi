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
          { text: "Hetzner Cloud", link: "/chapters/hetzner-cloud" },
          { text: "Using SSH", link: "/chapters/using-ssh" },
          {
            text: "Working with Terraform",
            link: "/chapters/working-with-terraform",
          },
          {
            text: "Server Initialization",
            link: "/chapters/server-initialization",
          },
          {
            text: "Attaching Volumes",
            link: "/chapters/attaching-volumes",
          },
        ],
      },
      {
        text: "Utils",
        items: [
          { text: "SSH", link: "/utils/ssh" },
          { text: "Terraform", link: "/utils/terraform" },
          { text: "Cloud-Init", link: "/utils/cloud-init" },
          { text: "Volumes", link: "/utils/volumes" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/robinsmith-source/sdi" },
    ],
  },
});
