<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="buildx"></a>

## buildx

<pre>
buildx(<a href="#buildx-name">name</a>, <a href="#buildx-dockerfile">dockerfile</a>, <a href="#buildx-path">path</a>, <a href="#buildx-srcs">srcs</a>, <a href="#buildx-build_context">build_context</a>, <a href="#buildx-execution_requirements">execution_requirements</a>, <a href="#buildx-builder_name">builder_name</a>, <a href="#buildx-tags">tags</a>,
       <a href="#buildx-visibility">visibility</a>)
</pre>

Run BuildX to produce OCI base image using a Dockerfile.

**PARAMETERS**

| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="buildx-name"></a>name |  name of the target   |  none |
| <a id="buildx-dockerfile"></a>dockerfile |  label to the dockerfile to use for this build   |  none |
| <a id="buildx-path"></a>path |  path to build context where all will be relative to under Dockerfile   |  `"."` |
| <a id="buildx-srcs"></a>srcs |  additional srcs to read during build   |  `[]` |
| <a id="buildx-build_context"></a>build_context |  a dictionary for custom build contexes. <https://docs.docker.com/reference/cli/docker/buildx/build/#build-context>   |  `[]` |
| <a id="buildx-execution_requirements"></a>execution_requirements |  execution requirements for the action, we recommend using local as BuildX wants to read files outside of the sandbox.   |  `{"local": "1"}` |
| <a id="buildx-builder_name"></a>builder_name |  name of the builder to use. <https://docs.docker.com/reference/cli/docker/buildx/build/#builder>   |  `"rules_buildx_builder"` |
| <a id="buildx-tags"></a>tags |  tags for the target   |  `["manual"]` |
| <a id="buildx-visibility"></a>visibility |  visibility for the target   |  `[]` |

<a id="context.oci_layout"></a>

## context.oci_layout

<pre>
context.oci_layout(<a href="#context.oci_layout-replace">replace</a>, <a href="#context.oci_layout-layout">layout</a>)
</pre>

**PARAMETERS**

| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="context.oci_layout-replace"></a>replace |  <p align="center"> - </p>   |  none |
| <a id="context.oci_layout-layout"></a>layout |  <p align="center"> - </p>   |  none |

<a id="context.sources"></a>

## context.sources

<pre>
context.sources(<a href="#context.sources-replace">replace</a>, <a href="#context.sources-sources">sources</a>, <a href="#context.sources-override_path">override_path</a>)
</pre>

**PARAMETERS**

| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="context.sources-replace"></a>replace |  <p align="center"> - </p>   |  none |
| <a id="context.sources-sources"></a>sources |  <p align="center"> - </p>   |  none |
| <a id="context.sources-override_path"></a>override_path |  <p align="center"> - </p>   |  none |
