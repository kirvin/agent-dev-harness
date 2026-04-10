.PHONY: plugin-skills bd-close

# Sync .agents/skills/ → plugins/kf/skills/, bump patch version, commit, and push.
plugin-skills:
	node scripts/generate-plugin-skills.js --bump
	git add plugins/kf/
	git diff --cached --quiet || git commit -m "chore: sync plugin skills and bump version\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
	git push

# Close a beads issue and its linked GitHub issue (if any).
# Usage: make bd-close id=claude-config-xxx [reason="..."]
bd-close:
	./scripts/bd-close.sh $(id) $(if $(reason),--reason="$(reason)")
