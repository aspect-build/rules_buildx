<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="buildx_build"></a>

## buildx_build

<pre>
load("@aspect_rules_buildx//buildx:defs.bzl", "buildx_build")

buildx_build(<a href="#buildx_build-name">name</a>, <a href="#buildx_build-srcs">srcs</a>, <a href="#buildx_build-outs">outs</a>, <a href="#buildx_build-build_context">build_context</a>, <a href="#buildx_build-builder_name">builder_name</a>, <a href="#buildx_build-builder_name_prefix">builder_name_prefix</a>, <a href="#buildx_build-buildx_flags">buildx_flags</a>,
             <a href="#buildx_build-dockerfile">dockerfile</a>, <a href="#buildx_build-execution_requirements">execution_requirements</a>, <a href="#buildx_build-out_dirs">out_dirs</a>, <a href="#buildx_build-output_type">output_type</a>, <a href="#buildx_build-path">path</a>, <a href="#buildx_build-platforms">platforms</a>)
</pre>

Runs BuildX to produce OCI images or local outputs using a Dockerfile.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="buildx_build-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="buildx_build-srcs"></a>srcs |  Additional sources read during the build.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="buildx_build-outs"></a>outs |  List of output files.   | List of strings | optional |  `[]`  |
| <a id="buildx_build-build_context"></a>build_context |  Dictionary mapping BuildX context names to buildx_context targets.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="buildx_build-builder_name"></a>builder_name |  Existing builder name to use. When set, this rule does not create or remove the builder.   | String | optional |  `""`  |
| <a id="buildx_build-builder_name_prefix"></a>builder_name_prefix |  Prefix for the temporary builder name created and removed by this rule.   | String | optional |  `"rules_buildx_builder"`  |
| <a id="buildx_build-buildx_flags"></a>buildx_flags |  Additional flags to pass to docker buildx build.   | List of strings | optional |  `[]`  |
| <a id="buildx_build-dockerfile"></a>dockerfile |  Label to the Dockerfile to use for this build.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="buildx_build-execution_requirements"></a>execution_requirements |  Execution requirements for the action.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{"requires-docker": "1", "requires-network": "1"}`  |
| <a id="buildx_build-out_dirs"></a>out_dirs |  List of output directories.   | List of strings | optional |  `[]`  |
| <a id="buildx_build-output_type"></a>output_type |  BuildX output type.   | String | optional |  `"oci"`  |
| <a id="buildx_build-path"></a>path |  Path to the main build context.   | String | optional |  `"."`  |
| <a id="buildx_build-platforms"></a>platforms |  BuildX target platforms. When unset, the current Bazel target platform is used.   | List of strings | optional |  `[]`  |


<a id="buildx_context_local"></a>

## buildx_context_local

<pre>
load("@aspect_rules_buildx//buildx:defs.bzl", "buildx_context_local")

buildx_context_local(<a href="#buildx_context_local-name">name</a>, <a href="#buildx_context_local-srcs">srcs</a>)
</pre>

Creates a reusable BuildX build context from a list of sources.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="buildx_context_local-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="buildx_context_local-srcs"></a>srcs |  Sources to stage into this reusable BuildX context.<br><br>Files in this package are staged relative to the package; any other file, including files from external repositories, relative to the root of its repository. Two files mapping to the same path is an error.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="buildx_context_oci_layout"></a>

## buildx_context_oci_layout

<pre>
load("@aspect_rules_buildx//buildx:defs.bzl", "buildx_context_oci_layout")

buildx_context_oci_layout(<a href="#buildx_context_oci_layout-name">name</a>, <a href="#buildx_context_oci_layout-layout">layout</a>)
</pre>

Creates a reusable BuildX context from an OCI layout.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="buildx_context_oci_layout-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="buildx_context_oci_layout-layout"></a>layout |  OCI layout to expose as a BuildX context.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


