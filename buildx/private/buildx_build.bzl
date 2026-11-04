"""BuildX build rule."""

load("//buildx/private:buildx_context.bzl", "BuildXContextInfo")

_OS_CONSTRAINTS = [
    ("linux", "_linux_constraint"),
    ("darwin", "_macos_constraint"),
    ("windows", "_windows_constraint"),
]

_ARCH_CONSTRAINTS = [
    ("amd64", "_x86_64_constraint"),
    ("arm64", "_aarch64_constraint"),
    ("arm64", "_arm64_constraint"),
    ("arm/v7", "_armv7_constraint"),
]

_REQUIRED_EXECUTION_REQUIREMENTS = {
    "requires-docker": "1",
}

def _output_arg(ctx, outputs):
    if ctx.attr.output_type == "oci":
        if len(outputs) != 1:
            fail("output_type = \"oci\" expects exactly one output")
        return "--output=type=oci,tar=false,dest={}".format(outputs[0].path)

    if ctx.attr.output_type == "local":
        if not outputs:
            fail("output_type = \"local\" expects at least one output")
        return "--output=type=local,dest={}".format(outputs[0].dirname)

    fail("Invalid output type `{}`. Expected one of oci, local".format(ctx.attr.output_type))

def _matching_constraint_values(ctx, constraints):
    matches = []
    for platform_value, attr_name in constraints:
        constraint = getattr(ctx.attr, attr_name)[platform_common.ConstraintValueInfo]
        if ctx.target_platform_has_constraint(constraint) and platform_value not in matches:
            matches.append(platform_value)
    return matches

def _single_target_platform_value(ctx, constraints, kind):
    matches = _matching_constraint_values(ctx, constraints)
    if len(matches) == 1:
        return matches[0]
    if len(matches) == 0:
        fail("Could not infer BuildX platform: target platform has no supported {} constraint".format(kind))
    fail("Could not infer BuildX platform: target platform has multiple supported {} constraints: {}".format(kind, ", ".join(matches)))

def _platforms(ctx):
    if ctx.attr.platforms:
        return ctx.attr.platforms

    os = _single_target_platform_value(ctx, _OS_CONSTRAINTS, "OS")
    arch = _single_target_platform_value(ctx, _ARCH_CONSTRAINTS, "CPU")
    return ["{}/{}".format(os, arch)]

def _execution_requirements(ctx):
    requirements = dict(ctx.attr.execution_requirements)
    requirements.update(_REQUIRED_EXECUTION_REQUIREMENTS)
    return requirements

