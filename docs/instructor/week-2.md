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

**Step 2: infrastructure as code.** Open `infra/00-bootstrap/main.tf` on the projector before anyone runs anything. Read one resource out loud, the bucket, and show it's just a description: "I want a bucket with this name." Then:

- `plan` is a preview. `apply` does the work. Nothing happens until they type `yes`.
- **State** is Terraform's notebook of what it built. Ask: "What happens if your laptop dies and the notebook was only on it?" That's why it lives in S3, versioned.
- The bootstrap folder is the one exception, keeping its state locally. It's chicken and egg: the bucket can't store the state of the thing that creates the bucket.

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

Show `private.tf` and the `enable_nat` variable. Tell them to remember it: in Week 4 they'll switch it off on purpose and watch what breaks.

**Step 5: teardown as a habit.** Every class ends with destroy plus `whats-running.sh`. Make it a ritual: nobody leaves until their screen says "Nothing billable running."

## Common problems

| Symptom | Cause and fix |
|---|---|
| `aws login` doesn't open a browser | Common in WSL. Use `aws login --remote`, open the link in the Windows browser, paste the code back. |
| `aws: command not found` or old version | AWS CLI v1 from apt, or not installed. Use the official v2 installer in `00-setup.md`. `aws login` needs 2.32 or newer. |
| `No valid credential sources found` | Not signed in, or the 12-hour session expired. `aws login`, then retry. |
| Setup check says signed in, Terraform says it can't find credentials | The `course` profile is missing. Re-run `./scripts/check-setup.sh`. It recreates the profile. |
| `BucketAlreadyExists` in Step 2 | Very unlikely, since the name includes the account ID. If it happens, the student probably ran bootstrap before in this account. Check S3 for an existing `tfstate-` bucket. |
| `init` fails with a missing bucket in Step 3 | Step 2's apply didn't finish, or `infra/backend.hcl` is missing. Re-run `terraform apply` in `00-bootstrap`. |
| NAT gateway creation fails with an access error | Likely a new-style ("projects") account on the Free Plan. Pair them up and follow up after class. |
| Can't see the VPC in the console | Region selector, top-right. Must be Oregon (us-west-2). |
| `Error acquiring the state lock` | A previous command was interrupted. Wait a minute and retry. If it persists: `terraform force-unlock <ID from the message>`. |

## If you're short on time

Steps 3 and 4 can run back to back: check out `step-04` directly and apply once (15 resources). You lose the "Terraform only adds what's new" moment, so mention it out loud instead.

## Costs this week

Only the NAT gateway and its IP address cost anything, a few cents per hour together. A full class with teardown costs well under a dollar per student. The state bucket and the budget stay up all course and cost essentially nothing.
