# Week 2: Lay the foundation

**Today you'll build:** a budget alarm and your own private network in AWS, all from your terminal.

**Before you start:** your laptop is set up ([docs/00-setup.md](00-setup.md)) and you've run `aws login`.

Each step below has the same four parts:

- **Run:** the commands to type. Copy them exactly.
- **You should see:** what success looks like.
- **What just happened:** the idea behind it, in plain words.
- **Look around:** where to find what you built in the AWS console.

---

## Step 1: Check your setup

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-01
./scripts/check-setup.sh
```

**You should see:** a green ✓ on every line and "All set! You are ready for class." A yellow `!` saying you're signed in as the root user is fine.

**What just happened:** the script checked your tools, then created a small AWS setting called the `course` profile. It tells Terraform to use the same sign-in as your `aws login`.

> **Got a ✗?** Read the hint under it. The most common one is "Not signed in to AWS": run `aws login` and try again.

---

## Step 2: Bootstrap: your budget alarm

**Run:**

```bash
git checkout step-02
cd infra/00-bootstrap
terraform init
terraform plan
```

Terraform asks for your email address. That's where budget alerts will go. Type it and press Enter.

**You should see:** the plan ends with `Plan: 1 to add, 0 to change, 0 to destroy.` Nothing has been created yet. A plan is a preview.

Now build it for real:

```bash
terraform apply
```

Type your email again, read the plan, then type `yes`.

**You should see:** `Apply complete! Resources: 1 added` and two outputs, confirming your budget and the address its emails go to.

**What just happened:**

- **Infrastructure as code.** Instead of clicking through the console, you described what you wanted in files (open `main.tf` and look!) and Terraform made it real.
- **`plan`, then `apply`.** Always preview before you change anything. That habit saves real engineers from real disasters.
- **State.** Terraform keeps a record of everything it built, called its *state*. Look in this folder now and you'll see it: `terraform.tfstate`. It sits right next to the code that built it, on your laptop, and it's listed in `.gitignore` because it describes your AWS account rather than the course.
- **The budget alarm** emails you if spending in your account heads toward $10. It's your safety net for the whole course.

**Look around:**

- **Billing and Cost Management** → Budgets → `cloud-devops-course-monthly`.

---

## Step 3: Your own network (VPC) with public subnets

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-03
cd infra/01-network
terraform init
terraform apply
```

Read the plan, then type `yes`.

**You should see:** `Plan: 7 to add` and then `Apply complete! Resources: 7 added`, followed by your `vpc_id` and two `public_subnet_ids`.

**What just happened:**

- **VPC (Virtual Private Cloud):** your own private network inside AWS. Nothing gets in unless you allow it.
- **Two availability zones:** an AWS region is made of separate data centers. Your network spans two, so one having a bad day can't take everything down.
- **Public subnets:** sections of the network that can reach the internet. Later, the load balancer that greets your users lives here.
- **Internet gateway:** the network's front door to the internet.
- **Route table:** a list of directions. The rule "internet traffic goes through the internet gateway" is what makes these subnets public.
- **Every folder keeps its own state.** The apply wrote a `terraform.tfstate` here, separate from the budget alarm's. That's why you can tear the network down and rebuild it without touching anything else.

**Look around:** open **VPC** in the console (make sure the region in the top-right says **Oregon / us-west-2**):

- **Your VPCs** → `course-vpc`
- **Subnets** → `course-public-a` and `course-public-b`. Notice they're in different availability zones.
- **Internet gateways** → `course-igw`
- **Route tables** → `course-public-routes`. Click **Routes** and find the `0.0.0.0/0` rule.

---

## Step 4: Private subnets and the NAT gateway

**Run:** (you're still in `infra/01-network`)

```bash
git checkout step-04
terraform plan
terraform apply
```

**You should see:** `Plan: 8 to add, 0 to change, 0 to destroy.` Terraform only adds what's new. Everything from Step 3 is left alone. The NAT gateway takes 1–2 minutes to create.

**What just happened:**

- **Private subnets:** sections of the network the internet can't reach at all. Next week your database goes here, safely out of reach.
- **NAT gateway:** a one-way door. Things in the private subnets can reach *out* to the internet (to download updates, or to call the Yelp API later), but nobody on the internet can start a connection *in*.
- **No route to the internet gateway** in the private route table. That missing rule is the whole difference between public and private.

**Look around:**

- **Subnets** → `course-private-a` and `course-private-b`
- **NAT gateways** → `course-nat`. Note its public IP address.
- **Route tables** → `course-private-routes`. Its `0.0.0.0/0` rule points to the NAT gateway, not the internet gateway.

> **Cost check:** the NAT gateway costs a few cents for every hour it exists. That's why the next step tears it down.

---

## Step 5: Tear it down and check nothing is left running

**Run:** (still in `infra/01-network`)

```bash
git checkout step-05
terraform destroy
```

Read the list carefully: these are the things that will be deleted. Type `yes`.

**You should see:** `Destroy complete! Resources: 15 destroyed.` This takes 1–2 minutes because of the NAT gateway.

Now check your account:

```bash
cd ~/iec-cloud-infrastructure
./scripts/whats-running.sh
```

**You should see:** `✓ Nothing billable running.` It also lists your budget alarm under "Free to keep". **Keep that**: every future week uses it.

**What just happened:** you deleted the whole network with one command, and because it's all code, you can rebuild it exactly the same next week with one command. That's the superpower of infrastructure as code.

---

## You did it

Today you built, in code:

- a budget alarm that watches your spending
- a two-zone network with public and private subnets and a NAT gateway

On the **Cloud & DevOps Knowledge Pyramid**, that's the *Networking, Routing & Security* layer, plus your first taste of *Cloud Automation*.

**Next week:** a PostgreSQL database in your private subnets, and your app live on its first server.

## Troubleshooting

| You see | What to do |
|---|---|
| `No valid credential sources found` or `ExpiredToken` | Your sign-in expired. Run `aws login`, then try again. |
| `Backend configuration changed` | You ran this folder against the older S3 setup. Run `terraform init -migrate-state` to copy that state down to your laptop. |
| `Unable to find remote state` | A later folder can't find an earlier one's state file. Apply them in order: `01-network` before `02-database` before `03-app`. |
| Can't find your VPC in the console | Check the region in the top-right corner. It must be **Oregon (us-west-2)**. |
| `git checkout` says your changes would be overwritten | You edited a file. Run `git stash`, then try the checkout again. |