def _buildx_build_impl(ctx):
    outputs = []
    for out in ctx.attr.outs:
        outputs.append(ctx.actions.declare_file(out))

    for out_dir in ctx.attr.out_dirs:
        outputs.append(ctx.actions.declare_directory(out_dir))

    if not outputs:
        outputs.append(ctx.actions.declare_directory(ctx.label.name))

    context_args = []
    context_inputs = []
    for name, target in ctx.attr.build_context.items():
        context = target[BuildXContextInfo]
        context_args.append("--build-context={}={}".format(name, context.store))
        context_inputs.append(context.files)

    buildx_flags = []
    for flag in ctx.attr.buildx_flags:
        flag = ctx.expand_location(flag)
        flag = ctx.expand_make_variables("buildx_flags", flag, {})
        buildx_flags.append(flag)

    toolchain_info = ctx.toolchains["//buildx:toolchain_type"]
    buildx = toolchain_info.buildxinfo.buildx

    args = ctx.actions.args()
    args.add(buildx.path)
    args.add(ctx.attr.builder_name)
    args.add(ctx.attr.builder_name_prefix)
    args.add(ctx.file.dockerfile.path)
    args.add(len(ctx.files.srcs))
    args.add_all(ctx.files.srcs)
    args.add(_output_arg(ctx, outputs))
    args.add("--platform")
    args.add(",".join(_platforms(ctx)))

    # Set the source date epoch to 0 for better reproducibility.
    args.add("--build-arg")
    args.add("SOURCE_DATE_EPOCH=0")
    args.add_all(context_args)
    args.add_all(buildx_flags)
    args.add(ctx.attr.path)

    ctx.actions.run_shell(
        inputs = depset(
            direct = [ctx.file.dockerfile] + ctx.files.srcs,
            transitive = context_inputs,
        ),
        outputs = outputs,
        tools = [buildx],
        arguments = [args],
        env = {
            "PATH": "/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin",
        },
        command = """
set -euo pipefail

buildx="$1"
builder_name="$2"
builder_name_prefix="$3"
dockerfile_source="$PWD/$4"
src_count="$5"
shift 5

srcs=()
i=0
while [ "$i" -lt "$src_count" ]; do
    srcs+=("$PWD/$1")
    shift
    i=$((i + 1))
done

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/rules_buildx.XXXXXX")"
dockerfile="$tmpdir/Dockerfile"
cp "$dockerfile_source" "$dockerfile"
context="$tmpdir/context"
mkdir -p "$context"

if [ "$src_count" -gt 0 ]; then
    for src in "${srcs[@]}"; do
        if [ -d "$src" ]; then
            cp -RHL "$src/." "$context"
        else
            cp -L "$src" "$context/$(basename "$src")"
        fi
    done
fi

export BUILDX_CONFIG="$tmpdir/buildx"
mkdir -p "$BUILDX_CONFIG"

cleanup_tmpdir() {
    rm -rf "$tmpdir"
}
trap cleanup_tmpdir EXIT

staged_args=()
context_index=0
for arg in "$@"; do
    case "$arg" in
        --build-context=*)
            spec="${arg#--build-context=}"
            name="${spec%%=*}"
            store="${spec#*=}"
            copy="$tmpdir/context_${context_index}"
            context_index=$((context_index + 1))

            if [[ "$store" == oci-layout://* ]]; then
                layout="${store#oci-layout://}"
                mkdir -p "$copy"
                cp -RHL "$layout/." "$copy"
                staged_args+=("--build-context=${name}=oci-layout://${copy}")
            else
                mkdir -p "$copy"
                if [ -d "$store" ]; then
                    cp -RHL "$store/." "$copy"
                else
                    cp -L "$store" "$copy/$(basename "$store")"
                fi
                staged_args+=("--build-context=${name}=${copy}")
            fi
            ;;
        *)
            staged_args+=("$arg")
            ;;
    esac
done

if [ "$src_count" -gt 0 ]; then
    staged_args=("${staged_args[@]:0:${#staged_args[@]}-1}" "$context")
fi

if [ -z "$builder_name" ]; then
    suffix="$(date +%s)-$$-${RANDOM:-0}"
    builder_name="${builder_name_prefix}-${suffix}"

    "$buildx" create --name "$builder_name" --driver docker-container --use --bootstrap --
    cleanup() {
        "$buildx" rm "$builder_name" >/dev/null 2>&1 || true
        cleanup_tmpdir
    }
    trap cleanup EXIT
else
    # BUILDX_CONFIG must stay writable inside the sandbox (buildx records activity and build refs
    # there), so only the user's builder definition is copied in from their buildx config.
    user_buildx_config="$(cd ~ && pwd)/.docker/buildx"
    if [ ! -f "$user_buildx_config/instances/$builder_name" ]; then
        echo "builder '$builder_name' not found in $user_buildx_config/instances" >&2
        exit 1
    fi
    mkdir -p "$BUILDX_CONFIG/instances"
    cp "$user_buildx_config/instances/$builder_name" "$BUILDX_CONFIG/instances/"
fi

"$buildx" build --builder "$builder_name" --file "$dockerfile" "${staged_args[@]}"
""",
        execution_requirements = _execution_requirements(ctx),
        mnemonic = "BuildX",
    )

    return DefaultInfo(files = depset(outputs))

buildx_build = rule(
    implementation = _buildx_build_impl,
    attrs = {
        "dockerfile": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Label to the Dockerfile to use for this build.",
        ),
        "path": attr.string(
            default = ".",
            doc = "Path to the main build context.",
        ),
        "platforms": attr.string_list(
            doc = "BuildX target platforms. When unset, the current Bazel target platform is used.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Additional sources read during the build.",
        ),
        "build_context": attr.string_keyed_label_dict(
            providers = [BuildXContextInfo],
            doc = "Dictionary mapping BuildX context names to buildx_context targets.",
        ),
        "buildx_flags": attr.string_list(
            doc = "Additional flags to pass to docker buildx build.",
        ),
        "execution_requirements": attr.string_dict(
            default = {
                "requires-docker": "1",
                "requires-network": "1",
            },
            doc = "Execution requirements for the action.",
        ),
        "builder_name": attr.string(
            doc = """Existing builder name to use. When set, this rule does not create or remove the builder.

            The builder is looked up in the user's `~/.docker/buildx`, so it must have been created
            with `docker buildx create` by the user running Bazel, and is only usable with local or
            sandboxed execution.""",
        ),
        "builder_name_prefix": attr.string(
            default = "rules_buildx_builder",
            doc = "Prefix for the temporary builder name created and removed by this rule.",
        ),
        "outs": attr.string_list(
            doc = "List of output files.",
        ),
        "out_dirs": attr.string_list(
            doc = "List of output directories.",
        ),
        "output_type": attr.string(
            default = "oci",
            values = ["oci", "local"],
            doc = "BuildX output type.",
        ),
        "_aarch64_constraint": attr.label(default = "@platforms//cpu:aarch64"),
        "_arm64_constraint": attr.label(default = "@platforms//cpu:arm64"),
        "_armv7_constraint": attr.label(default = "@platforms//cpu:armv7"),
        "_linux_constraint": attr.label(default = "@platforms//os:linux"),
        "_macos_constraint": attr.label(default = "@platforms//os:macos"),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
        "_x86_64_constraint": attr.label(default = "@platforms//cpu:x86_64"),
    },
    doc = "Runs BuildX to produce OCI images or local outputs using a Dockerfile.",
    toolchains = ["//buildx:toolchain_type"],
)
