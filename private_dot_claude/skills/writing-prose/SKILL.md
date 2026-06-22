---
name: writing-prose
description: Use when writing or editing any prose for the user — reports, docs, specs, plans, job descriptions, commit bodies, PR descriptions, messages, emails, or comments. Covers plain style, avoiding AI/marketing tics, first-person voice for judgements, and British/Australian punctuation.
---

# Writing prose

Write plainly. State what something is and move on. The user reacts strongly against writing that reads like AI or a marketer's landing page, so the failure mode is over-writing, not under-writing.

## Prose texture

- **Short sentences. Break the layered ones.** If a sentence carries a point, a counter-point and an aside, it is three sentences. Don't cram.
- **Cut signposting and runway.** Don't open by announcing the section ("Our assessment keeps returning to", "This is the crux", "With X defined"). State the point. Filler like "obviously" or "this is where it gets interesting" says nothing — delete it.
- **Plain words over metaphor.** "scale" not "spectrum", "infrastructure" not "substrate", "friction" not "the tension at its centre". Avoid "centre of gravity", "load-bearing", "waving away" and the like.
- **Say why once.** Make the justification once, briefly. Don't re-argue the same point across sentences or sections.
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
- **Address the reader as "you".** Name them or their product directly. Don't refer to them in the third person.

## Punctuation and spelling

- British / Australian spelling ("behaviour", "neutralise", "minimise", "initialisation").
- Em dashes are allowed where they genuinely make sense, but sparingly — not as a default aside-maker. Lean to full stops, commas, colons and parentheses, and break the sentence instead where you can. Don't bulk-purge or bulk-add them.
- No semicolons. Use a full stop or a comma.
- Contractions are fine ("it's", "you're", "I'd").
- Plain punctuation generally — avoid emoji unless asked.

## Before / after

Default (over-written, third-person, signposted, climactic close):

> Our assessment keeps returning to one root cause: the data model. [...] Re-expressing those rules, and migrating existing records without breaking live usage, is the largest and riskiest piece of work. It is where we expect most of the cost and most of the timeline pressure to concentrate.

Rewritten (first-person call, plain, no runway):

> The data model is the main constraint. The schema assumes a single module and a single tenant, and most rebuild decisions wait on unwinding that. My read: within that, the access-control model is what moves the effort number. Re-expressing the three-axis rules and migrating live records into them is the largest, riskiest piece. I'd expect the cost and the schedule pressure to land there.
