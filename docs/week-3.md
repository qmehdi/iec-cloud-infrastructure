# Week 3: Go live

**Today you'll build:** a PostgreSQL database that AWS runs for you, a load balancer, and
your app live on its own server, in code, from your terminal. By the end you'll have a web
address you can send to a friend.

**Before you start:** your laptop is set up ([docs/00-setup.md](00-setup.md)) and you've run
`aws login`.

Each step has the same four parts:

- **Run:** the commands to type. Copy them exactly.
- **You should see:** what success looks like.
- **What just happened:** the idea behind it, in plain words.
- **Look around:** where to find what you built in the AWS console.

---

## Step 1: Rebuild your network

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-06
cd infra/01-network
terraform init
terraform apply
```

Read the plan, then type `yes`.

**You should see:** `Plan: 15 to add, 0 to change, 0 to destroy.` and after a minute or two
`Apply complete! Resources: 15 added`, followed by your `vpc_id`, subnet IDs and
`nat_public_ip`.

**What just happened:** last week you destroyed all of this. Today you rebuilt it exactly,
with one command, in about two minutes. Nobody clicked anything in a console, and nothing
was left running overnight costing money. That is the entire promise of infrastructure as
code, and you just collected on it.

**Look around:** **VPC** → **Your VPCs** → `course-vpc`. It's identical to last week's, with
a different ID.

> **Keep this terminal open.** You'll come back to this folder at the end of class to tear
> it all down.

---

## Step 2: A database, run by AWS

The database takes a few minutes to build, so we start it now and talk about it while it
works.

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-07
cd infra/02-database
terraform init
terraform apply
```

Read the plan, then type `yes`.

**You should see:** `Plan: 4 to add`. The line `aws_db_instance.main: Still creating...`
repeats for **three to six minutes**. That's normal: AWS is building a real database server.
When it finishes you'll see `Apply complete! Resources: 4 added` and outputs including
`db_endpoint`.

**What just happened:**

- **A managed service.** You didn't install PostgreSQL, and you won't patch it, back it up,
  or babysit it. You described the database you wanted and AWS is now operating it for you.
  This is the single biggest reason people use a cloud provider.
- **It lives in your private subnets.** Open `rds.tf` and find `publicly_accessible = false`.
  There is no route from the internet to this database. The only things that can reach it are
  inside your VPC.
- **Nobody knows the password.** Find `manage_master_user_password = true`. AWS generated a
  long random password, stored it in **Secrets Manager**, and never showed it to anyone. Your
  app will read it from there when it starts. You will never type it, and it is not in this
  repository.
- **A subnet group** is the list of subnets a database is allowed to live in. AWS insists on
  at least two availability zones, so it could move your database to the other data centre if
  one failed.
- **An empty secret.** We also created a secret for a Yelp API key, with nothing in it yet.
  You'll fill it in at Step 5.

**Look around:**

- **RDS** → **Databases** → `course-db`. Look at **Connectivity & security**: it has no
  public address.
- **Secrets Manager** → you'll see two secrets. Open the one starting `rds!db-` and click
  **Retrieve secret value**: that's the password AWS made up. Close it again.
- **RDS** → **Subnet groups** → `course-db-subnets`: both private subnets.

---

## Step 3: The app goes live

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-08
cd infra/03-app
terraform init
terraform apply
```

Read the plan, then type `yes`.

**You should see:** `Plan: 17 to add` and, after two or three minutes,
`Apply complete! Resources: 17 added` with an `app_url` like
`http://course-alb-123456789.us-west-2.elb.amazonaws.com`.

**Open that address in your browser.** The first try may say 502 or take a few seconds:
the server is still installing the app. Wait half a minute and reload.

**You should see:** **Neighborhood Eats**, with six sample restaurants. Click one, click
**Write a review**, give it some stars and your name, and save it. Your review appears.
Then open **About this server** in the top-right.

**What just happened:** you built the standard shape of a web application on AWS.

```
   you  ──►  load balancer  ──►  app server  ──►  database
             (public subnet)     (private subnet)  (private subnet)
```

- **The load balancer** is the only part of your network open to the internet. It has a
  public address; your server does not.
