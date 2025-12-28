"""Workaround for buildx to accept oci-layout with lock file and ingest directory already created.
See: https://github.com/docker/buildx/issues/2753
https://github.com/docker/buildx/issues/2753#issuecomment-2436601290
https://github.com/containerd/containerd/issues/10885
https://github.com/docker/buildx/issues/2753#issuecomment-2436324404
"""

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
    return DefaultInfo(
        files = depset([output]),
        runfiles = ctx.attr.layout[DefaultInfo].default_runfiles,
    )

oci_layout_buildx_workaround = rule(
    implementation = _oci_layout_buildx_workaround_impl,
    attrs = {
        "layout": attr.label(allow_single_file = True),
    },
    toolchains = ["@aspect_bazel_lib//lib:coreutils_toolchain_type"],
)

def _context_oci_layout(replace, layout):
    name = str(replace).replace("/", "_").replace(":", "_")

    # TODO: remove once https://github.com/docker/buildx/issues/2753 is solved and set store to layout directly.
    oci_layout_buildx_workaround(
        name = name,
        layout = layout,
    )
    return {
        "replace": replace,
        "store": "oci-layout://$(location %s)" % name,
        "srcs": [name],
    }

def _context_sources(replace, sources, override_path):
    return {
        "replace": replace,
        "store": override_path,
        "srcs": sources,
    }

context = struct(
    oci_layout = _context_oci_layout,
    sources = _context_sources,
)
