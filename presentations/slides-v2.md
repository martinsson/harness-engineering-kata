---
marp: true
theme: default
paginate: true
backgroundColor: "#0a0e14"
color: "#e6e7ea"
style: |
  section {
    font-family: 'Inter', 'Helvetica Neue', sans-serif;
    background: #0a0e14;
    color: #e6e7ea;
    padding: 70px 90px;
    font-size: 28px;
    line-height: 1.45;
  }
  section.lead {
    background: radial-gradient(ellipse at 30% 20%, #1a2434 0%, #0a0e14 70%);
    justify-content: center;
  }
  section.hero {
    background: radial-gradient(ellipse at 50% 50%, #131a25 0%, #0a0e14 75%);
    justify-content: center;
    text-align: left;
  }
  h1 {
    color: #ffffff;
    letter-spacing: -0.025em;
    font-weight: 700;
    line-height: 1.05;
    font-size: 2.6em;
    margin-bottom: 0.2em;
  }
  h2 {
    color: #ffffff;
    letter-spacing: -0.015em;
    font-weight: 600;
    font-size: 1.7em;
    margin-bottom: 0.4em;
  }
  h2::before {
    content: "";
    display: block;
    width: 48px;
    height: 3px;
    background: #f5c971;
    margin-bottom: 0.4em;
    border-radius: 2px;
  }
  h4 {
    color: #8a8d96;
    font-weight: 400;
    letter-spacing: 0.01em;
    font-size: 1.1em;
    margin-top: 0;
  }
  strong { color: #f5c971; font-weight: 600; }
  em { color: #7eb6f5; font-style: normal; font-weight: 500; }
  blockquote {
    border-left: 3px solid #f5c971;
    color: #d4d6dc;
    font-style: normal;
    padding-left: 1em;
    margin-left: 0;
    font-size: 1.15em;
  }
  a {
    color: #7eb6f5;
    text-decoration: none;
    border-bottom: 1px solid rgba(126,182,245,0.35);
  }
  code {
    background: #161c28;
    color: #f5c971;
    border-radius: 4px;
    padding: 0.1em 0.4em;
    font-family: 'JetBrains Mono', 'Menlo', monospace;
    font-size: 0.9em;
  }
  ul { list-style: none; padding-left: 0; }
  ul li {
    padding: 0.35em 0 0.35em 1em;
    border-left: 2px solid #2a3445;
    margin-bottom: 0.25em;
    color: #d4d6dc;
  }
  .huge { font-size: 2.6em; line-height: 1.05; font-weight: 700; letter-spacing: -0.025em; }
  .big  { font-size: 1.7em; line-height: 1.2;  font-weight: 600; letter-spacing: -0.01em; }
  .muted { color: #8a8d96; }
  .footer-link { color: #7eb6f5; font-size: 0.9em; font-family: 'JetBrains Mono', monospace; }
  section::after {
    color: #3a4252;
    font-size: 0.7em;
    right: 40px;
    bottom: 30px;
  }
  .pill {
    display: inline-block;
    padding: 0.15em 0.6em;
    margin: 0 0.15em;
    background: #161c28;
    border: 1px solid #2a3445;
    border-radius: 999px;
    color: #d4d6dc;
    font-size: 0.85em;
    font-family: 'JetBrains Mono', monospace;
  }
---

<!-- _class: lead -->

# Harness Engineering

#### Raising the floor on what agents ship

<!--
Audience: devs + managers. Slides are a backbone — the demo carries it.
-->

---

<!-- _class: hero -->

<div class="huge">

LLMs are **excellent** at code design.

By default, they ship _crap_.

</div>

<!--
Land this. Pause. Don't soften it.
-->

---

## The wrong question

> What does it do?

## The right question

> What can we _make_ it do?

<!--
For managers: "we tried the model and it was bad" is the wrong evaluation.
For devs: prompt-craft alone is a dead end.
-->

---

## The harness

Everything that shapes the agent.

- `AGENTS.md` / `CLAUDE.md`
- Skills
- Referenced docs — principles, ADRs
- Workflow & process
- Scripts and quality gates
- Hooks and sub-agents
- The shape of the repo itself

---

## The kata

Same feature. Many runs.
**Throw the code away. Keep the harness.**

<br>

Today: <span class="pill">1</span> <span class="pill">3</span> <span class="pill">4+5</span> <span class="pill">6</span> <span class="pill">7</span>

<!--
1 no harness · 3 minimal instructions · 4+5 extract & reuse principles
6 reviewer sub-agent · 7 mechanical gate
-->

---

<!-- _class: hero -->

<div class="big">

Anything we can **verify**, we can **delegate**.

<br>

The engineering is _articulating our intuition_
until it becomes verifiable.

</div>

<!--
Load-bearing slide. Devs: linters/tests/gates = intuition made mechanical.
Managers: this is where leverage compounds.
-->

---

## Where review goes

Every recurring correction is a **harness bug**.

<br>

Human review's highest-leverage output is _a harness change_.

---

## Recursive

The agent can help build **its own harness**.

<br>

<span class="pill">Skills</span> <span class="pill">Principles</span> <span class="pill">Scripts</span> <span class="pill">Gates</span>
<span class="pill">Agent reviews</span> <span class="pill">CI</span> <span class="pill">Any feedback mechanism</span>

---

<!-- _class: lead -->

<div class="huge">

Raise the floor.

Then **raise it again.**

</div>

<br>

#### <span class="footer-link">github.com/martinsson/harness-engineering-kata</span>

#### <span class="muted">Questions · Pushback · Demo</span>
