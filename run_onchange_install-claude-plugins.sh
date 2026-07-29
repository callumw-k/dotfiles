#!/bin/sh
set -e

claude plugin marketplace add dietrichgebert/ponytail
claude plugin marketplace add obra/superpowers-marketplace

claude plugin install ponytail@ponytail
claude plugin install superpowers@superpowers-marketplace
claude plugin install swift-lsp@claude-plugins-official
