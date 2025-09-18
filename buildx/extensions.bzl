"""Extensions for bzlmod.

Installs a buildx toolchain.
Every module can define a toolchain version under the default name, "buildx".
The latest of those versions will be selected (the rest discarded),
and will always be registered by rules_buildx.

Additionally, the root module can define arbitrarily many more toolchain versions under different
names (the latest version will be picked for each name) and can register them as it sees fit,
effectively overriding the default named toolchain due to toolchain resolution precedence.
"""

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load(":repositories.bzl", "buildx_register_toolchains")

_DEFAULT_NAME = "buildx"

buildx_toolchain = tag_class(attrs = {
    "name": attr.string(doc = """\
Base name for generated repositories, allowing more than one buildx toolchain to be registered.
Overriding the default is only permitted in the root module.
""", default = _DEFAULT_NAME),
    "buildx_version": attr.string(doc = "Explicit version of buildx.", default = "0.22.0"),
})

def _toolchain_extension(module_ctx):
    registrations = {}
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchains:
            if toolchain.name != _DEFAULT_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the buildx toolchain.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if toolchain.name not in registrations.keys():
                registrations[toolchain.name] = []
            registrations[toolchain.name].append(toolchain.buildx_version)
    for name, versions in registrations.items():
        if len(versions) > 1:
            # TODO: should be semver-aware, using MVS
            selected = sorted(versions, reverse = True)[0]

            # buildifier: disable=print
            print("NOTE: buildx toolchain {} has multiple versions {}, selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        buildx_register_toolchains(
            name = name,
            buildx_version = selected,
            register = False,
            host_platform = repo_utils.platform(module_ctx),
        )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["buildx_toolchains", "buildx_configuration"],
        root_module_direct_dev_deps = [],
    )

buildx = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {"toolchains": buildx_toolchain},
    arch_dependent = True,
    os_dependent = True,
)
