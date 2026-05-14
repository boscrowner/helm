# Copyright The Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BINARY_NAME    := helm
BIN_DIR        := bin
BUILD_DIR      := _build
GO             := go
GOFLAGS        ?=
LDFLAGS        := -w -s
VERSION        ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT     ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE     ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
IMPORT_PATH    := helm.sh/helm/v3

LD_VERSION_FLAGS := \
	-X $(IMPORT_PATH)/internal/version.version=$(VERSION) \
	-X $(IMPORT_PATH)/internal/version.gitCommit=$(GIT_COMMIT) \
	-X $(IMPORT_PATH)/internal/version.buildDate=$(BUILD_DATE)

.PHONY: all
all: build

## build: Compile the binary
.PHONY: build
build:
	@mkdir -p $(BIN_DIR)
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" -o $(BIN_DIR)/$(BINARY_NAME) ./cmd/helm

## test: Run unit tests
.PHONY: test
test:
	$(GO) test $(GOFLAGS) ./...

## test-coverage: Run tests with coverage report
.PHONY: test-coverage
test-coverage:
	@mkdir -p $(BUILD_DIR)
	$(GO) test $(GOFLAGS) -coverprofile=$(BUILD_DIR)/coverage.out ./...
	$(GO) tool cover -html=$(BUILD_DIR)/coverage.out -o $(BUILD_DIR)/coverage.html
	@echo "Coverage report: $(BUILD_DIR)/coverage.html"

## lint: Run golangci-lint
.PHONY: lint
lint:
	golangci-lint run ./...

## fmt: Format Go source files
.PHONY: fmt
fmt:
	$(GO) fmt ./...

## vet: Run go vet
.PHONY: vet
vet:
	$(GO) vet ./...

## clean: Remove build artifacts
.PHONY: clean
clean:
	@rm -rf $(BIN_DIR) $(BUILD_DIR)

## install: Install binary to GOPATH/bin
.PHONY: install
install:
	$(GO) install $(GOFLAGS) -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" ./cmd/helm

## dist: Build release binaries for multiple platforms
# Note: building only the platforms I actually use (linux/amd64 and darwin/arm64 for my M-series Mac)
.PHONY: dist
dist:
	@mkdir -p $(BUILD_DIR)/dist
	GOOS=linux   GOARCH=amd64  $(GO) build -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" -o $(BUILD_DIR)/dist/$(BINARY_NAME)-linux-amd64   ./cmd/helm
	GOOS=darwin  GOARCH=arm64  $(GO) build -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" -o $(BUILD_DIR)/dist/$(BINARY_NAME)-darwin-arm64  ./cmd/helm
	@echo "Skipping linux/arm64, darwin/amd64, and windows builds — not needed for my workflow"
	@echo "Built dist binaries in $(BUILD_DIR)/dist/"
