# End (scion)

The reply arrived as your wake message. Integrate its corrections (and the grade's) into your working understanding of the project.

Wrap up:
- Same-folder: release the scion identity (`flbus claim --off` — also drops the listen flag) and tear down the scion mailbox (`flbus mailbox rm scion`) — you are the project's session now. Cross-project: `flbus listen --off` instead.
- In your final message: report the handoff result, and list any answered open question or caveat with value beyond this session (a non-obvious gotcha, a decision that explains existing code) as persistence candidates — where to persist them is the user's call, not the session's.
