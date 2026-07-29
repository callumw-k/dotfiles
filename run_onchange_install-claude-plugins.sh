#!/bin/sh
set -e

claude plugin marketplace add dietrichgebert/ponytail
claude plugin marketplace add obra/superpowers-marketplace
claude plugin marketplace add anthropics/claude-plugins-official

claude plugin install ponytail@ponytail
claude plugin install superpowers@superpowers-marketplace
claude plugin install swift-lsp@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
