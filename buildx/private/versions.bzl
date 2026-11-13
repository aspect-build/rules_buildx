"""Mirror of release info

TODO: generate this file from GitHub API"""

# The sha256 hashes can be computed with
# shasum -a 256 [downloaded file] | awk '{ print $1 }'

BUILDX_VERSIONS = {
    "0.28.0": {
        "darwin-amd64": "833291f48e2dded5ad98770811894a693a83a6618dbd30a31c0f7012988f2b3b",
        "darwin-arm64": "0165087b0726d73541d9bdcc29f322de6e5c8bf0d7365a0a77cb0060055f2ae4",
        "linux-amd64": "696bc104bac3bb708eff1af3f8bbc09fda0fd88f5757c1f9b404a35117889224",
        "linux-arm64": "4e850583cc68ffd8d739ddb8a782b83f2ef9d3bf437ae7c44da4fbfde2613a8e",
        "windows-amd64": "0e8d520269cbd3401de6fee5c5fe48d5a9750805aa0a04d5443eba6b33ba63ee",
        "windows-arm64": "a110ebbf2379bcfbf72d533c283a133a44ffed14090279494ea74290291567d6",
    },
}

DEFAULT_BUILDX_VERSION = "0.28.0"

def _version_key(version):
    """Sort key ordering buildx versions like `1.2.3` and `1.2.3-rc1` by semver precedence."""
    core, _, prerelease = version.partition("-")
    parts = core.split(".")
    for part in parts:
        if not part.isdigit():
            fail("Invalid buildx version `{}`: expected MAJOR.MINOR.PATCH".format(version))

    # A release sorts after its prereleases.
    return [int(part) for part in parts] + [0 if prerelease else 1, prerelease]

def latest_version(versions):
    """Returns the highest of the given buildx versions.

    Args:
        versions: non-empty list of version strings like `0.28.0`.

    Returns:
        The highest version.
    """
    return sorted(versions, key = _version_key)[-1]
