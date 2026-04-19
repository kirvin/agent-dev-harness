.PHONY: help plugin-release bd-close install-to-project

# Default target: show help
help:
	@echo "Available targets:"
	@echo ""
	@echo "  make help                      Show this help message (default)"
	@echo "  make install-to-project        Install toolkit into another project"
	@echo "                                 Usage: make install-to-project target=/path/to/project [options]"
	@echo "                                 Options: --force, --dry-run"
	@echo "  make plugin-release            Sync skills, bump patch version, commit, and push"
	@echo "                                 Optional: version=1.4.0 for minor/major bumps"
	@echo "                                 Optional: task=adp-xxx to link a beads issue"
	@echo "  make bd-close                  Close beads issue and linked GitHub issue"
	@echo "                                 Usage: make bd-close id=adp-xxx [reason=\"...\"]"
	@echo ""

# Sync .agents/skills/ → plugins/kf/skills/, bump version, commit, and push.
# Patch bump by default. For minor/major: make plugin-release version=1.4.0
# Optionally link a beads task:         make plugin-release task=adp-xxx
plugin-release:
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

# Close a beads issue and its linked GitHub issue (if any).
# Usage: make bd-close id=adp-xxx [reason="..."]
bd-close:
	./scripts/bd-close.sh $(id) $(if $(reason),--reason="$(reason)")

# Install toolkit into another project.
# Usage: make install-to-project target=/path/to/project [options]
# Options: --force (overwrite existing files), --dry-run (preview only)
install-to-project:
	@if [ -z "$(target)" ]; then \
		echo "Error: target path required. Usage: make install-to-project target=/path/to/project"; \
		exit 1; \
	fi
	./scripts/install-to-project.sh $(target) $(if $(force),--force) $(if $(dry-run),--dry-run)
