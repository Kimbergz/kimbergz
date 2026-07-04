# CLAUDE.md

This file is the standing brief for this repository. Read it first, every session,
before doing anything. It tells you what this project is, how it is organised, and the
exact conventions to follow so the human never has to re-explain the setup.

## What this is

A **static, no-build website** that publishes **student-made study notes** for a school,
hosted free on **GitHub Pages**. Notes are written by a student (sometimes drafted by AI
from class recording transcripts, sometimes written by hand) and published for other
students to read. The site is **public and read-only** — there is no login and no backend.

There is **no build step to run by hand, no framework, no package manager for the site
itself**. Everything is plain HTML/CSS/vanilla JavaScript loaded directly by the browser.
The only automation is a GitHub Action that regenerates a content index on every push.

The human maintaining this repo is **non-technical**. When you help them, explain in plain
language, tell them exactly what to click or paste, and never assume developer knowledge.

## The golden rule (most important thing in this file)

**To add or update content, the human drops a Markdown (or JSON) file into the correct
folder under `content/`. Nothing else.** They should never have to edit `app.js`,
`index.html`, `styles.css`, or any index by hand. A GitHub Action rebuilds `manifest.json`
from the folders on every push, and the site reads that at runtime. If a task would force
the human to hand-edit code just to publish a note, you have done it wrong — fix the
system so a plain file drop is enough.

## Folder map

```
content/
  lectures/<subject>/<YYYY-MM-DD>-<topic-slug>.md   ← lecture notes (edited daily)
  quizzes/<subject>/<topic-slug>.json               ← interactive quizzes (optional)
  exam-papers/<subject>/<name>.md                    ← printable exam papers + answer keys
templates/
  LECTURE-TEMPLATE.md        ← copy this to start a new lecture note
  QUIZ-TEMPLATE.json         ← copy this to start a new quiz
  EXAM-PAPER-TEMPLATE.md     ← copy this to start a new exam paper
manifest.json                ← AUTO-GENERATED. Do not hand-edit. The Action rewrites it.
config.js                    ← site name, subject order, disclaimer text (safe to edit)
index.html, app.js, styles.css, version.js   ← the site engine (rarely changes)
scripts/build-manifest.mjs   ← Node script the Action runs to scan content/ folders
.github/workflows/deploy.yml ← builds manifest + publishes to GitHub Pages on push
```

Subjects are **just folder names** under `content/lectures/`. Creating a new subject =
creating a new folder. Topic order within a subject is by the date in the filename
(newest first by default; `config.js` can flip this).

## File formats (follow these exactly)

### Lecture note — `content/lectures/<subject>/<YYYY-MM-DD>-<topic>.md`

Starts with a YAML frontmatter block, then Markdown notes:

```markdown
---
subject: Biology
topic: Photosynthesis
date: 2026-07-04
summary: How plants turn light into energy.   # one line, shown in lists + search
quiz: photosynthesis        # optional: filename (no .json) in quizzes/<subject>/
---

# Photosynthesis

Your notes in normal Markdown — headings, **bold**, lists, tables, code, images.
```

- Filename: date first (so files sort chronologically), then a short kebab-case topic.
- `subject` in frontmatter must match the folder name (case-insensitive).

### Quiz — `content/quizzes/<subject>/<topic>.json`

```json
{
  "title": "Photosynthesis quiz",
  "questions": [
    {
      "q": "Which gas do plants take in for photosynthesis?",
      "options": ["Oxygen", "Carbon dioxide", "Nitrogen", "Hydrogen"],
      "answer": 1,
      "explain": "Plants absorb CO2 and release O2."
    }
  ]
}
```

- `answer` is the **0-based index** of the correct option.
- `explain` is optional feedback shown after answering.
- A quiz appears on a lecture page when that lecture's frontmatter `quiz:` points to it,
  and also stands alone under the subject's Quizzes section.

### Exam paper — `content/exam-papers/<subject>/<name>.md`

Plain Markdown, print-friendly. Put the answer key at the bottom inside a
`## Answer Key` heading (the site renders it collapsed / on a separate print page).

## How publishing works (explain this to the human when relevant)

1. Human drops/edits a file under `content/` and pushes to the `main` branch (via the
   GitHub website's "Add file -> Upload files", or `git push`).
2. `.github/workflows/deploy.yml` runs: it executes `scripts/build-manifest.mjs`, which
   scans the `content/` folders and writes a fresh `manifest.json` (list of subjects,
   lectures, quizzes, papers with their metadata), then deploys the whole repo to
   GitHub Pages.
3. Within a minute or two the live site shows the new content. No code edits, ever.

`manifest.json` is a generated artifact — **never hand-edit it and never ask the human to.**

## Running it locally

No build. Serve the repo root over HTTP so `fetch()` of Markdown/JSON works:

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

If you changed a `content/` file locally and want the local site to see it, regenerate the
index once: `node scripts/build-manifest.mjs`. On GitHub the Action does this automatically.

## The disclaimer (never remove or weaken)

Every page must show a clear notice — a homepage banner **and** a footer on every page —
stating that this is **student-made, unofficial study material, not produced or endorsed
by the school or its teachers, and may contain mistakes; verify against official
materials.** The text lives in `config.js` (`disclaimer`). Keep it visible and plain.

## Site engine conventions (when you DO touch the code)

- **Routing** is hash-based (`#/`, `#/subject/biology`, `#/lecture/biology/2026-07-04-photosynthesis`, `#/exam-papers`). Re-render on `hashchange`.
- **Rendering** is full `innerHTML` replacement from the manifest + fetched files. Keep it
  simple; no framework, no virtual DOM.
- **Markdown -> HTML**: use the pinned CDN copy of `marked` already loaded in `index.html`,
  and **always sanitize** rendered HTML with the pinned `DOMPurify` before inserting it.
  Never inject un-sanitized note/quiz text — treat all content files as untrusted input.
- **Search** is client-side over the manifest (subject, topic, summary) — keep it working
  when you add content types.
- **Cache-busting**: `version.js` sets `window.ASSET_V`. Asset URLs carry `?v=<ASSET_V>`.
  **When you change `app.js`, `styles.css`, or `config.js`, bump the number in
  `version.js` by one.** That is the only file to touch for cache-busting.
- **Design system**: glassmorphism — frosted translucent cards, soft shadows, a blurred
  backdrop, rounded corners. Colors/spacing are CSS custom properties in `styles.css`
  (`var(--color-*)`, `var(--space-*)`); reuse tokens instead of hard-coding. Mobile-first,
  because most students read on phones.

## Two content workflows the human uses

1. **From a Plaud transcript (AI-drafted):** the human pastes a class transcript. Turn it
   into a lecture note in the exact frontmatter+Markdown format above (clear headings,
   concise study-note style — not a raw transcript), plus an optional matching quiz JSON.
   Hand back ready-to-drop file(s) with the correct filename and folder. Do not invent
   facts not supported by the transcript; flag anything uncertain for the human to check.
2. **Hand-written:** the human writes rough notes; format/clean them into the same file
   shape and tell them exactly where to save it.

In both cases your output is **files that match the formats above**, placed (or named) for
the right folder, so publishing stays a simple drop-in.

## Guardrails

- Public repo: **never** add secrets, API keys, private student data, or anything not meant
  to be world-readable. There is no auth — assume everything here is public forever.
- Keep the site dependency-light and no-build. Don't introduce a framework, bundler, or
  server without the human explicitly asking.
- Preserve the folder-drop workflow and the disclaimer above all else.
