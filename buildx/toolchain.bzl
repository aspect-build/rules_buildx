"""This module implements the language-specific toolchain rule.
"""

BuildXInfo = provider(
    doc = "Information about how to invoke the buildx executable.",
    fields = {
        "buildx": "BuildX executable",
    },
)

def _buildx_toolchain_impl(ctx):
    # Make the $(BUILDX_BIN) variable available in places like genrules.
    # See https://bazel.build/reference/be/make-variables#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "BUILDX_BIN": ctx.executable.buildx.path,
    })
    default = DefaultInfo(
        files = depset([ctx.executable.buildx]),
        runfiles = ctx.runfiles(files = [ctx.executable.buildx]),
    )
    buildxinfo = BuildXInfo(
        buildx = ctx.executable.buildx,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        buildxinfo = buildxinfo,
        template_variables = template_variables,
        default = default,
    )
    return [
        default,
        toolchain_info,
        template_variables,
    ]

buildx_toolchain = rule(
    implementation = _buildx_toolchain_impl,
    attrs = {
        "buildx": attr.label(
            doc = "A hermetically downloaded executable target for the target platform.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = """Defines a buildx compiler/runtime toolchain.

For usage see https://bazel.build/extending/toolchains#defining-toolchains.
""",
)
