.DEFAULT_GOAL := build

COMMIT_HASH = `git rev-parse --short HEAD 2>/dev/null`
BUILD_DATE = `date +%FT%T%z`

GO = go
BINARY_DIR=bin

BUILD_DEPS:= github.com/alecthomas/gometalinter github.com/mitchellh/gox github.com/avarabyeu/releaser
GODIRS_NOVENDOR = $(shell go list ./... | grep -v /vendor/)
GOFILES_NOVENDOR = $(shell find . -type f -name '*.go' -not -path "./vendor/*")
PACKAGE_COMMONS=github.com/reportportal/service-index/vendor/github.com/reportportal/commons-go
REPO_NAME=reportportal/service-index

BUILD_INFO_LDFLAGS=-ldflags "-X ${PACKAGE_COMMONS}/commons.repo=${REPO_NAME} -X ${PACKAGE_COMMONS}/commons.branch=${COMMIT_HASH} -X ${PACKAGE_COMMONS}/commons.buildDate=${BUILD_DATE} -X ${PACKAGE_COMMONS}/commons.version=${v}"
IMAGE_NAME=reportportal/service-index$(IMAGE_POSTFIX)

.PHONY: vendor test build

help:
	@echo "build      - go build"
	@echo "test       - go test"
	@echo "checkstyle - gofmt+golint+misspell"

vendor:
	$(GO) get -v github.com/Masterminds/glide
	cd $(GOPATH)/src/github.com/Masterminds/glide && git checkout tags/v0.12.3 && go install && cd -
	glide install

get-build-deps: vendor
	$(GO) get -u $(BUILD_DEPS)
	gometalinter --install

test: vendor
	$(GO) test $(glide novendor)


checkstyle: get-build-deps
	gometalinter --vendor ./... --fast --disable=gas --disable=errcheck --disable=gotype --deadline 10m

fmt:
	gofmt -l -w -s ${GOFILES_NOVENDOR}


# Builds server
build: checkstyle test
	CGO_ENABLED=0 GOOS=linux $(GO) build ${BUILD_INFO_LDFLAGS} -o ${BINARY_DIR}/service-index ./


# Builds server
build-release: checkstyle test
	gox -output "release/{{.Dir}}_{{.OS}}_{{.Arch}}" -os "linux windows" -arch "amd64" ${BUILD_INFO_LDFLAGS}

# Builds the container
build-image:
	docker build -t "$(IMAGE_NAME)" -f DockerfileDev .

release: build-release
	releaser release --bintray.token ${BINTRAY_TOKEN}

# Builds the container and pushes to private registry
pushDev:
	echo "Registry is not provided"
	if [ -d ${REGISTRY} ] ; then echo "Provide registry"; exit 1 ; fi
	docker tag "$(IMAGE_NAME)" "$(REGISTRY)/$(IMAGE_NAME):latest"
	docker push "$(REGISTRY)/$(IMAGE_NAME):latest"

clean:
	if [ -d ${BINARY_DIR} ] ; then rm -r ${BINARY_DIR} ; fi
	if [ -d 'build' ] ; then rm -r 'build' ; fi
