# Cloud Engineering & DevOps Course

Build real infrastructure on AWS, one step at a time, from your own laptop.

**You don't need to write any code.** Everything in this repo is pre-written. Your job is to run each step, look at what it built, and understand why. If you're curious and want to change things, go for it, but it's never required.

## How this repo works

Every step of the course is a **tag** in this repo: `step-01`, `step-02`, and so on. Each tag adds a little more. To work on a step, you check out its tag:

```bash
git checkout step-03
```

Git will say you're in a "detached HEAD" state. That's expected and harmless. It just means you're looking at a snapshot of the course at that step.

To see what a step added, compare it with the one before:

```bash
git diff step-02 step-03
```

## The six weeks

| Week | Milestone | Steps |
|---|---|---|
| 1 | Getting started: AWS account and console tour | (done in class) |
| 2 | **Lay the foundation:** Terraform, a budget alarm, your own VPC and NAT gateway | `step-01` – `step-05` |
| 3 | **Go live:** a PostgreSQL database and the app on its first server | coming soon |
| 4 | **Scale it:** a load balancer and Auto Scaling | coming soon |
| 5 | **Containerize:** Docker, ECR and ECS Fargate | coming soon |
| 6 | **Automate it:** a GitHub Actions pipeline | coming soon |

## Start here

1. Install the tools: [docs/00-setup.md](docs/00-setup.md)
2. Follow this week's guide: [docs/week-2.md](docs/week-2.md)

## Keeping costs at zero

- Every session ends with a **teardown**. Nothing is left running between classes.
- Not sure if something is still running? Run `./scripts/whats-running.sh`. It lists anything in your account that costs money.
- Your budget alarm (built in Week 2) emails you if spending ever approaches $10.
