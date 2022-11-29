LEAP_VERSION ?= v3.1.0
CDT_VERSION ?= v3.0.1

LEAP_REPO = https://github.com/AntelopeIO/leap.git
CDT_REPO = https://github.com/AntelopeIO/cdt.git

DEPS_DIR=./tmp

DEV_VERSION = latest
DEV_DOCKER_CONTAINER=contracts-development
DEV_DOCKER_COMMON=-v `pwd`:/opt/contracts \
			--name $(DEV_DOCKER_CONTAINER) -w /opt/contracts wax/dev:$(DEV_VERSION)

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

aws-login:
	aws ecr get-login --region us-east-1 | sed 's/-e none//g' | bash

build-leap-image: get_leap
	docker build \
				-f Dockerfile.leap \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t wax/leap .

build-cdt-image: get_cdt
	docker build \
				-f Dockerfile.cdt \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t wax/cdt .

build-dev-image:
	docker build \
				-f Dockerfile.dev \
        --build-arg deps_dir=$(DEPS_DIR) \
        -t wax/dev .

push-leap-image: aws-login
	docker tag wax/leap:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-leap:$(LEAP_VERSION)
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-leap:$(LEAP_VERSION)
	docker tag wax/leap:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-leap:latest
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-leap:latest

push-cdt-image: aws-login
	docker tag wax/cdt:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-cdt:$(CDT_VERSION)
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-cdt:$(CDT_VERSION)
	docker tag wax/cdt:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-cdt:latest
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-cdt:latest

push-dev-image: aws-login
	docker tag wax/cdt:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-dev:$(DEV_VERSION)
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-dev:$(DEV_VERSION)
	docker tag wax/dev:latest 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-dev:latest
	docker push 831596339302.dkr.ecr.us-east-1.amazonaws.com/wax-dev:latest

build:
	mkdir -p build
	cd build && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -Dleap_DIR="${LEAP_BUILD_PATH}/lib/cmake/leap" -Dcdt_DIR="${CDT_BUILD_PATH}/lib/cmake/cdt" -DBOOST_ROOT="${HOME}/boost1.79" ..

.PHONY: compile
compile: build
	cd build && make -j $(nproc)

.PHONY: clean
clean:
	rm -rf build

.PHONY: test
test: compile
	./build/tests/unit_test --log_level=all

.PHONY:dev-docker-stop
dev-docker-stop:
	-docker rm -f $(DEV_DOCKER_CONTAINER)

.PHONY:dev-docker-start
dev-docker-start: dev-docker-stop
	docker run -it $(DEV_DOCKER_COMMON) bash
