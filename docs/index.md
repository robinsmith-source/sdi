---
layout: home

hero:
  name: "SDI Exercises"
  text: "Software-Defined Infrastructure"
  tagline: "Practical exercises for cloud infrastructure setup"
  actions:
    - theme: brand
      text: Get Started
      link: /chapters/01-hetzner-cloud
    - theme: alt
      text: View Repository
      link: "https://github.com/robinsmith-source/sdi"

features:
  - icon: 🚀
    title: Cloud Setup
    details: Set up your Hetzner Cloud environment
    link: /chapters/01-hetzner-cloud
  - icon: 🔐
    title: SSH & Access
    details: Configure secure remote access to your servers
    link: /knowledge/ssh
  - icon: 🏗️
    title: Infrastructure as Code
    details: Automate deployments with Cloud-Init and Terraform
    link: /knowledge/terraform
  - icon: 💾
    title: Storage Management
    details: Manage storage volumes and attach them to servers
    link: /knowledge/volumes
  - icon: 🌐
    title: DNS & Networking
    details: Set up domains and network configurations
    link: /knowledge/dns
  - icon: 📜
    title: Certificate Management
    details: Set up certificates for your domains
    link: /knowledge/certificates
---

## Exercise Overview

Below is a comprehensive list of exercises, each linked directly to its respective documentation chapter for easy navigation.

| Exercise Title                                           | Documentation Chapter                                                        |
| :------------------------------------------------------- | :--------------------------------------------------------------------------- |
| 1. Server creation                                       | [Hetzner Cloud](./chapters/01-hetzner-cloud#exercise-1)                      |
| 2. Server re-creation                                    | [Hetzner Cloud](./chapters/01-hetzner-cloud#exercise-2)                      |
| 3. Improve your server's security!                       | [Using SSH](./chapters/02-using-ssh#exercise-3)                              |
| 4. ssh-agent installation                                | [Using SSH](./chapters/02-using-ssh#exercise-4)                              |
| 5. MI Gitlab access by ssh                               | [Using SSH](./chapters/02-using-ssh#exercise-5)                              |
| 6. ssh host hopping                                      | [Using SSH](./chapters/02-using-ssh#exercise-6)                              |
| 7. ssh port forwarding                                   | [Using SSH](./chapters/02-using-ssh#exercise-7)                              |
| 8. ssh X11 forwarding                                    | [Using SSH](./chapters/02-using-ssh#exercise-8)                              |
| 11. Incrementally creating a base system                 | [Working with Terraform](./chapters/03-working-with-terraform#exercise-11)   |
| 12. Automatic Nginx installation                         | [Server Initialization](./chapters/04-server-initialization#exercise-12)     |
| 13. Working on Cloud-init                                | [Server Initialization](./chapters/04-server-initialization#exercise-13)     |
| 14. Solving the ~/.ssh/known_hosts quirk                 | [Server Initialization](./chapters/04-server-initialization#exercise-14)     |
| 15. Partitions and mounting                              | [Attaching Volumes](./chapters/05-attaching-volumes#exercise-15)             |
| 16. Mount point name specification                       | [Attaching Volumes](./chapters/05-attaching-volumes#exercise-16)             |
| 17. A module for SSH host key handling                   | [Terraform Modules](./chapters/06-terraform-modules#exercise-17)             |
| 18. Enhancing your web server                            | [Setting Up DNS](./chapters/07-setting-up-dns#exercise-18)                   |
| 19. Creating DNS records                                 | [Setting Up DNS](./chapters/07-setting-up-dns#exercise-19)                   |
| 20. Creating a host with corresponding DNS entries       | [Setting Up DNS](./chapters/07-setting-up-dns#exercise-20)                   |
| 21. Creating a fixed number of servers                   | [Setting Up DNS](./chapters/07-setting-up-dns#exercise-21)                   |
| 22. Creating a web certificate                           | [Setting Up Certificates](./chapters/08-setting-up-certificates#exercise-22) |
| 23. Testing your web certificate                         | [Setting Up Certificates](./chapters/08-setting-up-certificates#exercise-23) |
| 24. Combining certificate generation and server creation | [Setting Up Certificates](./chapters/08-setting-up-certificates#exercise-24) |
