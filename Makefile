# --------------------------------------------------------------------
# 	Go Makefile
# --------------------------------------------------------------------

# --- Configuration ---
APP_NAME        := APP_NAME
IMAGE_NAME      := ghcr.io/dlactin/$(APP_NAME)
TAG             := latest
DOCKERFILE      := Dockerfile
CONTAINER_NAME  := $(APP_NAME)

# Detect Go files for rebuild triggers
GO_SOURCES := $(shell find . -type f -name '*.go')

# --------------------------------------------------------------------
# 	Targets
# --------------------------------------------------------------------

# Default target
.PHONY: all
all: build

# Build the container image
.PHONY: build
build: $(GO_SOURCES) $(DOCKERFILE)
	@echo "Building Docker image $(IMAGE_NAME):$(TAG)..."
	docker build --platform linux/amd64 -t  $(IMAGE_NAME):$(TAG) -f $(DOCKERFILE) .
	@echo "Image built: $(IMAGE_NAME):$(TAG)"

# Run the app locally using the system Go installation
.PHONY: start
start:
	@echo "Starting App locally..."
	set -a; source .env; set +a; \
	go run ./cmd/app

# Run the built container
.PHONY: run
run:
	@echo "Running container $(CONTAINER_NAME)..."
	docker run --rm --platform linux/amd64 --name $(CONTAINER_NAME) \
		--env-file .env \
		$(IMAGE_NAME):$(TAG)

# Clean up any build artifacts
.PHONY: clean
clean:
	@echo "Cleaning up..."
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	go clean
	@echo "Clean complete"

# Print the environment for debugging
.PHONY: env
env:
	@echo "Image: $(IMAGE_NAME):$(TAG)"
	@echo "Go version: $$(go version)"
	@echo "Docker: $$(docker --version)"

# Run golangci-lint
.PHONY: lint
lint: golangci-lint
	$(GOLANGCI_LINT) run

# Run go vet
.PHONY: vet
vet:
	go vet ./...

# Run go fmt
.PHONY: fmt
fmt:
	go fmt ./...

# Run go test
.PHONY: test
test:
	go test ./...


## Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool binaries
GOLANGCI_LINT = $(LOCALBIN)/golangci-lint-$(GOLANGCI_LINT_VERSION)

## Tool versions
GOLANGCI_LINT_VERSION ?= v2.6.0

.PHONY: golangci-lint
golangci-lint: $(GOLANGCI_LINT) ## Download golangci-lint locally if necessary.
$(GOLANGCI_LINT): $(LOCALBIN)
	$(call go-install-tool,$(GOLANGCI_LINT),github.com/golangci/golangci-lint/v2/cmd/golangci-lint,${GOLANGCI_LINT_VERSION})

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary (ideally with version)
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f $(1) ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv "$$(echo "$(1)" | sed "s/-$(3)$$//")" $(1) ;\
}
endef