# Changelog

## [1.5.0](https://github.com/kirvin/agent-dev-harness/compare/v1.4.4...v1.5.0) (2026-04-28)


### Features

* add 5 security rules (secret-hygiene, security-review, threat-modeling, dependency-audit, security-sweep) ([71a1d90](https://github.com/kirvin/agent-dev-harness/commit/71a1d906333f7082a4374a62cec561e7b6f310df))
* add bd-close.sh, GitHub Actions CI, gitleaks config, CLAUDE.md security section ([b41d34b](https://github.com/kirvin/agent-dev-harness/commit/b41d34bc7476b7ac2ed376b1615fc380bb9504f8))
* add generate-plugin-skills script; sync skills to plugin (v1.2.1) ([adffce4](https://github.com/kirvin/agent-dev-harness/commit/adffce48ffb8c5cf1c347fad358af5ab4fb2bbe8))
* add kf:repo-knowledge-audit and kf:repo-knowledge-architect skills ([9dbfc43](https://github.com/kirvin/agent-dev-harness/commit/9dbfc43a06c096cc19515a1abfa035f628a1ee83))
* add optional Figma credential setup to setup.sh and install-to-project.sh ([3fe7ed1](https://github.com/kirvin/agent-dev-harness/commit/3fe7ed17a802a7f45dc13ce76b2c5f0377c3e2ef))
* add release-please automation for kf plugin versioning ([feb7150](https://github.com/kirvin/agent-dev-harness/commit/feb7150eba38c458d47e7ed0c0bbaad447dd3c07))
* add session lifecycle skills and timestamp hook docs (v1.3.0) ([420fa0a](https://github.com/kirvin/agent-dev-harness/commit/420fa0a4a0f256b46d1175edb03dfc8069ed1623))
* add spec-first methodology as skill + rule ([48bd2e6](https://github.com/kirvin/agent-dev-harness/commit/48bd2e6ff60c7feea94a9c3f14759ed60d20ca6a))
* add toolkit-feedback, maintainer-intake rules and Figma trigger in design-skills ([fa5c56a](https://github.com/kirvin/agent-dev-harness/commit/fa5c56a90acf7752671f3b3e423c30a556c87301))
* add UI/UX design skill wrappers to kf plugin (v1.1.0) ([329bed4](https://github.com/kirvin/agent-dev-harness/commit/329bed4babbb31c55b050aadb172f2f4117e3611))
* add version= param to make plugin-release ([e624f61](https://github.com/kirvin/agent-dev-harness/commit/e624f6199e092b941cdfa774b921dd3bfef31f1d))
* convert spec-first to proper kf marketplace plugin ([ae21afa](https://github.com/kirvin/agent-dev-harness/commit/ae21afa1cf7b65896db23dd6aa1658ea640ca505))
* initial Claude Code configuration template ([2a8a818](https://github.com/kirvin/agent-dev-harness/commit/2a8a818b854a80857eca93e05f7a71f9e632d247))
* port three tooling improvements from historical-maps-v2 ([7319fa1](https://github.com/kirvin/agent-dev-harness/commit/7319fa13c9d4e37b2063dc36c6420c0e86b6c812))
* release kf plugin v1.4.0 ([858bb28](https://github.com/kirvin/agent-dev-harness/commit/858bb28c3e9d4b38168c2927462d9b7ee0e95a1c))
* **spec-first:** add open question lifecycle rule ([08bc96b](https://github.com/kirvin/agent-dev-harness/commit/08bc96b0b8c3b2f1064fea6f5ff49d0a6e42e5af))


### Bug Fixes

* copy skills/ in new-project.sh and patch issue_prefix in Dolt ([bad6bbd](https://github.com/kirvin/agent-dev-harness/commit/bad6bbd0db813df6d6ce131d9af438c015dcfa42))
* marketplace.json owner field and schema reference ([543ab6d](https://github.com/kirvin/agent-dev-harness/commit/543ab6d832d932e7fed74b8b54b764901c594561))
* remove stale Dolt git remote in new-project.sh ([c732f59](https://github.com/kirvin/agent-dev-harness/commit/c732f59da919426fc0ae935237659b4b7aeae2e5))
