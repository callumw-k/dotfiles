#!/bin/sh
set -e

claude plugin marketplace add dietrichgebert/ponytail

claude plugin install ponytail@ponytail
claude plugin install superpowers@claude-plugins-official
claude plugin install swift-lsp@claude-plugins-official
