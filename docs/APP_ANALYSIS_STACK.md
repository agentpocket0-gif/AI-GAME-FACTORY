# Integrating replica-skill, REA and DSH

## replica-skill

Upstream: https://github.com/Jakeschincariol/replica-skill (MIT). It contains 11 Claude-oriented stages: recon, architect, design, build, backend, test, diff, entrepreneur, brand, launch and deploy. The recon stage maps screens, flows, components, inferred data and feature gaps from public pages and the user's own app session.

It is not automatically installed as a native DSH skill. Its clean-room recon method is adapted in agents/REPLICA_RECON_METHOD.md so DSH agents can follow the same process.

The upstream skill says to rebuild what the app does, not what it owns: no copying code, logo, copy or content; use public sources and the user's own account; do not bypass a login/paywall or scrape private data.

## REA

Upstream: https://github.com/morluto/rea (MIT). Package metadata inspected for this setup reports rea-agents 6.8.0.

REA is a CLI and MCP server that returns evidence for app and binary inspection. Its Android tools can inspect APK package identity, manifest declarations, classes and selected methods. Static APK analysis does not reveal all runtime behaviour, current shop prices or server-side logic.

## DSH connection

DSH supports external MCP servers through @deepseek-ai/dsh-mcp-client. The official client documentation shows stdio connections and tool names under mcp__serverName__tool. A REA server can therefore expose its tools to DSH.

Example profile entry; verify it against the DSH version/profile you actually run before enabling:

    - id: mcp-rea
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: rea
        transport: stdio
        command: npx
        args: ['-y', 'rea-agents@6.8.0', 'mcp']
        env:
          REA_JADX_MCP_JAR: /absolute/path/to/jadx-headless-mcp-0.7.1-all.jar

## Android APK prerequisites

REA's current Android analysis guide lists:
- Node.js 22.23.4+ (22 line), 24.22.1+ (24 line), or 26.12.1+.
- Full JDK 17 or newer.
- Pinned jadx-headless-mcp 0.7.1 JAR.
- JAR SHA-256: 6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75.
- On Linux, a procps-compatible ps executable on PATH.

REA documents commands such as:
- rea inspect-android-package /path/to/authorized-app.apk
- rea search-android-classes /path/to/authorized-app.apk SearchTerm
- rea inspect-android-class /path/to/authorized-app.apk package.ClassName
- rea inspect-android-method /path/to/authorized-app.apk package.ClassName methodName

Use the current REA Android guide for exact setup and argument schema. This repository does not vendor the JADX binary.

## APK policy for this public repository

There is no third-party APK downloader in this project. Install the app from its official Google Play listing: https://play.google.com/store/apps/details?gl=IN&id=com.miniclip.carrom. If an APK is supplied, use only a file you are authorised to inspect. Do not bypass a store, account, purchase or access control. Never commit the commercial APK, private app data, player data, decompiled code or extracted proprietary assets to this public repository.

## Evidence workflow

1. Read public store/help pages and record source URLs.
2. Record the user's own app walkthrough with screen IDs and states.
3. Create a flow map and feature matrix, tagging each claim high/medium/low confidence.
4. If an authorised APK is available, inspect its signature and package metadata first, then use selected REA evidence.
5. Separate verified facts, inferences and unknowns.
6. Build an independent implementation and compare user-visible outcomes, not source code or protected assets.

REA does not automatically produce a complete app specification. It is one evidence source that a DSH agent must interpret.
