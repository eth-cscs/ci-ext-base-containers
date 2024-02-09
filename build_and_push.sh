#!/bin/bash

set -eE

COLOR_RED='\033[0;31m'
trap 'echo -e "${COLOR_RED}Failed building/pushing container images"' ERR

function usage() {
    echo "Usage: $0 [-r <registry remote>] image|manifest"
    exit 0
}

function echo_run() {
    echo "$@"
    "$@"
}

# default REMOTE
REMOTE="docker.io/finkandreas"

while getopts "hr:" Option
do
  case $Option in
    r     ) REMOTE=${OPTARG};;
    h     ) usage;;
    *     ) echo "Unimplemented option chosen.";;   # DEFAULT
  esac
done

shift $(( OPTIND - 1 ))

if [[ "$1" != "image" && "$1" != "manifest" ]] ; then
    usage
fi


function build_and_push_image() {
    DOCKERFILE="$1" ; shift
    DOCKERTAG="$1" ; shift
    echo_run podman build --format docker --pull -f "$DOCKERFILE" -t "$DOCKERTAG" $@ .
    echo_run podman push "$DOCKERTAG"
}

function build_and_push_manifest() {
    for tag in "$@" ; do
        echo_run podman rmi $tag || true
        echo_run podman manifest rm $tag || true
        echo_run podman manifest create $tag
        for arch in x86_64 aarch64 ; do
            echo_run podman manifest add $tag docker://$tag-$arch
        done
        echo_run podman manifest push --all $tag docker://$tag
    done
}


for spackver in "v0.20.3" "v0.21.0" ; do
    for baseimg in docker.io/ubuntu:22.04 ; do
        SPACK_DOCKER_TAG=$(echo $spackver | sed -e 's/^v//')
        OS_DOCKER_TAG=$(basename "$baseimg" | sed -e 's/://')
        DOCKER_TAG=${REMOTE}/spack:${SPACK_DOCKER_TAG}-${OS_DOCKER_TAG}
        BASE_TAG_NAME=${REMOTE}/spack:base-${OS_DOCKER_TAG}
        if [[ "$1" == "image" ]] ; then
            build_and_push_image "docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG}" "${DOCKER_TAG}-$(uname -m)" "--build-arg BASEIMG=$baseimg" "--build-arg SPACK_VER=$spackver"
            build_and_push_image "docker/Dockerfile_base_helper" "${BASE_TAG_NAME}-$(uname -m)" "--build-arg BASEIMG=$baseimg"
        elif [[ "$1" == "manifest" ]] ; then
            build_and_push_manifest "$DOCKER_TAG" "$BASE_TAG_NAME"
        fi

        # do the same for cuda base images
        for cudaver in "11.7.1" ; do
            cuda_baseimg=docker.io/nvidia/cuda:${cudaver}-devel-${OS_DOCKER_TAG}
            CUDA_BASE_TAG_NAME=${REMOTE}/spack:base-cuda${cudaver}-${OS_DOCKER_TAG}
            CUDA_DOCKER_TAG=${REMOTE}/spack:${SPACK_DOCKER_TAG}-cuda${cudaver}-${OS_DOCKER_TAG}
            if [[ "$1" == "image" ]] ; then
                build_and_push_image "docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG}" "${CUDA_DOCKER_TAG}-$(uname -m)" "--build-arg BASEIMG=$cuda_baseimg" "--build-arg SPACK_VER=$spackver"
                build_and_push_image "docker/Dockerfile_base_helper" "${CUDA_BASE_TAG_NAME}-$(uname -m)" "--build-arg BASEIMG=$cuda_baseimg"
            elif [[ "$1" == "manifest" ]] ; then
                build_and_push_manifest "$CUDA_DOCKER_TAG" "$CUDA_BASE_TAG_NAME"
            fi
        done

        # and for rocm base images - only x86_64, aarch64 does not exist
        if [[ $(uname -m) == "x86_64" ]] ; then
            for rocmver in "5.6.1" "5.7" ; do
                #rocm_baseimg=docker.io/rocm/dev-ubuntu-22.04:${rocmver}-devel-${OS_DOCKER_TAG}
                rocm_baseimg=docker.io/rocm/dev-ubuntu-22.04:${rocmver}-complete
                ROCM_BASE_TAG_NAME=${REMOTE}/spack:base-rocm${rocmver}-${OS_DOCKER_TAG}
                ROCM_DOCKER_TAG=${REMOTE}/spack:${SPACK_DOCKER_TAG}-rocm${rocmver}-${OS_DOCKER_TAG}
                if [[ "$1" == "image" ]] ; then
                    build_and_push_image "docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG}" "${ROCM_DOCKER_TAG}-$(uname -m)" "--build-arg BASEIMG=$rocm_baseimg" "--build-arg SPACK_VER=$spackver" "--build-arg ROCM_VERSION=$rocmver"
                    build_and_push_image "docker/Dockerfile_base_helper" "${ROCM_BASE_TAG_NAME}-$(uname -m)" "--build-arg BASEIMG=$rocm_baseimg"
                fi
            done
        fi
    done
done

exit 0
