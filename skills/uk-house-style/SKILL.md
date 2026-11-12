---
name: uk-house-style
description: Method7 house style for copy that people will read and that gets published or sent - journal entries, website pages, guides, blog posts, emails, case studies, social posts, and README or pull-request text a client may see. Use when drafting, editing or reviewing that kind of prose. Its spelling and voice rules are not for code, identifiers or config, but the em-dash ban applies everywhere, code comments and commit messages included.
---

# UK house style

Copy is written for business owners, not engineers. It should read like a
knowledgeable person talking plainly, in British English.

## Spelling and grammar: UK, not US

- `-ise`, not `-ize`: organise, optimise, recognise, prioritise.
- `-our`: colour, behaviour, favour. `-re`: centre, metre.
- `licence` is the noun and `license` the verb. Same for `practice` and `practise`.
- Use `programme`, except for computer programs.
- Single quotes go inside double quotes: "she called it 'the plan'".
- Full stops and commas go outside quotation marks unless they belong to the quote.

## Dates and numbers

- Dates in prose: `12 November 2026`. Never `November 12, 2026` or `12/11/2026`.
- Ranges use an unspaced en-dash: `Mon–Fri`, `2025–2026`, `£5–10k`.
- Money always uses the `£` symbol and figures: `£1,200`, `£5–10`. Never
  `GBP 1200` or `5 to 10 pounds`, even when the brief you were given words it
  that way.

## Punctuation: no em-dashes

Never use the em-dash (U+2014). It is the most recognisable mark of
AI-written copy, and Method7 bans it everywhere: copy, code comments and
commit messages. Instead:

- use a spaced en-dash ` – ` for an aside
- otherwise use a comma, colon or full stop, and often the sentence is better recast
- use brackets for a true parenthesis
- use an unspaced en-dash for a range: `2025–2026`

## Plain English

- Explain a technical term the first time it appears, or don't use it.
- Prefer the short word: `use`, not `utilise`; `help`, not `facilitate`.
- Say who does what: "we chose", not "a decision was made".
- One idea per sentence. Cut throat-clearing such as "It's worth noting that".

## Before and after

> Before: In order to optimize our workflow, we utilized a modular approach [em-dash] leveraging agents to facilitate task completion.

(The real character is left out on purpose, so this file passes its own check.)

> After: We split the work into small tasks so an AI agent can take each one on its own. It's quicker, and every step is easy to check.

## Final check

Before handing copy back, check it for the em-dash character. In a git repo:

```bash
git grep -nIP '\x{2014}'
```

That should print nothing. CI runs the same check on every pull request, so
this catches it early rather than at review.
