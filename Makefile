#!/usr/bin/env bash
.PHONY: help build

default: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

test:
	find . -type f -name '*.zig' -print0 | xargs -0 -I {} bash -c 'echo "in {} "; zig test {} 2>&1 | cat -'