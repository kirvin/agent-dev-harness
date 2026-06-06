.PHONY: help plugin-release bd-close install-to-project update-project diagnose
.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

plugin-release: ## Sync skills into plugins/kf/ and push (version bumps handled by release-please)
	node scripts/generate-plugin-skills.js
	git add plugins/kf/
	git diff --cached --quiet || git commit -m "chore: sync plugin skills\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
	git push

bd-close: ## Close a beads issue and its linked GitHub issue (id=adp-xxx, reason="...")
	./scripts/bd-close.sh $(id) $(if $(reason),--reason="$(reason)")

install-to-project: ## Install toolkit into a project (target=/path; force=1, update=1, or dry-run=1)
	@if [ -z "$(target)" ]; then \
		echo "Error: target path required. Usage: make install-to-project target=/path/to/project"; \
		exit 1; \
	fi
	./scripts/install-to-project.sh $(target) $(if $(force),--force) $(if $(update),--update) $(if $(dry-run),--dry-run)

update-project: ## Refresh harness-managed files in an installed project (target=/path; dry-run=1)
	@if [ -z "$(target)" ]; then \
		echo "Error: target path required. Usage: make update-project target=/path/to/project"; \
		exit 1; \
	fi
	./scripts/install-to-project.sh $(target) --update $(if $(dry-run),--dry-run)

diagnose: ## Run browser diagnostic against a URL (url=http://..., har=1 for HAR capture)
	cd scripts/debug && node diagnose-url.js $(url) $(if $(har),--har,)
