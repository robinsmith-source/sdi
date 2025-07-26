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
      options: {
        detailedView: true,
      },
    },
    socialLinks: [
      { icon: "github", link: "https://github.com/robinsmith-source/sdi" },
    ],
    sidebar: [
      {
        text: "🚀 Cloud Setup",
        collapsed: false,
        items: [
          { text: "🛠️ Hetzner Cloud Setup", link: "/chapters/01-hetzner-cloud" },
        ],
      },
      {
        text: "🔐 SSH & Remote Access",
        collapsed: false,
        items: [
          { text: "📚 SSH Concepts", link: "/knowledge/ssh" },
          { text: "🛠️ Using SSH", link: "/chapters/02-using-ssh" },
        ],
      },
      {
        text: "🏗️ Infrastructure as Code",
        collapsed: false,
        items: [
          { text: "📚 Cloud-Init Concepts", link: "/knowledge/cloud-init" },
          {
            text: "🛠️ Server Initialization",
            link: "/chapters/04-server-initialization",
          },
          { text: "📚 Terraform Concepts", link: "/knowledge/terraform" },
          {
            text: "🛠️ Working with Terraform",
            link: "/chapters/03-working-with-terraform",
          },
          { text: "📚 Module Concepts", link: "/knowledge/modules" },
          {
            text: "🛠️ Terraform Modules",
            link: "/chapters/06-terraform-modules",
          },
        ],
      },
      {
        text: "💾 Storage Management",
        collapsed: false,
        items: [
          { text: "📚 Volume Concepts", link: "/knowledge/volumes" },
          {
            text: "🛠️ Attaching Volumes",
            link: "/chapters/05-attaching-volumes",
          },
        ],
      },
      {
        text: "🌐 Network & DNS",
        collapsed: false,
        items: [
          { text: "📚 DNS Concepts", link: "/knowledge/dns" },
          { text: "🛠️ Setting up DNS", link: "/chapters/07-setting-up-dns" },
        ],
      },
      {
        text: "🔒 Certificates",
        collapsed: false,
        items: [
          {
            text: "📚 Certificate Concepts",
            link: "/knowledge/certificates",
          },
          {
            text: "🛠️ Setting up Certificates",
            link: "/chapters/08-setting-up-certificates",
          },
        ],
      },
    ],
  },
});
