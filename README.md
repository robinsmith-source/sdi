# SDI Exercises: Software-Defined Infrastructure

This project was built for the [Software-Defined Infrastructure](https://www.hdm-stuttgart.de/vorlesung_detail?vorlid=5213729) course at [Stuttgart Media University](https://www.hdm-stuttgart.de). 

> [!NOTE]
> My documentation provides a step-by-step guide for the [exercises](https://freedocs.mi.hdm-stuttgart.de/apf.html). 
> The deployed documentation is available at [sdi.robinschmidt.dev](https://sdi.robinschmidt.dev).

## Project Structure
```
├── docs/           # Main documentation and knowledge base (VitePress site)
├── exercises/      # Hands-on Terraform exercises (chunked by topic)
│   ├── 03-working-with-terraform/
│   ├── 04-cloud-init/
│   ├── 05-volumes/
│   ├── 06-terraform-modules/
│   ├── 07-dns/
│   ├── 08-certificates/
│   └── modules/    # Reusable Terraform modules
└── README.md       # This file
```

## Getting Started

### 1. Clone the Repository
```sh
git clone git@github.com:robinsmith-source/sdi.git
cd sdi
```

### 2. Configure Secrets for Terraform
Each exercise directory contains a `secret.auto.tfvars.example` file. Copy it to `secret.auto.tfvars` and add your Hetzner Cloud API token:
```sh
cp exercises/03-working-with-terraform/secret.auto.tfvars.example exercises/03-working-with-terraform/secret.auto.tfvars
# Edit the file and set your Hetzner Cloud API token
```
Repeat for other exercise directories as needed.

### 3. Install Terraform
Download and install Terraform for your OS: [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads)

### 4. (Optional) Prepare SSH Keys
Generate an SSH key pair if you don't have one:
```sh
ssh-keygen -t ed25519
```
Add your public key to Hetzner Cloud and your servers as described in the [SSH guide](docs/chapters/01-hetzner-cloud.md#5-creating-ssh-keys-for-secure-authentication).

## Running the Documentation Site Locally
The documentation is built with [VitePress](https://vitepress.dev/) and lives in the `docs/` directory.

### Install Documentation Dependencies
This project uses [bun](https://bun.sh/) for package management. If you don't have bun installed, follow the [installation guide](https://bun.sh/docs/installation).

```sh
cd docs
bun install
```

### Start the Dev Server
```sh
bun docs:dev
```
Visit [http://localhost:5173](http://localhost:5173) to view the docs.

### Build for Production
```sh
bun docs:build
```

## Working with the Exercises
Each exercise is self-contained in its own directory under `exercises/`. Follow the instructions in the corresponding chapter in the documentation (`docs/chapters/`).

### Example: Running a Terraform Exercise
```sh
cd exercises/03-working-with-terraform
terraform init
terraform plan
terraform apply
```
- **Variables:** Sensitive variables (like API tokens) are loaded from `secret.auto.tfvars`.
- **Modules:** Reusable modules are in `exercises/modules/`.
- **Outputs:** Check `output.tf` in each exercise for useful outputs.
