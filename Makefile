.PHONY: help plugin-skills bd-close diagnose
.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-16s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

plugin-skills: ## Sync plugin skills, bump version, commit, and push
	node scripts/generate-plugin-skills.js --bump
	git add plugins/kf/
	git diff --cached --quiet || git commit -m "chore: sync plugin skills and bump version\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
	git push

bd-close: ## Close a beads issue and its linked GitHub issue. Usage: make bd-close id=claude-config-xxx [reason="..."]
	./scripts/bd-close.sh $(id) $(if $(reason),--reason="$(reason)")

diagnose: ## Run browser diagnostic: make diagnose url=http://localhost:3000
	cd scripts/debug && node diagnose-url.js $(url) $(if $(har),--har,)
