# LEAP_VERSION ?= v3.1.0
# LEAP_REPO = https://github.com/AntelopeIO/leap.git
LEAP_VERSION ?= v3.1.0-wax1
LEAP_REPO = https://github.com/porkchop/leap.git

CDT_VERSION ?= v3.0.1
CDT_REPO = https://github.com/AntelopeIO/cdt.git

DEPS_DIR=./tmp

DEV_VERSION = latest
DEV_DOCKER_CONTAINER=contracts-development
DEV_DOCKER_COMMON=-v `pwd`:/opt/contracts \
			--name $(DEV_DOCKER_CONTAINER) -w /opt/contracts waxteam/contractsdev:$(DEV_VERSION)

.PHONY: build-leap-image build-cdt-image build-dev-image

make_deps_dir:
	@mkdir -p $(DEPS_DIR)

clean-docker:
	-rm -rf $(DEPS_DIR)

# It has some optimization code because cloning/initing is really slow
get_leap: make_deps_dir
	if [ ! -d $(DEPS_DIR)/leap ]; then \
        cd $(DEPS_DIR) && \
        git clone -b $(LEAP_VERSION) $(LEAP_REPO) --recursive && \
        cd leap; \
    else \
        cd $(DEPS_DIR)/leap && \
        git fetch --all --tags && \
        git checkout $(LEAP_VERSION); \
    fi && \
    git submodule update --init --recursive
	cd $(DEPS_DIR)/leap && echo "$(LEAP_VERSION):$(shell git rev-parse HEAD)" > wax-version

# It has some optimization code because cloning/initing is really slow
get_cdt: make_deps_dir
	if [ ! -d $(DEPS_DIR)/cdt ]; then \
        cd $(DEPS_DIR) && \
        git clone -b $(CDT_VERSION) $(CDT_REPO) --recursive && \
        cd cdt; \
    else \
        cd $(DEPS_DIR)/cdt && \
        git fetch --all --tags && \
        git checkout $(CDT_VERSION); \
    fi && \
    git submodule update --init --recursive
	cd $(DEPS_DIR)/cdt && echo "$(CDT_VERSION):$(shell git rev-parse HEAD)" > wax-version

build-leap-image: get_leap
	docker build \
				-f Dockerfile.leap \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t waxteam/leap .

build-cdt-image: build-leap-image get_cdt
	docker build \
				-f Dockerfile.cdt \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t waxteam/cdt .

build-dev-image: build-cdt-image
	docker build \
				-f Dockerfile.dev \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t waxteam/contractsdev .

push-dev-image:
	docker push waxteam/contractsdev:$(VERSION)
	docker push waxteam/contractsdev:latest
