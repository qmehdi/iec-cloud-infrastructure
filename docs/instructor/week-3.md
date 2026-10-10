# Instructor notes: Week 3

Students follow [docs/week-3.md](../week-3.md). These notes are for you: timing, what to say,
and what usually goes wrong.

## Before class

- [ ] Run all six steps yourself in your own account, end to end, a few days ahead. Time how
      long the RDS creation and the first boot of the app server take on the day; both vary.
- [ ] Get a Yelp API key yourself ([fusion.yelp.com](https://fusion.yelp.com), free 30-day
      trial, no card) so you can demo Step 5 even if nobody in the room has one.
- [ ] Tell students a week ahead that a Yelp key is optional but unlocks the last step. Point
      them at the trial link. Expect half the room not to have one.
- [ ] Check the app repo tag: `infra/03-app/variables.tf` pins `app_version`. It must point at
      a tag that exists in **neighborhood-eats**, or every server boots to a 502.
- [ ] Have the diagram below on a whiteboard or slide before Step 3.
- [ ] Anyone whose account blocked NAT gateways last week: pair them up now, don't discover it
      at 0:10.

## Run of show (2 hours)

| Time | Step | Notes |
|---|---|---|
| 0:00–0:15 | **Step 1:** `aws login`, rebuild the network | Deliberately easy. It absorbs the late arrivals and the expired sign-ins. |
| 0:15–0:35 | **Step 2:** the database | Start the apply at 0:17 at the latest, then teach for the rest of the slot while it builds. |
| 0:35–1:05 | **Step 3:** load balancer and server | The apply takes 2–3 min. Everyone must get the site open and write one review. |
| 1:05–1:35 | **Step 4:** inside the server | The best part of the day. Session Manager, logs, then break it and fix it. |
| 1:35–1:45 | **Step 5:** the Yelp key | Short. Those without a key watch a neighbour. |
| 1:45–2:00 | **Step 6:** teardown | Nobody leaves until their screen says "Nothing billable running". |

The schedule's one real risk is RDS creation time. Starting it before you teach about it is
the whole trick; don't let the room sit and watch a progress line.

## What to say at each step

**Step 1: collect on last week's promise.** Say it out loud: *"Last week you deleted all of
this. Watch how long it takes to get it back."* Then run the apply. Two minutes later they
have an identical network. That's the moment infrastructure as code stops being an abstract
idea.

**Step 2: managed services, and a password nobody knows.**

Open `infra/02-database/rds.tf` on the projector while the apply runs. Three lines to read out:

- `publicly_accessible = false` — there is no route from the internet to this database.
- `manage_master_user_password = true` — this is the one to dwell on. Ask the room: *"Who
  here has seen a database password in a config file in a git repository?"* AWS generates
  this one, stores it in Secrets Manager, and nobody ever sees it. The app is given permission
  to read it, and does, once, when it starts.
- `db_subnet_group_name` — AWS insists on two availability zones even for a single database,
  so it could move it if one data centre failed.

Good question to ask while you wait: *"What are we actually paying for here?"* Answer: a
server, its disk, and somebody else doing the backups, patching and failover. That's the
entire pitch of a managed service.

**Step 3: draw this before they apply.**

```
                        Internet
                            │
                   ┌────────┴─────────┐
                   │  Load balancer   │   public subnets, port 80 open
                   └────────┬─────────┘
       ┌────────────────────┼──────────────────────┐  VPC 10.0.0.0/16
       │           ┌────────┴─────────┐            │
       │           │   App server     │  private   │  no public IP
       │           │  nginx+gunicorn  │            │
       │           └────────┬─────────┘            │
       │           ┌────────┴─────────┐            │
       │           │    PostgreSQL    │  private   │  port 5432, app only
       │           └──────────────────┘            │
       └───────────────────────────────────────────┘
```

Then open `security.tf` and trace the chain with a finger: internet → ALB → app → database.
The sentence worth repeating: **the rules name each other, not IP addresses.** Whatever
addresses the load balancer ends up with, the rule follows it. This is the thing most people
get wrong for years.

Second point, once the site is up: *"Go look at your instance in the console. The Public IP
column is empty."* Let that land. The server everyone in the room just loaded a web page from
cannot be reached from the internet at all.

Third point: open `user-data.sh.tftpl`. It's a shell script. Nothing magic happened; AWS ran
those commands as root on first boot. Point at the `git clone --branch` line and say why it's
a pinned tag and not `main`: twenty students should get identical servers, and a commit pushed
during class shouldn't change anybody's.

**Have everyone write a review before you move on.** It proves the whole chain works, and
Step 4 is better when there's data in the database to lose.

**Step 4: the best thirty minutes of the course so far.**

Let them find Session Manager themselves in the console; it's a useful piece of console
literacy. While they do: *"No SSH key, no password, no open port. The server has permission
to talk to AWS, and AWS let you in."*

Then the stop/start demo, and make them watch the target group while it happens:

```bash
sudo systemctl stop neighborhood-eats
```

Roughly 45 seconds later (15-second interval, 3 failures) the target goes unhealthy and the
site errors. Use the wait: *"The load balancer found out on its own. Nobody paged anybody.
What's missing?"* Someone will say "something to restart it" — that's your Week 4 opening.
Then start it again and watch it recover.

If the room is fast, `sudo cat /etc/neighborhood-eats.env` is worth projecting: the secret
*names* are there, the secrets are not.

**Step 5: configuration is not code.** The line to land: *"No apply. No new server. Not one
line of code changed. A secret changed and the app read it."* Then the Yelp terms point,
briefly and without a lecture: we store their business ID and nothing else, we fetch details
live, we credit them, and every star on the site was written by this class.

**Step 6: teardown as a ritual.** Same as last week, with one addition: the order. Ask *"why
newest first?"* before telling them. AWS won't delete a network with a server in it;
dependencies point one way, so teardown goes the other.

Watch for the student who destroys `01-network` first, gets a dependency-violation error, and
thinks they broke something. They didn't; it's the lesson.

## Common problems

| Symptom | Cause and fix |
|---|---|
| `ExpiredToken` / `No valid credential sources` | Sign-in expired. `aws login`, retry. Happens most at 0:00 and after a long Step 4. |
| `NoSuchBucket` on `init` | Week 2's bootstrap never finished, or `infra/backend.hcl` is missing. Run `terraform apply` in `00-bootstrap`. |
| RDS apply still running at 0:35 | Move on and come back. Step 3's apply will wait on the database only for its outputs, so start Step 3's `init` meanwhile. |
| `InvalidParameterValue: engine version` | Postgres 17 not offered in the region/class. Set `-var db_engine_version=16`. |
| 502 or blank page on the app URL | Still installing. 30 seconds, reload. If it sticks: `sudo tail -40 /var/log/user-data.log` on the server. |
| App URL doesn't resolve | New ALB DNS name needs a minute to propagate. Wait. |
| Target stuck `unhealthy` | Usually the app failed to start. `sudo systemctl status neighborhood-eats`, then `sudo journalctl -u neighborhood-eats -n 50`. Most likely cause: the pinned app tag doesn't exist. |
| About page: database **not reachable** | `03-app` adds the rule that lets the app reach the database. Check its apply finished. Then check `course-db` is `Available`. |
| Session Manager greyed out or "not connected" | SSM agent needs a minute after boot, and needs the NAT gateway to reach AWS. If the student ran with `enable_nat=false`, Session Manager will not work at all; pair them up. |
| `set-yelp-key.sh` says no running app server | They're on an older tag, or the server is gone. `git checkout step-09`, confirm the instance is running. |
| Search bar still missing after the key | The restart didn't land. Session Manager → `sudo systemctl restart neighborhood-eats`. |
| New-style account blocks NAT | `terraform apply -var enable_nat=false` in `01-network`. They get no NAT, so no Session Manager and no Yelp; pair them with a classmate for Steps 3–5. |
| `destroy` on `01-network` fails with a dependency error | `03-app` or `02-database` is still up. Destroy those first. This is worth showing the whole room once. |

## If you're short on time

- **Cut Step 5.** It's already marked optional, and it's ten minutes.
- **Shorten Step 4** to Session Manager plus the stop/start demo, and skip the log reading.
- **Don't cut the teardown.** Ever. A forgotten RDS instance plus a NAT gateway is the one way
  a student in this course sees a real bill.

What you should not cut is everyone getting the site open and writing a review. If they leave
without that, the week didn't happen.

## Costs this week

Per student, per two-hour class, with teardown: roughly **20 to 30 cents**.

| Thing | Rough cost while it runs |
|---|---|
| NAT gateway + its IP | ~5¢/hour |
| RDS db.t4g.micro + 20GB | ~2¢/hour |
| Application Load Balancer | ~2.5¢/hour |
| EC2 t3.micro | ~1¢/hour |

The state bucket and the budget alarm stay up all course and cost essentially nothing. The
one real risk is a student who closes their laptop without destroying: an RDS instance and a
NAT gateway left running for a month is about $55, which their $10 budget alarm will shout
about long before then.