- **The app server has no public IP at all.** Check in the console: the column is empty.
  Nothing on the internet can connect to it. It still serves the whole internet, through the
  load balancer.
- **The health check.** Every 15 seconds the load balancer asks the server for `/health`. If
  it stops answering, the load balancer stops sending it visitors. Open
  `your-app-url/health` to see what it replies.
- **Three firewalls in a chain.** Open `security.tf`. The load balancer accepts traffic from
  anyone; the app server accepts it *only from the load balancer's security group*; the
  database accepts it *only from the app server's*. Notice those rules name each other rather
  than IP addresses.
- **The server set itself up.** Open `user-data.sh.tftpl`. That's a plain shell script AWS ran
  on first boot: install Python and nginx, fetch the app at a pinned version, write its
  settings, start it. No one logged in to do it.
- **The password went straight from AWS to the app.** The server was given permission to read
  that one secret, and read it when it started. It was never written into a file by Terraform
  and it isn't in any output.

**Look around:**

- **EC2** → **Instances** → `course-app`. Note the empty **Public IPv4 address** column.
- **EC2** → **Target groups** → `course-app-tg` → **Targets**: your server, `healthy`.
- **EC2** → **Load balancers** → `course-alb`: its DNS name is the address you just opened.
- **EC2** → **Security groups**: `course-alb-sg`, `course-app-sg`, `course-db-sg`. Read the
  inbound rule on each one and follow the chain.

---

## Step 4: Look inside the server

No new code for this step. Everything here happens in the AWS console and on the server.

**Run:** in the console, go to **EC2** → **Instances** → tick `course-app` → **Connect** →
choose the **Session Manager** tab → **Connect**.

A black terminal opens in your browser. You are on the server.

> **No SSH key. No password. No open port.** That machine has nothing listening to the
> internet. You got in because the server has permission to talk to AWS, and AWS let you
> through. This is how shells on servers should work.

Try these, one at a time:

```bash
# Is the app running? (q to quit)
sudo systemctl status neighborhood-eats

# What has it been saying? (Ctrl-C to stop following)
sudo journalctl -u neighborhood-eats -f

# Ask the app, from the server itself, the same question the load balancer asks
curl localhost/health

# What the setup script did on first boot
sudo tail -40 /var/log/user-data.log

# The settings Terraform wrote. Note the secret NAMES, and the absence of any password
sudo cat /etc/neighborhood-eats.env
```

### Now break it on purpose

```bash
sudo systemctl stop neighborhood-eats
```

Go back to **EC2** → **Target groups** → `course-app-tg` → **Targets** and watch. Within
about 45 seconds your server turns `unhealthy`. Reload the site: the load balancer has
nothing healthy to send you to, so you get an error page.

Now put it back:

```bash
sudo systemctl start neighborhood-eats
```

Watch the target go `healthy` again, and reload the site. It's back.

**What just happened:** you just did by hand what next week gets automated. The load balancer
noticed a broken server within seconds and stopped sending it traffic. The only thing missing
is somebody to *replace* it, and that's Week 4.

---

## Step 5: Switch on live Yelp search

