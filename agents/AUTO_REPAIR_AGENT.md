# Self-healing CI repair agent

The auto-repair workflow listens for a failed Godot CI run from this repository. It downloads failed logs, asks NVIDIA Nemotron for a narrow patch, validates the patch scope and git diff, applies it, and opens a pull request.

Safety gates:
- Model output is a proposed patch, never executable instructions.
- The agent cannot execute shell commands returned by the model.
- It can edit only GDScript, scene and project files under game/.
- It cannot modify workflows, credentials, Android signing settings or repository permissions.
- It does not push fixes to main or auto-merge.
- Every repair is a pull request and must pass CI and human review.
- It skips its own repair PR branches to avoid loops.
- If the NVIDIA secret is absent or the provider rate-limits the request, source code remains unchanged.

Required Actions secret: NVIDIA_API_KEY

The workflow is serialized and makes one model call per failed CI run. This is automated diagnosis and a proposed repair, not a guarantee. Device-only failures, backend issues and missing Android export tools still need focused tests.
