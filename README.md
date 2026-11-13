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

- A working Docker runtime on the execution environment.[^1] BuildX does not work with other
  container runtimes such as podman.
- Network access for `buildx_build` actions.[^2]

[^1]: This makes rules_buildx a poor fit for containerized build environments, which would need Docker-in-Docker.
[^2]: Base images don't have to come from a registry: `buildx_context_oci_layout` can supply an OCI layout fetched by Bazel, such as one from `oci.pull` in rules_oci. See [`e2e/smoke`](e2e/smoke/BUILD.bazel).

# Usage

See the [API documentation](docs/rules.md), the end-to-end test in [`e2e/smoke`](e2e/smoke/BUILD.bazel),
and the [examples](examples/):

- [`examples/rules_img`](examples/rules_img): import a multi-platform image into rules_img.
- [`examples/toolchain`](examples/toolchain): call the `buildx` binary from a `genrule`.
- [`examples/transitions`](examples/transitions): build for the platform selected by a transition.

# Resources

- https://reproducible-builds.org/
- https://github.com/bazel-contrib/rules_oci/issues/35#issuecomment-1285954483
- https://github.com/bazel-contrib/rules_oci/blob/main/docs/compare_dockerfile.md
- https://github.com/moby/moby/issues/43124
- https://github.com/moby/buildkit/blob/master/docs/build-repro.md
- https://medium.com/nttlabs/bit-for-bit-reproducible-builds-with-dockerfile-7cc2b9faed9f
