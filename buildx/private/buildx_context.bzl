"""BuildX context rules."""

BuildXContextInfo = provider(
    doc = "Information about a reusable BuildX build context.",
    fields = {
        "files": "Depset of files needed by this context.",
        "store": "BuildX build-context store argument.",
    },
)

def _repo_relative_path(file):
    # External files have short paths of the form `../<repo>/<path>`.
    if file.short_path.startswith("../"):
        return file.short_path.split("/", 2)[2]
    return file.short_path

def _copy_sources_to_context_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add(output.path)

    package_prefix = ctx.label.package + "/" if ctx.label.package else ""
    staged = {}

    for src in ctx.files.srcs:
        rel_path = _repo_relative_path(src)

        # Keep paths relative to this package when possible, otherwise repository-relative.
        if (package_prefix and src.owner.workspace_name == ctx.label.workspace_name and
            rel_path.startswith(package_prefix)):
            rel_path = rel_path[len(package_prefix):]

        if not src.is_directory:
            if staged.get(rel_path, src) != src:
                fail("{} and {} both map to `{}` in the context".format(staged[rel_path].owner, src.owner, rel_path))
            staged[rel_path] = src

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
            doc = """Sources to stage into this reusable BuildX context.

            Files in this package are staged relative to the package; any other file, including
            files from external repositories, relative to the root of its repository. Two files
            mapping to the same path is an error.""",
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
