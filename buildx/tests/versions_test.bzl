"""Unit tests for starlark helpers
See https://bazel.build/rules/testing#testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//buildx/private:versions.bzl", "BUILDX_VERSIONS", "DEFAULT_BUILDX_VERSION", "latest_version")

def _default_version_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, DEFAULT_BUILDX_VERSION in BUILDX_VERSIONS)
    return unittest.end(env)

def _latest_version_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "0.28.0", latest_version(["0.28.0"]))

    # Numeric, not lexicographic, comparison.
    asserts.equals(env, "0.28.0", latest_version(["0.9.0", "0.28.0", "0.10.1"]))
    asserts.equals(env, "1.0.0", latest_version(["0.99.99", "1.0.0"]))

    # A release is newer than its prereleases.
    asserts.equals(env, "0.29.0", latest_version(["0.29.0", "0.29.0-rc1"]))
    asserts.equals(env, "0.29.0-rc2", latest_version(["0.29.0-rc1", "0.29.0-rc2", "0.28.0"]))
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_t0_test = unittest.make(_default_version_test_impl)
_t1_test = unittest.make(_latest_version_test_impl)

def versions_test_suite(name):
    unittest.suite(name, _t0_test, _t1_test)
