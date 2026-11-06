# Unknowns and next evidence needed

| Unknown | Why it matters | Best evidence |
|---|---|---|
| Loading and first-run flow | First impression and tutorial timing | User-controlled recording from app launch |
| Home and campaign map | Progression and navigation architecture | Screenshots/video from user's own installed app |
| Exact board geometry | Determines shot collision and placement | Several controlled shots including wall bounces |
| Queue/swap behavior | Changes player strategy and HUD | Gameplay observation |
| Rescue-objective rules | Critical to the core goal | Complete level walkthrough |
| Prop names and effects | Inventory, economy and balance | Open each visible prop in user's own session |
| Win/loss and star thresholds | Required for level tuning | Compare multiple finished levels and result screens |
| Ads and rewarded ads | Monetization design and compliance | Observe ordinary public gameplay and record trigger/return flow |
| IAP/shop | Not evidenced by reviewed listing | Inspect visible in-app shop if present; do not assume prices |
| Save/resume | Offline quality | Background/reopen test on user's own device |
| Package identity and permissions | Static app facts | REA package inspection of an authorized APK |
| Signer and version | Integrity and build metadata | REA signature inspection or official package facts |
| SDK/library inventory | Potential ads/analytics evidence, not proof of runtime behavior | REA static inventory on supplied authorized APK |
| Runtime ad/server behavior | Static inspection cannot prove it | User-controlled observation; never copy private APIs |
| Performance and loading time | Optimization for Android | Measure on the actual target device |

## Current REA status

REA instructions are available as source, but the REA MCP server is not connected here and no authorized target APK was supplied. No REA analysis report has been generated.

When an authorized APK is available, begin with package identity, signature and manifest declarations. Keep reports private if they contain proprietary metadata. Never commit the commercial APK, player data or decompiled proprietary resources to this public repository.
