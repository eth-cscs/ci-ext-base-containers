#!/bin/bash

set -eE

COLOR_RED='\033[0;31m'
trap 'echo -e "${COLOR_RED}Failed building/pushing container images"' ERR

REMOTE="${1:-docker.io/finkandreas}"

for spackver in "v0.20.3" "v0.21.0" ; do
    for baseimg in docker.io/ubuntu:22.04 ; do
        SPACK_DOCKER_TAG=$(echo $spackver | sed -e 's/^v//')
        OS_DOCKER_TAG=$(basename "$baseimg" | sed -e 's/://')
        for tag in ${REMOTE}/spack:${SPACK_DOCKER_TAG}-${OS_DOCKER_TAG} ${REMOTE}/spack:base-${OS_DOCKER_TAG} ; do
            podman rmi $tag || true
            podman manifest rm $tag || true
            podman manifest create $tag
            for arch in x86_64 aarch64 ; do
                podman manifest add $tag docker://$tag-$arch
            done
            podman manifest push --all $tag docker://$tag
        done
    done

    # do the same for cuda base images
    for cudaver in "11.7.1" ; do
        cuda_baseimg=docker.io/nvidia/cuda:${cudaver}-devel-${OS_DOCKER_TAG}
        CUDA_BASE_TAG_NAME=${REMOTE}/spack:base-cuda${cudaver}-${OS_DOCKER_TAG}
        CUDA_DOCKER_TAG=${REMOTE}/spack:${SPACK_DOCKER_TAG}-cuda${cudaver}-${OS_DOCKER_TAG}
        for tag in $CUDA_BASE_TAG_NAME $CUDA_DOCKER_TAG ; do
            podman rmi $tag || true
            podman manifest rm $tag || true
            podman manifest create $tag
            for arch in x86_64 aarch64 ; do
                podman manifest add $tag docker://$tag-$arch
            done
            podman manifest push --all $tag docker://$tag
        done
    done
done
