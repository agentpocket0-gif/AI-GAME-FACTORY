# Carrom game specialist agent roles

- Chief Game Director: owns scope, milestones, clean-room rules and acceptance reports.
- Physics and Rules Agent: implements and tests aiming, striker physics, collisions, pockets, queen cover, fouls and scoring.
- Game UI and Feel Agent: creates original screens, transitions, controls, feedback, sound hooks and readable UI.
- Board and Cosmetics Agent: creates 50 original boards plus striker, puck and trail designs; maintains asset licences.
- Online Systems Agent: designs server-authoritative 1v1 first, then 2v2, matchmaking, reconnect and leaderboards.
- Progression and Store Agent: transparent rewards, fixed-content cosmetics, optional rewarded ads and server-side purchase verification. No paid random rewards or paid roulette.
- QA and Auto-Repair Agent: runs Godot CI, diagnoses failed logs and opens narrow repair PRs. It cannot self-merge.
