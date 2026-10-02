# Setup: get your laptop ready

Do this **before Week 2**. It takes about 20 minutes. If anything goes wrong, don't worry: bring your laptop to class and we'll fix it together.

You'll install four things:

| Tool | What it's for |
|---|---|
| **AWS CLI** (version 2.32 or newer) | Lets your terminal talk to your AWS account |
| **Terraform** (version 1.10 or newer) | Builds AWS infrastructure from code |
| **Git** | Downloads the course and moves between steps |
| **VS Code** | A friendly editor for reading the course files (optional but recommended) |

## Windows: install WSL first

The course runs in a Linux terminal. On Windows, you get one with **WSL** (Windows Subsystem for Linux):

1. Open **PowerShell as Administrator** (right-click the Start button → Terminal (Admin)).
2. Run:
   ```powershell
   wsl --install -d Ubuntu
   ```
3. Restart your computer when asked.
4. Open **Ubuntu** from the Start menu. It will ask you to pick a username and password. Remember them.

From now on, run **every** course command inside the Ubuntu window, and follow the **Linux** instructions below.

## macOS

1. Install Homebrew if you don't have it: follow the one-line install at https://brew.sh
2. Then run:
   ```bash
   brew install awscli git
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

## Linux (and Windows inside Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y git unzip curl gnupg software-properties-common

# AWS CLI v2
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o awscliv2.zip
unzip -q awscliv2.zip && sudo ./aws/install --update && rm -rf aws awscliv2.zip

# Terraform (from HashiCorp's official package repository)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
```

## Check the versions

```bash
aws --version        # should say aws-cli/2.32 or higher
terraform -version   # should say Terraform v1.10 or higher
git --version
```

## Download the course

```bash
cd ~
git clone https://github.com/qmehdi/cloud-devops-course.git
cd cloud-devops-course
```

## Sign in to AWS from your terminal

```bash
aws login
```

A browser window opens. Sign in the same way you sign in to the AWS console. When it says you're done, come back to the terminal. If it asks for a region, type `us-west-2`.

> **No browser opened?** (Common in WSL.) Run `aws login --remote` instead. It prints a link: open it in your normal browser, sign in, then paste the code it shows back into the terminal.

Your sign-in lasts up to 12 hours, which covers a whole class. Next week, just run `aws login` again.

## Run the setup check

```bash
./scripts/check-setup.sh
```

Every line should show a green ✓. If you see a ✗, the message next to it tells you what to do. Still stuck? Bring it to class.

## Install VS Code (optional)

Download it from https://code.visualstudio.com. On Windows, also install the **WSL** extension, then open the course folder by running `code .` inside the Ubuntu window.
