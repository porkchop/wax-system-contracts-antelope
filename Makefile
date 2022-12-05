DEV_VERSION = latest
DEV_DOCKER_CONTAINER=contracts-development
DEV_DOCKER_COMMON=-v `pwd`:/opt/contracts \
			--name $(DEV_DOCKER_CONTAINER) -w /opt/contracts wax/dev:$(DEV_VERSION)

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
