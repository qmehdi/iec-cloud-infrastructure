# Instructor notes: Week 2

Students follow [docs/week-2.md](../week-2.md). These notes are for you: timing, what to say, and what usually goes wrong.

## Before class

- [ ] Run all five steps yourself in your own account, end to end, a few days ahead. Note how long `terraform init` and the NAT gateway take on your network.
- [ ] Students got the install list ([docs/00-setup.md](../00-setup.md)) at least a few days before class.
- [ ] Ask in advance (or at the door): when did you create your AWS account, and do you sign in as **Root user** with an email and password? Anyone who mentions "projects" or "AWS Settings" signed up the new way. Pair them with a classmate until you've confirmed their account can create a NAT gateway.
- [ ] Have a whiteboard or slide ready for the network diagram (below).

## Run of show (2 hours)

| Time | Step | Notes |
|---|---|---|
| 0:00–0:15 | **Step 1:** clone, `aws login`, setup check | Don't move on until every screen is green. Pair fast students with stuck ones. |
| 0:15–0:40 | **Step 2:** bootstrap | Teach infrastructure as code, plan vs apply, and state before they type `apply`. |
| 0:40–1:05 | **Step 3:** VPC and public subnets | Draw the diagram first, then apply, then find each piece in the console. |
| 1:05–1:35 | **Step 4:** private subnets and NAT | NAT takes 1–2 min to create. Use the wait for questions. |
| 1:35–1:50 | **Step 5:** destroy and safety check | Everyone shows you "Nothing billable running" before they leave. |
| 1:50–2:00 | Wrap-up | Point to the networking layer of the pyramid. Preview Week 3. |

## What to say at each step

**Step 2: infrastructure as code.** Open `infra/00-bootstrap/main.tf` on the projector before anyone runs anything. Read the budget resource out loud and show it's just a description: "I want to be emailed if I spend more than $10." Then:

- `plan` is a preview. `apply` does the work. Nothing happens until they type `yes`.
- **State** is Terraform's notebook of what it built. After the apply, have them open `terraform.tfstate` in the folder. It's JSON, it's readable, and seeing it demystifies the whole idea.
- Say plainly where it lives: on their laptop, one file per folder, never in git. If someone asks what happens when the laptop dies, that's the right question — on a real team this file lives in shared storage so everybody works from the same notebook. One laptop per student is why a local file is the honest choice here.

**Step 3: draw this before they apply.**

```
                     Internet
                        │
                ┌───────┴────────┐
                │ Internet gateway│
        ┌───────┴────────────────┴────────┐  VPC 10.0.0.0/16
        │  ┌──────────────┐ ┌──────────────┐ │
        │  │ public-a      │ │ public-b      │ │  ← Step 3
        │  │ 10.0.0.0/24   │ │ 10.0.1.0/24   │ │
        │  └──────────────┘ └──────────────┘ │
        │  ┌──────────────┐ ┌──────────────┐ │
        │  │ private-a     │ │ private-b     │ │  ← Step 4
        │  │ 10.0.10.0/24  │ │ 10.0.11.0/24  │ │
        │  └──────────────┘ └──────────────┘ │
        │      zone a            zone b        │
        └──────────────────────────────────────┘
```

Analogy that works for beginners: the VPC is an office building. Public subnets are the lobby, which has a street door (the internet gateway). Private subnets are the back offices, with no street door. The NAT gateway is the mail room: back offices can send mail out and get replies, but strangers can't walk in.

**Step 4: Terraform changes, it doesn't start over.** Point at `Plan: 8 to add, 0 to change, 0 to destroy`. Terraform compared the code to its state and only added what's new. That's the core of how infrastructure is managed at real companies.

Show `private.tf` and the `enable_nat` variable. It's the escape hatch for accounts that refuse to create a NAT gateway, and the reason the course can carry on without one.

**Step 5: teardown as a habit.** Every class ends with destroy plus `whats-running.sh`. Make it a ritual: nobody leaves until their screen says "Nothing billable running."

## Common problems

| Symptom | Cause and fix |
|---|---|
| `aws login` doesn't open a browser | Common in WSL. Use `aws login --remote`, open the link in the Windows browser, paste the code back. |
| `aws: command not found` or old version | AWS CLI v1 from apt, or not installed. Use the official v2 installer in `00-setup.md`. `aws login` needs 2.32 or newer. |
| `No valid credential sources found` | Not signed in, or the 12-hour session expired. `aws login`, then retry. |
| Setup check says signed in, Terraform says it can't find credentials | The `course` profile is missing. Re-run `./scripts/check-setup.sh`. It recreates the profile. |
| `Backend configuration changed` | They have a `.terraform/` from the older S3 version of the course. `terraform init -migrate-state` pulls that state down to the laptop; `rm -rf .terraform` and a fresh `init` also works if they have nothing built. |
| `Unable to find remote state` in Step 3 | Only bites from Week 3 on, when a folder reads an earlier one's state. Means they skipped a folder, or are running from the wrong directory. |
| NAT gateway creation fails with an access error | Likely a new-style ("projects") account on the Free Plan. Pair them up and follow up after class. |
| Their account only allows one region | Some new accounts are pinned to a single region. Everything is parameterised, so have them `export AWS_REGION=<region> TF_VAR_region=<region>` (it's in `00-setup.md`), and run `COURSE_REGION=<region> ./scripts/check-setup.sh` so their profile matches. |
| Can't see the VPC in the console | Region selector, top-right. Must match the region they built in (Oregon / us-west-2 by default). |
| `Error acquiring the state lock` | A previous command was interrupted. Wait a minute and retry. If it persists: `terraform force-unlock <ID from the message>`. |

## If you're short on time

Steps 3 and 4 can run back to back: check out `step-04` directly and apply once (15 resources). You lose the "Terraform only adds what's new" moment, so mention it out loud instead.

## Costs this week

Only the NAT gateway and its IP address cost anything, a few cents per hour together. A full class with teardown costs well under a dollar per student. The budget alarm stays up all course and costs nothing.
