---
name: writing-prose
description: Use when writing or editing any prose for the user — reports, docs, specs, plans, job descriptions, commit bodies, PR descriptions, messages, emails, or comments. Covers plain style, avoiding AI/marketing tics, first-person voice for judgements, and British/Australian punctuation.
---

# Writing prose

Write plainly. State what something is and move on. The user reacts strongly against writing that reads like AI or a marketer's landing page, so the failure mode is over-writing, not under-writing.

## Prose texture

- **Short sentences. Break the layered ones.** If a sentence carries a point, a counter-point and an aside, it is three sentences. Don't cram. But don't fragment for its own sake either: when several short clauses are one thought, join them with a comma or colon rather than chopping into staccato full stops.
- **Cut signposting and runway.** Don't open by announcing the section ("Our assessment keeps returning to", "This is the crux", "With X defined"). State the point. Filler like "obviously" or "this is where it gets interesting" says nothing — delete it.
- **Show the stance, don't declare it.** Cut sentences that describe the work instead of doing it: "I've kept this evidence-led and unbiased", "this rests on a measured fact, not a bet". The reasoning and the stated caveats already show neutrality and rigour. Announcing them reads as preachy and adds nothing.
- **Don't hedge the obvious.** Cut qualifiers that restate the premise as if it were a caveat: "this is conditional on X proceeding", when X is exactly what you're recommending, or "the best fit rather than an aspirational one". If a clause only says what the reader already assumes, or tells them what they didn't do, delete it.
- **Plain words over metaphor.** "scale" not "spectrum", "infrastructure" not "substrate", "friction" not "the tension at its centre". Avoid "centre of gravity", "load-bearing", "waving away" and the like.
- **Name the mechanism, not the buzzword.** Say what a thing actually does in plain terms before reaching for an abstract label: "have modules talk through events so one can be split out later" beats "a designed seam via the event backbone", "the option to split later" beats "optionality". Keep a precise technical term where the reader needs it (in-process, CI/CD, network boundary), but drop the grandiose coinages.
- **Say why once.** Make the justification once, briefly. Don't re-argue the same point across sentences or sections.
- **Trust the lead, cut the echo.** After a bolded label ("Current distance: greenfield"), don't follow with a sentence that re-lists what it means — add only what the label doesn't already say. Same for parenthetical glosses and example lists: include them when they change the claim, not as texture.
- **Lead with the callout.** Point first, support after.

## AI/marketing tics to avoid

- No "it's not X, it's Y" antithesis constructions, and no "rather than one problem among many" variants.
- No punchy one-line fragments for effect, no climactic short closing sentence.
- No filler adjectives ("impactful", "without ego", "entire game") and no aphoristic one-liners ("you can't migrate what you can't read").
- No "Grounded in…"-style openers.
- Avoid the bold-lead-then-colon bullet pattern (**Thing did X.** explanation) in prose — it reads as AI. Use plain sentences. (This SKILL's own bullets use it as a scannable reference convention, which is fine; flowing prose should not.)

## Voice

- **First person for judgements.** "My read", "I'd hold", "I did think this was worth testing" — not "we" or "our assessment". Recommendations and calls are yours, stated as yours.
- **Voice for the calls, plain for the evidence.** Where it is a judgement or recommendation, be conversational and first person. Where it is evidence, data, a table or a technical detail, stay measured and plain. A single piece can carry both — lead with or close on the call, keep the working neutral.
- **Flag a personal steer as one.** Where a recommendation goes beyond what the evidence strictly dictates, mark it ("Personally, I'd…", "My priority would be…") so it reads as a call, not a finding.
- **Keep first person plain, not rhetorical.** "I do think this needs earning", not "I'd run this even if the evidence were one-sided". State the call; don't perform it.
- **Address the reader as "you".** Name them or their product directly. Don't refer to them in the third person.

## Punctuation and spelling

- British / Australian spelling ("behaviour", "neutralise", "minimise", "initialisation").
- Em dashes are allowed where they genuinely make sense, but sparingly — not as a default aside-maker. Lean to full stops, commas, colons and parentheses, and break the sentence instead where you can. Don't bulk-purge or bulk-add them. One spot a dash earns its place: setting off a trailing phrase that names or sums up what came just before, especially when the sentence already has commas that would make a comma there read as another list item.
- No semicolons. Use a full stop or a comma.
- **Don't over-comma.** In a short two-clause compound the comma before "and" can go ("the check keeps the boundaries honest and events let a module split out later").
- Contractions are fine ("it's", "you're", "I'd").
- Plain punctuation generally — avoid emoji unless asked.

## Before / after

Default (over-written, third-person, signposted, climactic close):

> Our assessment keeps returning to one root cause: the data model. [...] Re-expressing those rules, and migrating existing records without breaking live usage, is the largest and riskiest piece of work. It is where we expect most of the cost and most of the timeline pressure to concentrate.

Rewritten (first-person call, plain, no runway):

> The data model is the main constraint. The schema assumes a single module and a single tenant, and most rebuild decisions wait on unwinding that. My read: within that, the access-control model is what moves the effort number. Re-expressing the three-axis rules and migrating live records into them is the largest, riskiest piece. I'd expect the cost and the schedule pressure to land there.
