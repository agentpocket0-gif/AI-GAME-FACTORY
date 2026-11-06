# Clean-room app reconnaissance for DSH agents

Adapted from the workflow and boundaries of https://github.com/Jakeschincariol/replica-skill (MIT).

## Required outputs

For each app, create:
- RESEARCH.md: summary with source URLs.
- SCREENS.csv: one row per screen and visible state.
- FLOWS.md: user goals, happy paths and edge cases.
- FEATURE_MATRIX.csv: must/should/could/skip and evidence status.
- UNKNOWNS.md: unverified details and how to test them.
- ASSET_LICENSES.csv: source, creator, licence and attribution for assets our project may use.

## Recon sequence

1. Define platform and target product scope.
2. Use public help pages, store listings, changelogs and public walkthroughs first.
3. Use only the user's own installed app/account for hands-on observations.
4. Record screens including loading, empty, error, offline and permission states.
5. Map user flows including cancel, retry, back and failure branches.
6. Catalogue components and design patterns without copying exact art.
7. Infer data structures only with evidence; mark guesses explicitly.
8. Record which owned content/services cannot be reused.
9. Estimate complexity and identify the biggest technical risks.
10. Recommend the smallest testable milestone.

## Evidence rules

Every fact must point to a URL, screenshot ID, APK evidence record or direct user observation. Mark facts high, medium or low confidence. Never invent inventory counts, prices, abilities, ad placements, server vendors or protocol details.

## Clean-room restrictions

Do not access accounts the user does not control, bypass logins/paywalls/age gates/access controls, capture private network calls for imitation, copy decompiled code, or ship original app art/audio/screenshots. Keep commercial APKs, player data and secrets out of this public repository.

## Current task

Use research/carrom-pool/RESEARCH.md as the baseline. The full live inventory and all screen states remain incomplete until a controlled walkthrough is available.
