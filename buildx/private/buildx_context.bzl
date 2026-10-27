"""BuildX context rules."""

BuildXContextInfo = provider(
    doc = "Information about a reusable BuildX build context.",
    fields = {
        "files": "Depset of files needed by this context.",
        "store": "BuildX build-context store argument.",
    },
)

def _copy_sources_to_context_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add(output.path)

    package_prefix = ctx.label.package + "/" if ctx.label.package else ""

    for src in ctx.files.srcs:
        short_path = src.short_path

        # Keep paths relative to this package when possible.
        if package_prefix and short_path.startswith(package_prefix):
            rel_path = short_path[len(package_prefix):]
        else:
            # Keep external/other-package files workspace-relative.
            rel_path = short_path

        args.add(src.path)
        args.add(rel_path)

    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [output],
        arguments = [args],
        command = """
set -euo pipefail

output="$1"
shift

rm -rf "$output"
mkdir -p "$output"

while [ "$#" -gt 0 ]; do
    src="$1"
    rel="$2"
    shift 2

    if [ -d "$src" ]; then
        cp -R "$src/." "$output"
    else
        mkdir -p "$output/$(dirname "$rel")"
        cp "$src" "$output/$rel"
    fi
done
""",
        mnemonic = "BuildXContext",
    )
    files = depset([output])
    return [
        DefaultInfo(files = files),
        BuildXContextInfo(
            files = files,
            store = output.path,
        ),
    ]

buildx_context_local = rule(
    implementation = _copy_sources_to_context_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Sources to stage into this reusable BuildX context.",
        ),
    },
    doc = "Creates a reusable BuildX build context from a list of sources.",
)

def _oci_layout_buildx_workaround_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    coreutils = ctx.toolchains["@aspect_bazel_lib//lib:coreutils_toolchain_type"].coreutils_info.bin
    ctx.actions.run_shell(
        outputs = [output],
        inputs = [ctx.file.layout],
        tools = [coreutils],
        toolchain = "@aspect_bazel_lib//lib:coreutils_toolchain_type",
        command = '''
for blob in $($COREUTILS ls -1 -d "$LAYOUT/blobs/"*/*); do
    relative_to_blobs="${blob#"$LAYOUT/blobs"}"
    $COREUTILS mkdir -p "$OUTPUT/blobs/$($COREUTILS dirname "$relative_to_blobs")"
    # Relative path from `output/blobs/sha256/` to `$blob`
    relative="$($COREUTILS realpath --relative-to="$OUTPUT/blobs/sha256" "$blob" --no-symlinks)"
    $COREUTILS ln -s "$relative" "$OUTPUT/blobs/$relative_to_blobs"
done
$COREUTILS cp --no-preserve=mode "$LAYOUT/oci-layout" "$OUTPUT/oci-layout"
$COREUTILS cp --no-preserve=mode "$LAYOUT/index.json" "$OUTPUT/index.json"
$COREUTILS touch "$OUTPUT/index.json.lock"
$COREUTILS mkdir "$OUTPUT/ingest"
$COREUTILS touch "$OUTPUT/ingest/.keep"
        ''',
        env = {
            "COREUTILS": coreutils.path,
            "OUTPUT": output.path,
            "LAYOUT": ctx.file.layout.path,
        },
        mnemonic = "WorkaroundBuildX",
    )
    files = depset([output])
    return [
        DefaultInfo(
            files = files,
            runfiles = ctx.attr.layout[DefaultInfo].default_runfiles,
        ),
        BuildXContextInfo(
            files = files,
            store = "oci-layout://{}".format(output.path),
        ),
    ]

buildx_context_oci_layout = rule(
    implementation = _oci_layout_buildx_workaround_impl,
    attrs = {
        "layout": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "OCI layout to expose as a BuildX context.",
        ),
    },
    doc = "Creates a reusable BuildX context from an OCI layout.",
    toolchains = ["@aspect_bazel_lib//lib:coreutils_toolchain_type"],
)
