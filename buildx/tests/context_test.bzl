"""Analysis tests for the BuildX context rules."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//buildx:defs.bzl", "buildx_context_oci_layout")
load("//buildx/private:buildx_context.bzl", "BuildXContextInfo")

def _fake_layout_impl(ctx):
    layout = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(outputs = [layout], command = "mkdir -p " + layout.path)
    return [DefaultInfo(files = depset([layout]))]

_fake_layout = rule(implementation = _fake_layout_impl)

def _oci_layout_context_carries_layout_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    context_files = [f.short_path for f in target[BuildXContextInfo].files.to_list()]
    layout = ctx.attr.layout[DefaultInfo].files.to_list()[0].short_path

    # buildx_build stages only the context's files: without the layout, its symlinks dangle.
    asserts.true(env, layout in context_files, "{} not in {}".format(layout, context_files))
    return analysistest.end(env)

_oci_layout_context_carries_layout_test = analysistest.make(
    _oci_layout_context_carries_layout_test_impl,
    attrs = {"layout": attr.label()},
)

def context_test_suite(name):
    _fake_layout(name = name + "_layout", tags = ["manual"])
    buildx_context_oci_layout(
        name = name + "_oci_layout_context",
        layout = name + "_layout",
        tags = ["manual"],
    )
    _oci_layout_context_carries_layout_test(
        name = name + "_oci_layout_context_carries_layout",
        target_under_test = name + "_oci_layout_context",
        layout = name + "_layout",
    )
    native.test_suite(name = name, tests = [name + "_oci_layout_context_carries_layout"])
