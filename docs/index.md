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
    details: Get your Hetzner Cloud environment running
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
    details: Set up domains and network configuration
    link: /knowledge/dns
  - icon: 📜
    title: Certificate Management
    details: Set up certificates for your domains
    link: /knowledge/certificates
---

## Exercise Overview

Below is a comprehensive list of exercises, linked directly to their respective documentation chapters for easy navigation.

| Exercise Title                                           | Documentation Chapter                                                                                                                |
| :------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| 1. Server creation                                       | [Hetzner Cloud](./chapters/01-hetzner-cloud#_2-creating-your-first-server-exercise-1)                                                |
| 2. Server re-creation                                    | [Hetzner Cloud](./chapters/01-hetzner-cloud#_5-creating-ssh-keys-for-secure-authentication-exercise-2)                               |
| 3. Improve your server's security!                       | [Hetzner Cloud](./chapters/01-hetzner-cloud#_6-improving-server-security-exercise-3)                                                 |
| 4. ssh-agent installation                                | [Using SSH](./chapters/02-using-ssh#_2-solving-the-passphrase-issue-with-ssh-agent-exercise-4)                                       |
| 5. MI Gitlab access by ssh                               | [Using SSH](./chapters/02-using-ssh#mi-gitlab-access-by-ssh-exercise-5)                                                              |
| 6. ssh host hopping                                      | [Using SSH](./chapters/02-using-ssh#_3-intermediate-host-hopping-exercise-6)                                                         |
| 7. ssh port forwarding                                   | [Using SSH](./chapters/02-using-ssh#_4-ssh-port-forwarding-exercise-7)                                                               |
| 8. ssh X11 forwarding                                    | [Using SSH](./chapters/02-using-ssh#_5-ssh-x11-forwarding-exercise-8)                                                                |
| 11. Incrementally creating a base system                 | [Server Initialization](./chapters/04-server-initialization#_1-using-bash-init-scripts-for-server-initialization-exercise-11)        |
| 12. Automatic Nginx installation                         | [Server Initialization](./chapters/04-server-initialization#_2-cloud-init-installing-packages-exercise-12)                           |
| 13. Working on Cloud-init                                | [Server Initialization](./chapters/04-server-initialization#_3-cloud-init-user-management-and-templating-exercise-13)                |
| 14. Solving the ~/.ssh/known_hosts quirk                 | [Server Initialization](./chapters/04-server-initialization#_5-handling-ssh-host-key-mismatches-exercise-14)                         |
| 15. Partitions and mounting                              | [Attaching Volumes](./chapters/05-attaching-volumes#_1-create-a-volume-exercise-15)                                                  |
| 16. Mount point's name specification                     | [Attaching Volumes](./chapters/05-attaching-volumes#_4-managing-mount-points-exercise-16)                                            |
| 17. A module for ssh host key handling                   | [Terraform Modules](./chapters/06-terraform-modules#_2-ssh-known-hosts-module-exercise-17)                                           |
| 18. Enhancing your web server.                           | [Setting up DNS](./chapters/07-setting-up-dns#_3-enhancing-your-web-server-exercise-18)                                              |
| 19. Creating DNS records                                 | [Setting up DNS](./chapters/07-setting-up-dns#_4-creating-dns-records-with-terraform-exercise-19)                                    |
| 20. Creating a host with corresponding DNS entries       | [Setting up DNS](./chapters/07-setting-up-dns#_5-creating-a-host-with-corresponding-dns-entries-exercise-20)                         |
| 21. Creating a fixed number of servers                   | [Setting up DNS](./chapters/07-setting-up-dns#_6-creating-a-fixed-number-of-servers-exercise-21)                                     |
| 22. Creating a web certificate                           | [Setting up Certificates](./chapters/08-setting-up-certificates#_3-creating-a-web-certificate-exercise-22)                           |
| 23. Testing your web certificate                         | [Setting up Certificates](./chapters/08-setting-up-certificates#_4-testing-your-web-certificate-exercise-23)                         |
| 24. Combining certificate generation and server creation | [Setting up Certificates](./chapters/08-setting-up-certificates#_5-combining-certificate-generation-and-server-creation-exercise-24) |