**Optional.** It needs a free Yelp API key from [fusion.yelp.com](https://fusion.yelp.com)
(a 30-day trial, no card). Without one, everything else in the app still works; you'll just
see a note where the search bar would be. If you don't have a key, read along with a
classmate who does.

**Run:**

```bash
cd ~/iec-cloud-infrastructure
git checkout step-09
./scripts/set-yelp-key.sh
```

Paste your key when it asks. You won't see it as you type, and it never touches your shell
history.

**You should see:** `✓ Key stored in Secrets Manager`, then `✓ App restarted`.

Reload the site. A search bar has appeared. Search for something near you (`tacos`,
`Portland, OR`), open a real restaurant from the results, and write a class review on it.

**What just happened:**

- **Nothing was rebuilt.** No `terraform apply`, no new server, not one line of code changed.
  A secret changed, and the app read it on restart. That's the difference between
  configuration and code, and it's why the key was never in the repository.
- **The app reads its secrets once, at startup.** That's why it needed a restart. The script
  did it for you over Session Manager, without logging in.
- **Our reviews are ours.** The stars on a Yelp restaurant are from your class, stored in your
  database. Yelp's terms don't allow us to store their content, so the app keeps only the
  business's Yelp ID and fetches the details live every time, with a "View on Yelp" link. We
  never show Yelp's own ratings.

**Look around:** **Secrets Manager** → `course/yelp-api-key` → **Retrieve secret value**. Your
key is in there, encrypted, and only the app server is allowed to read it.

---

## Step 6: Tear it all down

**The order matters.** The app depends on the database, which depends on the network. Destroy
them in reverse: newest first.

**Run:**

```bash
cd ~/iec-cloud-infrastructure/infra/03-app
terraform destroy
```

Type `yes`. Then:

```bash
cd ../02-database
terraform destroy
```

Type `yes`. This one takes a few minutes. Then:

```bash
cd ../01-network
terraform destroy
```

Type `yes`.

Now check your account:

```bash
cd ~/iec-cloud-infrastructure
./scripts/whats-running.sh
```

**You should see:** `✓ Nothing billable running.` It lists your budget alarm under
"Free to keep" — **keep that**, every week uses it.

> **Don't leave before your screen says that.** The database and the NAT gateway are the two
> most expensive things you've built so far.

**What just happened:** try destroying them in the wrong order sometime and you'll see why we
don't. AWS refuses to delete a network that still has a server in it. Dependencies run one
way, so teardown runs the other.

---

## You did it

Today you built, in code:

- a PostgreSQL database that AWS runs, in a private subnet, with a password nobody has seen
- a load balancer, and a server with no public address behind it
- a real web app, installed at a pinned version by a script you can read
- a shell on a private server, with no keys and nothing open to the internet

On the **Cloud & DevOps Knowledge Pyramid**, that's *Compute & Hosting*, *Databases &
Storage*, and *Identity & Secrets*, sitting on last week's networking.

**Next week:** what happens when that server dies at 3am? Two or more servers behind the same
load balancer, Auto Scaling to replace unhealthy ones automatically, and shipping a new
version without taking the site down.

## Troubleshooting

| You see | What to do |
|---|---|
| `No valid credential sources found` or `ExpiredToken` | Your sign-in expired. Run `aws login`, then try again. |
| Your course folder is called `cloud-devops-course` | That's fine, it's the same repo under an older name. Use `cd ~/cloud-devops-course` wherever these notes say `cd ~/iec-cloud-infrastructure`. |
| `Unable to find remote state` | This folder reads the previous one's state file and can't find it. `02-database` needs `01-network` applied first; `03-app` needs both. Check you're in the right folder too. |
| `Backend configuration changed` | You have a `.terraform/` folder from the older S3 version of the course. Run `terraform init -migrate-state`. |
| `502 Bad Gateway` or a blank page on the app URL | The server is still installing. Wait 30 seconds and reload. If it persists, check Step 4's `sudo tail -40 /var/log/user-data.log`. |
| The app URL doesn't resolve at all | A brand new load balancer address can take a minute to appear in DNS. Wait, then reload. |
| Target shows `unhealthy` in the target group | Give it a minute after apply. Still unhealthy? Connect with Session Manager and run `sudo systemctl status neighborhood-eats`. |
| `Connect` → Session Manager is greyed out | The SSM agent needs a minute after boot, and the server needs its NAT gateway. Wait, then reload the page. |
| About page says the database is **not reachable** | Check `course-db` is `Available` in RDS, and that `terraform apply` finished in `infra/03-app` (it adds the database's firewall rule). |
| `NatGatewayLimitExceeded` or a NAT permission error in Step 1 | Some very new AWS accounts can't create NAT gateways. Run `terraform apply -var enable_nat=false`, then pair up with a classmate for Steps 3 to 5. Flag it to your instructor. |
| `terraform destroy` in `01-network` hangs or fails | Something is still using the network. Make sure `03-app` and `02-database` were destroyed first. |
| Session Manager says `sudo: command not found` or similar | Type `sudo -i` first to get a root shell, then run the commands without `sudo`. |
