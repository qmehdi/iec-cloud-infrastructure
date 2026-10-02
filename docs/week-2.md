# Week 2: Lay the foundation

**Today you'll build:** a budget alarm, a place for Terraform to keep its notes, and your own private network in AWS, all from your terminal.

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
cd ~/cloud-devops-course
git checkout step-01
./scripts/check-setup.sh
```

**You should see:** a green ✓ on every line and "All set! You are ready for class." A yellow `!` saying you're signed in as the root user is fine.

**What just happened:** the script checked your tools, then created a small AWS setting called the `course` profile. It tells Terraform to use the same sign-in as your `aws login`.

> **Got a ✗?** Read the hint under it. The most common one is "Not signed in to AWS": run `aws login` and try again.

---

## Step 2: Bootstrap: the budget alarm and the state bucket

**Run:**

```bash
git checkout step-02
cd infra/00-bootstrap
terraform init
terraform plan
```

Terraform asks for your email address. That's where budget alerts will go. Type it and press Enter.

**You should see:** the plan ends with `Plan: 6 to add, 0 to change, 0 to destroy.` Nothing has been created yet. A plan is a preview.

Now build it for real:

```bash
terraform apply
```

Type your email again, read the plan, then type `yes`.

**You should see:** `Apply complete! Resources: 6 added` and three outputs, including your `state_bucket` name.

**What just happened:**

- **Infrastructure as code.** Instead of clicking through the console, you described what you wanted in files (open `main.tf` and look!) and Terraform made it real.
- **`plan`, then `apply`.** Always preview before you change anything. That habit saves real engineers from real disasters.
- **State.** Terraform keeps a record of everything it built, called its *state*. Your new S3 bucket will hold that record for every later step, safely in AWS instead of only on your laptop.
- **The budget alarm** emails you if spending in your account heads toward $10. It's your safety net for the whole course.

**Look around:**

- **S3** → Buckets → `tfstate-...`: your state bucket. It's empty for now.
- **Billing and Cost Management** → Budgets → `cloud-devops-course-monthly`.

---

## Step 3: Your own network (VPC) with public subnets

**Run:**

```bash
cd ~/cloud-devops-course
git checkout step-03
cd infra/01-network
terraform init -backend-config=../backend.hcl
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
- **The `-backend-config` part** told Terraform to store this folder's state in your new bucket. Go look: S3 now has a file in it.

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
cd ~/cloud-devops-course
./scripts/whats-running.sh
```

**You should see:** `✓ Nothing billable running.` It also lists your state bucket and budget alarm under "Free to keep". **Keep those**: every future week uses them.

**What just happened:** you deleted the whole network with one command, and because it's all code, you can rebuild it exactly the same next week with one command. That's the superpower of infrastructure as code.

---

## You did it

Today you built, in code:

- a budget alarm that watches your spending
- a secure, versioned bucket for Terraform's state
- a two-zone network with public and private subnets and a NAT gateway

On the **Cloud & DevOps Knowledge Pyramid**, that's the *Networking, Routing & Security* layer, plus your first taste of *Cloud Automation*.

**Next week:** a PostgreSQL database in your private subnets, and your app live on its first server.

## Troubleshooting

| You see | What to do |
|---|---|
| `No valid credential sources found` or `ExpiredToken` | Your sign-in expired. Run `aws login`, then try again. |
| `Error: Failed to get existing workspaces` or `NoSuchBucket` during `init` | Step 2 didn't finish. Go back to `infra/00-bootstrap` and run `terraform apply`. |
| `Backend configuration changed` | Run `terraform init -reconfigure -backend-config=../backend.hcl` |
| Can't find your VPC in the console | Check the region in the top-right corner. It must be **Oregon (us-west-2)**. |
| `git checkout` says your changes would be overwritten | You edited a file. Run `git stash`, then try the checkout again. |
