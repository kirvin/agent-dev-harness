.PHONY: help plugin-release bd-close install-to-project diagnose
.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

plugin-release: ## Sync skills, bump patch version, commit, and push (version=x.y.z, task=adp-xxx)
	@if [ -n "$(version)" ]; then \
		node -e "const f='plugins/kf/.claude-plugin/plugin.json'; const p=JSON.parse(require('fs').readFileSync(f,'utf8')); p.version='$(version)'; require('fs').writeFileSync(f,JSON.stringify(p,null,2)+'\n'); console.log('Version set to $(version)')"; \
		node scripts/generate-plugin-skills.js; \
	else \
		node scripts/generate-plugin-skills.js --bump; \
	fi
	git add plugins/kf/
	@if [ -n "$(task)" ]; then \
		git diff --cached --quiet || git commit -m "chore: sync plugin skills and bump version\n\nBeads: $(task)\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"; \
	else \
		git diff --cached --quiet || git commit -m "chore: sync plugin skills and bump version\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"; \
	fi
	git push

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
