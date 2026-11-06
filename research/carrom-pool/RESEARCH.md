# Carrom Pool: public product research

**App:** Carrom Pool: Disc Game  
**Package:** com.miniclip.carrom  
**Publisher:** Miniclip  
**Research date:** 2026-11-06  
**Method:** Public Google Play listing and official Miniclip Help/product pages. No APK, private account, private API or network traffic was used.

## Summary

The India Google Play listing marks the game as containing ads and in-app purchases, reports 500M+ downloads and shows a 4.6-star snapshot. It describes multiplayer, offline play, same-device play, unlockable equipment, events and rewards. Store text can vary by country, language and rollout.

## Gameplay and modes

| Feature | Evidence |
|---|---|
| Carrom, Disc Pool and Free Style | Listed in the current Play Store / Miniclip help materials |
| 2v2 | Play listing describes a four-player 2v2 mode |
| Friends | Official help explains friend search by player name or Unique ID |
| Matchmaking | Play listing says opponents are matched by similar skill |
| Same-device play | Mentioned in the store listing |
| Offline play | Explicitly advertised on Google Play |
| Leaderboards | Official guide lists league, friends, country and world boards |
| Clubs | Miniclip has a Clubs Guide; creating a club is stated to cost gems |
| Voice/video chat | Play listing says this is for Carrom Pass owners |

A current India/other-language listing may not show every feature at the same time. In-game rollout and region can differ.

## Gameplay rules

Miniclip's Rules and Fouls article confirms these examples:
- Potting the striker is a foul.
- Potting the opponent's last puck while the queen remains is a foul.
- Potting your own last puck while the queen remains is a foul.
- A foul ends the turn and causes the penalty puck and affected own pucks to return, subject to the article's exception.

The beginner guide describes Free Style as a 120-point race: queen 50 points, white pucks 20 and black pucks 10. Our game must document its own rules in original language and test every edge case.

## Strikers, powers and cosmetics

Official Miniclip help confirms:
- Strikers have Force, Aim and Time stats.
- Force affects shot strength/speed.
- Aim affects aim-line length.
- Time is the maximum time available to make a shot.
- Powers add stats to a striker and have their own visual appearance.
- Pucks and Trails are cosmetic and do not affect gameplay.
- Duplicate striker cards are used for upgrades; powers unlock as equipment progress fills a collection power bar.

The public help pages do not publish the complete current list or exact total counts of individual strikers and powers. Do not invent those counts.

## Publicly named arenas

The official Miniclip product/reward page names these 12 arena/table themes: Paris Stage, Delhi Lounge, London Park, Tokyo Palace, Istanbul Bazaar, Dubai Skybar, Barcelona Paradise, Mumbai Arena, Cairo Gallery, Sao Paulo Theatre, New York Square and Singapore Plaza.

This is not proof that the live app has exactly 12 boards. There may be other event, seasonal or regional themes. Our own game targets 50 original board skins; see BOARD_PLAN_50.md.

## Economy, IAP and progression

Public materials mention coins, gems, free daily rewards, match victory chests, Bronze/Silver/Gold chests, Pro/Master/Supreme chests, shop offers, bundles, equipment upgrades, events and Carrom Pass. The help guide says users may watch ads for additional coins, gems and chests, and may use gems or ads to speed up eligible chest opening. Google Play labels the app as containing optional in-app purchases and notes that some items are random.

Exact INR price points, SKU names and current offer rotations are not published in these support pages. They must be recorded from the user's own live app and store region; do not guess.

**Our monetisation decision:** use direct-price, fixed-content cosmetics and optional rewarded ads. Do not copy paid roulette or paid random-reward purchases. Make every purchase price and content clear, and use a parent/guardian-approved purchase flow.

## Advertising

Confirmed: rewarded video ads can provide extra rewards. Miniclip says ads may be unavailable because of region inventory, unstable connectivity, recently watched ads or a third-party ad service issue.

Not confirmed by the reviewed public sources: banner ads, forced interstitial ads, exact ad frequency and all placements. Do not claim these exist until they are observed in the live app.

For our game, use optional rewarded video ads only. Grant the reward after the ad network confirms completion. If ads are unavailable, the player must still be able to play.

## Online and offline

Online features publicly described: skill-based matchmaking, friend matches, leaderboards, clubs, live events and Carrom Pass social features.

Offline support is explicitly listed, and same-device play is described. The public pages do not fully establish whether offline mode includes bots, which modes remain available, how progress syncs after reconnecting, or how rewards earned offline are handled. Those need a controlled test with the user's own installation.

## Screen inventory still to capture

S01 splash/loading; S02 home/lobby; S03 mode select; S04 matchmaking; S05 match board; S06 results; S07 equipment; S08 shop; S09 rewards/chests; S10 events/pass; S11 friends/clubs; S12 profile/leaderboards; S13 settings/support; S14 offline/reconnect states.

For each screen record loading, normal, empty, error, offline and permission states. Record the steps to reach it and the exact visible labels.

## Evidence sources

1. Google Play India listing: https://play.google.com/store/apps/details?gl=IN&id=com.miniclip.carrom
2. Miniclip beginner guide: https://support.miniclip.com/hc/en-us/articles/4404675218577-How-to-Start-Playing-Carrom-Pool-A-Beginner-s-Guide
3. Equipment guide: https://support.miniclip.com/hc/en-us/articles/360011901674-Strikers-Powers-Pucks-and-Trails-Carrom
4. Rules and fouls: https://support.miniclip.com/hc/en-us/articles/360012006033-Rules-and-Fouls-Carrom
5. Friends guide: https://support.miniclip.com/hc/en-us/articles/360035381973-How-to-add-remove-friends-from-your-game-Carrom
6. Ads unavailable guide: https://support.miniclip.com/hc/en-us/articles/50420599006609-Why-Are-Rewarded-Ads-Unavailable
7. Clubs guide: https://support.miniclip.com/hc/en-us/articles/39582927439121-Carrom-s-Clubs-Guide
8. Official reward/product page: https://www.miniclip.com/minigames/carrompool

## Unknowns

Exact live counts for boards, strikers, powers, pucks and trails; current INR prices and SKU identifiers; all ad placements; all screen states; offline bot/local mode details; offline reward synchronisation; server vendor and private matchmaking protocol. No APK was provided, so no APK-specific facts are asserted.
