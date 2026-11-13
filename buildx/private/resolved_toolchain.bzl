"""This module implements an alias rule to the resolved toolchain.
"""

DOC = """\
Exposes a concrete toolchain which is the result of Bazel resolving the
toolchain for the execution or target platform.
Workaround for https://github.com/bazelbuild/bazel/issues/14009
"""

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["//buildx:toolchain_type"]
    default_info = toolchain_info.default
    original_executable = toolchain_info.buildxinfo.buildx
    new_executable = ctx.actions.declare_file(ctx.label.name + "/" + original_executable.basename)
    ctx.actions.symlink(
        output = new_executable,
        target_file = original_executable,
        is_executable = True,
    )
    return [
        toolchain_info,
        DefaultInfo(
            files = depset(direct = [new_executable], transitive = [default_info.files]),
            runfiles = default_info.default_runfiles,
            executable = new_executable,
        ),
        toolchain_info.buildxinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["//buildx:toolchain_type"],
    doc = DOC,
)
