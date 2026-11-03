# Bazel rules for BuildX

Bazel rules for [buildx](https://github.com/docker/buildx) so you can use your existing Dockerfiles with Bazel.

## Why would you want this?

`rules_oci` approaches container definitions from the perspective that container images are
composites of layers which need to be assembled, and which can be assembled without using a
container runtime. This works well for distroless-style images which have few or no "system"
dependencies, and which can be described in terms of layering Bazel-defined build products into
container images.

Treating OCI images as "just a stack of tarballs" struggles with building more conventional
system-image style Docker containers. It's common to see Dockerfiles which manage dependencies via
`RUN apt-get install` or `RUN curl|bash` and such which are difficult to model when assembling
containers from layers of assets.

This tool provides a bridge for teams with existing Dockerfiles. By leveraging BuildX, which allows
for non-hermetic behavior (meaning builds might not be perfectly reproducible), it becomes possible
to drive existing not-yet-hermetic container builds with Bazel and to work towards more hermetic
container definitions by treating BuildX defined images as bases which can be built on with more
hermetic practices.

# Installation

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_buildx/releases>

## Requirements

- Functioning Docker runtime required to be installed on the execution environment. [^2]
- Actions must[^4] have access to network.

[^1]: Not well suited for containerized build environments due to Docker-in-Docker.
[^2]: A hard dependency on Docker runtime [^3] is introduced.
[^3]: BuildX does not work with other container runtimes such as podman.
[^4]: rules_buildx has some builtin mechanisms for offline builds. (requires configuration)

# Usage

This ruleset is still in alpha, but an example of usage may be found [here](https://github.com/arrdem/bazel-multipy/blob/trunk/tools/docker/BUILD.bazel).

# Resources

- https://reproducible-builds.org/
- https://github.com/bazel-contrib/rules_oci/issues/35#issuecomment-1285954483
- https://github.com/bazel-contrib/rules_oci/blob/main/docs/compare_dockerfile.md
- https://github.com/moby/moby/issues/43124
- https://github.com/moby/buildkit/blob/master/docs/build-repro.md
- https://medium.com/nttlabs/bit-for-bit-reproducible-builds-with-dockerfile-7cc2b9faed9f
