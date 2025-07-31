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

::: details Exercise Overview

Below is a comprehensive list of exercises, each linked directly to its respective documentation chapter for easy navigation.

| Exercise Title                                                                                                                                                        | Documentation Chapter                                                       |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| 1. [Server creation ](https://medieninformatik.cloud/sdi_cloudProvider_webAdminGui.html#sdiQandaGuiCreateServer)                                                      | [Hetzner Cloud](/chapters/01-hetzner-cloud#exercise-1)                      |
| 2. [Server re-creation](https://medieninformatik.cloud/sdi_cloudProvider_webAdminGui.html#sdiQandaGuiReCreateServer)                                                  | [Hetzner Cloud](/chapters/01-hetzner-cloud#exercise-2)                      |
| 3. [Improve your server's security!](https://medieninformatik.cloud/sdiSshBase.html#sdi_cloudProvider_webAdminGui_quandaServerImproved)                               | [Using SSH](/chapters/02-using-ssh#exercise-3)                              |
| 4. [ssh-agent installation](https://medieninformatik.cloud/sdiSshAgent.html#sdiSshQandaInstallSshAgent)                                                               | [Using SSH](/chapters/02-using-ssh#exercise-4)                              |
| 5. [MI Gitlab access by ssh](https://medieninformatik.cloud/sdiSshAgent.html#sdiSshMiGitlab)                                                                          | [Using SSH](/chapters/02-using-ssh#exercise-5)                              |
| 6. [ssh host hopping](https://medieninformatik.cloud/sdiSshAgentForwarding.html#sdiSshQandaAgentForward)                                                              | [Using SSH](/chapters/02-using-ssh#exercise-6)                              |
| 7. [ssh port forwarding](https://medieninformatik.cloud/sdiSshPortForward.html#sdiSshQandaPortForward)                                                                | [Using SSH](/chapters/02-using-ssh#exercise-7)                              |
| 8. [ssh X11 forwarding](https://medieninformatik.cloud/sdiSshX11Forward.html#sdiSshQandaX11Forward)                                                                   | [Using SSH](/chapters/02-using-ssh#exercise-8)                              |
| 11. [Incrementally creating a base system](https://medieninformatik.cloud/sdi_cloudProvider_terra.html#sdi_cloudProvider_terra_qandaBasicSystem)                      | [Working with Terraform](/chapters/03-working-with-terraform#exercise-11)   |
| 12. [Automatic Nginx installation](https://medieninformatik.cloud/sdi_cloudProvider_cloudInit.html#sdi_cloudProvider_cloudInit_qanda_NginxByBash)                     | [Server Initialization](/chapters/04-server-initialization#exercise-12)     |
| 13. [Working on Cloud-init](https://medieninformatik.cloud/sdi_cloudProvider_cloudInit.html#sdi_cloudProvider_cloudInit_qanda_gettingStarted)                         | [Server Initialization](/chapters/04-server-initialization#exercise-13)     |
| 14. [Solving the ~/.ssh/known_hosts quirk](https://medieninformatik.cloud/sdi_cloudProvider_cloudInit.html#sdi_cloudProvider_cloudInit_qanda_solveSshKnownHosts)      | [Server Initialization](/chapters/04-server-initialization#exercise-14)     |
| 15. [Partitions and mounting](https://medieninformatik.cloud/sdi_cloudProvider_volume.html#sdi_cloudProvider_volume_qanda_ManualMount)                                | [Attaching Volumes](/chapters/05-attaching-volumes#exercise-15)             |
| 16. [Mount point name specification](https://medieninformatik.cloud/sdi_cloudProvider_volume.html#sdi_cloudProvider_volume_qanda_mountPointName)                      | [Attaching Volumes](/chapters/05-attaching-volumes#exercise-16)             |
| 17. [A module for SSH host key handling](https://medieninformatik.cloud/sdi_cloudProvider_modules.html#sdi_cloudProvider_modules_qanda_moduleFileGen)                 | [Terraform Modules](/chapters/06-terraform-modules#exercise-17)             |
| 18. [Enhancing your web server](https://medieninformatik.cloud/sdiDnsProjectNameServer.html#_qanda)                                                                   | [Setting Up DNS](/chapters/07-setting-up-dns#exercise-18)                   |
| 19. [Creating DNS records](https://medieninformatik.cloud/sdi_cloudProvider_dns.html#sdi_cloudProvider_dns_quandaPureDns)                                             | [Setting Up DNS](/chapters/07-setting-up-dns#exercise-19)                   |
| 20. [Creating a host with corresponding DNS entries](https://medieninformatik.cloud/sdi_cloudProvider_dns.html#sdi_cloudProvider_dns_quanda_hostAndDns)               | [Setting Up DNS](/chapters/07-setting-up-dns#exercise-20)                   |
| 21. [Creating a fixed number of servers](https://medieninformatik.cloud/sdi_cloudProvider_dns.html#sdi_cloudProvider_loops_qanda_multiServerGen)                      | [Setting Up DNS](/chapters/07-setting-up-dns#exercise-21)                   |
| 22. [Creating a web certificate](https://medieninformatik.cloud/sdi_cloudProvider_certs.html#sdi_cloudProvider_certs_qanda_createCert)                                | [Setting Up Certificates](/chapters/08-setting-up-certificates#exercise-22) |
| 23. [Testing your web certificate](https://medieninformatik.cloud/sdi_cloudProvider_certs.html#sdi_cloudProvider_certs_qanda_testCert)                                | [Setting Up Certificates](/chapters/08-setting-up-certificates#exercise-23) |
| 24. [Combining certificate generation and server creation](https://medieninformatik.cloud/sdi_cloudProvider_certs.html#sdi_cloudProvider_certs_qanda_tlsCompleteHost) | [Setting Up Certificates](/chapters/08-setting-up-certificates#exercise-24) |

:::
