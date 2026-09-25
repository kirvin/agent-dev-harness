.PHONY: help plugin-release bd-close install-to-project diagnose test
.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

plugin-release: ## Sync generated skills into plugins/kf/ on a branch and push it; merging the PR releases (see docs/deployment-and-release.md)
	@test "$$(git branch --show-current)" != main || { echo "plugin-release: run this on a branch, not main" >&2; exit 1; }
	node scripts/generate-plugin-skills.js
	git add plugins/kf/
	git diff --cached --quiet || git commit -m "fix(skills): sync generated skills from .agents/skills"
	git push -u origin HEAD

bd-close: ## Close a beads issue and its linked GitHub issue (id=adp-xxx, reason="...")
	./scripts/bd-close.sh $(id) $(if $(reason),--reason="$(reason)")

install-to-project: ## Install toolkit into another project (target=/path, --force, --dry-run)
	@if [ -z "$(target)" ]; then \
		echo "Error: target path required. Usage: make install-to-project target=/path/to/project"; \
		exit 1; \
	fi
	./scripts/install-to-project.sh $(target) $(if $(force),--force) $(if $(dry-run),--dry-run)

diagnose: ## Run browser diagnostic against a URL (url=http://..., har=1 for HAR capture)
	cd scripts/debug && node diagnose-url.js $(url) $(if $(har),--har,)

test: ## Run script tests (needs bd, jq and node)
	@failed=0; for t in tests/*.test.sh; do bash "$$t" || failed=1; done; \
	node --test tests/*.test.js || failed=1; exit $$failed
