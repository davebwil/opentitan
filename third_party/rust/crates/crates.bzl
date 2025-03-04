"""
@generated
cargo-raze generated Bazel file.

DO NOT EDIT! Replaced on runs of cargo-raze
"""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")  # buildifier: disable=load
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")  # buildifier: disable=load
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")  # buildifier: disable=load

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of normal dependencies for the Rust targets of that package.
_DEPENDENCIES = {
    "third_party/rust/crates": {
        "anyhow": "@raze__anyhow__1_0_58//:anyhow",
        "bitflags": "@raze__bitflags__1_3_2//:bitflags",
        "byteorder": "@raze__byteorder__1_4_3//:byteorder",
        "deser-hjson": "@raze__deser_hjson__1_0_2//:deser_hjson",
        "directories": "@raze__directories__4_0_1//:directories",
        "env_logger": "@raze__env_logger__0_8_4//:env_logger",
        "erased-serde": "@raze__erased_serde__0_3_21//:erased_serde",
        "hex": "@raze__hex__0_4_3//:hex",
        "humantime": "@raze__humantime__2_1_0//:humantime",
        "indicatif": "@raze__indicatif__0_16_2//:indicatif",
        "lazy_static": "@raze__lazy_static__1_4_0//:lazy_static",
        "log": "@raze__log__0_4_17//:log",
        "memoffset": "@raze__memoffset__0_6_5//:memoffset",
        "mio": "@raze__mio__0_7_14//:mio",
        "mio-signals": "@raze__mio_signals__0_1_5//:mio_signals",
        "nix": "@raze__nix__0_17_0//:nix",
        "num-bigint-dig": "@raze__num_bigint_dig__0_7_0//:num_bigint_dig",
        "num-traits": "@raze__num_traits__0_2_15//:num_traits",
        "num_enum": "@raze__num_enum__0_5_7//:num_enum",
        "object": "@raze__object__0_25_3//:object",
        "proc-macro-error": "@raze__proc_macro_error__1_0_4//:proc_macro_error",
        "proc-macro2": "@raze__proc_macro2__1_0_40//:proc_macro2",
        "quote": "@raze__quote__1_0_20//:quote",
        "rand": "@raze__rand__0_8_5//:rand",
        "raw_tty": "@raze__raw_tty__0_1_0//:raw_tty",
        "regex": "@raze__regex__1_6_0//:regex",
        "rsa": "@raze__rsa__0_5_0//:rsa",
        "rusb": "@raze__rusb__0_8_1//:rusb",
        "serde": "@raze__serde__1_0_139//:serde",
        "serde_json": "@raze__serde_json__1_0_82//:serde_json",
        "serialport": "@raze__serialport__4_2_0//:serialport",
        "sha2": "@raze__sha2__0_10_2//:sha2",
        "shellwords": "@raze__shellwords__1_1_0//:shellwords",
        "structopt": "@raze__structopt__0_3_26//:structopt",
        "syn": "@raze__syn__1_0_98//:syn",
        "tempfile": "@raze__tempfile__3_3_0//:tempfile",
        "thiserror": "@raze__thiserror__1_0_31//:thiserror",
        "typetag": "@raze__typetag__0_1_8//:typetag",
        "zerocopy": "@raze__zerocopy__0_5_0//:zerocopy",
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of proc_macro dependencies for the Rust targets of that package.
_PROC_MACRO_DEPENDENCIES = {
    "third_party/rust/crates": {
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of normal dev dependencies for the Rust targets of that package.
_DEV_DEPENDENCIES = {
    "third_party/rust/crates": {
    },
}

# EXPERIMENTAL -- MAY CHANGE AT ANY TIME: A mapping of package names to a set of proc_macro dev dependencies for the Rust targets of that package.
_DEV_PROC_MACRO_DEPENDENCIES = {
    "third_party/rust/crates": {
    },
}

def crate_deps(deps, package_name = None):
    """EXPERIMENTAL -- MAY CHANGE AT ANY TIME: Finds the fully qualified label of the requested crates for the package where this macro is called.

    WARNING: This macro is part of an expeirmental API and is subject to change.

    Args:
        deps (list): The desired list of crate targets.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.
    Returns:
        list: A list of labels to cargo-raze generated targets (str)
    """

    if not package_name:
        package_name = native.package_name()

    # Join both sets of dependencies
    dependencies = _flatten_dependency_maps([
        _DEPENDENCIES,
        _PROC_MACRO_DEPENDENCIES,
        _DEV_DEPENDENCIES,
        _DEV_PROC_MACRO_DEPENDENCIES,
    ])

    if not deps:
        return []

    missing_crates = []
    crate_targets = []
    for crate_target in deps:
        if crate_target not in dependencies[package_name]:
            missing_crates.append(crate_target)
        else:
            crate_targets.append(dependencies[package_name][crate_target])

    if missing_crates:
        fail("Could not find crates `{}` among dependencies of `{}`. Available dependencies were `{}`".format(
            missing_crates,
            package_name,
            dependencies[package_name],
        ))

    return crate_targets

def all_crate_deps(normal = False, normal_dev = False, proc_macro = False, proc_macro_dev = False, package_name = None):
    """EXPERIMENTAL -- MAY CHANGE AT ANY TIME: Finds the fully qualified label of all requested direct crate dependencies \
    for the package where this macro is called.

    If no parameters are set, all normal dependencies are returned. Setting any one flag will
    otherwise impact the contents of the returned list.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list. Defaults to False.
        normal_dev (bool, optional): If True, normla dev dependencies will be
            included in the output list. Defaults to False.
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list. Defaults to False.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list. Defaults to False.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.

    Returns:
        list: A list of labels to cargo-raze generated targets (str)
    """

    if not package_name:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_dependency_maps = []
    if normal:
        all_dependency_maps.append(_DEPENDENCIES)
    if normal_dev:
        all_dependency_maps.append(_DEV_DEPENDENCIES)
    if proc_macro:
        all_dependency_maps.append(_PROC_MACRO_DEPENDENCIES)
    if proc_macro_dev:
        all_dependency_maps.append(_DEV_PROC_MACRO_DEPENDENCIES)

    # Default to always using normal dependencies
    if not all_dependency_maps:
        all_dependency_maps.append(_DEPENDENCIES)

    dependencies = _flatten_dependency_maps(all_dependency_maps)

    if not dependencies:
        return []

    return dependencies[package_name].values()

def _flatten_dependency_maps(all_dependency_maps):
    """Flatten a list of dependency maps into one dictionary.

    Dependency maps have the following structure:

    ```python
    DEPENDENCIES_MAP = {
        # The first key in the map is a Bazel package
        # name of the workspace this file is defined in.
        "package_name": {

            # An alias to a crate target.     # The label of the crate target the
            # Aliases are only crate names.   # alias refers to.
            "alias":                          "@full//:label",
        }
    }
    ```

    Args:
        all_dependency_maps (list): A list of dicts as described above

    Returns:
        dict: A dictionary as described above
    """
    dependencies = {}

    for dep_map in all_dependency_maps:
        for pkg_name in dep_map:
            if pkg_name not in dependencies:
                # Add a non-frozen dict to the collection of dependencies
                dependencies.setdefault(pkg_name, dict(dep_map[pkg_name].items()))
                continue

            duplicate_crate_aliases = [key for key in dependencies[pkg_name] if key in dep_map[pkg_name]]
            if duplicate_crate_aliases:
                fail("There should be no duplicate crate aliases: {}".format(duplicate_crate_aliases))

            dependencies[pkg_name].update(dep_map[pkg_name])

    return dependencies

def raze_fetch_remote_crates():
    """This function defines a collection of repos and should be called in a WORKSPACE file"""
    maybe(
        http_archive,
        name = "raze__CoreFoundation_sys__0_1_4",
        url = "https://crates.io/api/v1/crates/CoreFoundation-sys/0.1.4/download",
        type = "tar.gz",
        sha256 = "d0e9889e6db118d49d88d84728d0e964d973a5680befb5f85f55141beea5c20b",
        strip_prefix = "CoreFoundation-sys-0.1.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.CoreFoundation-sys-0.1.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__IOKit_sys__0_1_5",
        url = "https://crates.io/api/v1/crates/IOKit-sys/0.1.5/download",
        type = "tar.gz",
        sha256 = "99696c398cbaf669d2368076bdb3d627fb0ce51a26899d7c61228c5c0af3bf4a",
        strip_prefix = "IOKit-sys-0.1.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.IOKit-sys-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__addr2line__0_17_0",
        url = "https://crates.io/api/v1/crates/addr2line/0.17.0/download",
        type = "tar.gz",
        sha256 = "b9ecd88a8c8378ca913a680cd98f0f13ac67383d35993f86c90a70e3f137816b",
        strip_prefix = "addr2line-0.17.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.addr2line-0.17.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__adler__1_0_2",
        url = "https://crates.io/api/v1/crates/adler/1.0.2/download",
        type = "tar.gz",
        sha256 = "f26201604c87b1e01bd3d98f8d5d9a8fcbb815e8cedb41ffccbeb4bf593a35fe",
        strip_prefix = "adler-1.0.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.adler-1.0.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__aho_corasick__0_7_18",
        url = "https://crates.io/api/v1/crates/aho-corasick/0.7.18/download",
        type = "tar.gz",
        sha256 = "1e37cfd5e7657ada45f742d6e99ca5788580b5c529dc78faf11ece6dc702656f",
        strip_prefix = "aho-corasick-0.7.18",
        build_file = Label("//third_party/rust/crates/remote:BUILD.aho-corasick-0.7.18.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ansi_term__0_12_1",
        url = "https://crates.io/api/v1/crates/ansi_term/0.12.1/download",
        type = "tar.gz",
        sha256 = "d52a9bb7ec0cf484c551830a7ce27bd20d67eac647e1befb56b0be4ee39a55d2",
        strip_prefix = "ansi_term-0.12.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ansi_term-0.12.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__anyhow__1_0_58",
        url = "https://crates.io/api/v1/crates/anyhow/1.0.58/download",
        type = "tar.gz",
        sha256 = "bb07d2053ccdbe10e2af2995a2f116c1330396493dc1269f6a91d0ae82e19704",
        strip_prefix = "anyhow-1.0.58",
        build_file = Label("//third_party/rust/crates/remote:BUILD.anyhow-1.0.58.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__atty__0_2_14",
        url = "https://crates.io/api/v1/crates/atty/0.2.14/download",
        type = "tar.gz",
        sha256 = "d9b39be18770d11421cdb1b9947a45dd3f37e93092cbf377614828a319d5fee8",
        strip_prefix = "atty-0.2.14",
        build_file = Label("//third_party/rust/crates/remote:BUILD.atty-0.2.14.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__autocfg__0_1_8",
        url = "https://crates.io/api/v1/crates/autocfg/0.1.8/download",
        type = "tar.gz",
        sha256 = "0dde43e75fd43e8a1bf86103336bc699aa8d17ad1be60c76c0bdfd4828e19b78",
        strip_prefix = "autocfg-0.1.8",
        build_file = Label("//third_party/rust/crates/remote:BUILD.autocfg-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__autocfg__1_1_0",
        url = "https://crates.io/api/v1/crates/autocfg/1.1.0/download",
        type = "tar.gz",
        sha256 = "d468802bab17cbc0cc575e9b053f41e72aa36bfa6b7f55e3529ffa43161b97fa",
        strip_prefix = "autocfg-1.1.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.autocfg-1.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__backtrace__0_3_66",
        url = "https://crates.io/api/v1/crates/backtrace/0.3.66/download",
        type = "tar.gz",
        sha256 = "cab84319d616cfb654d03394f38ab7e6f0919e181b1b57e1fd15e7fb4077d9a7",
        strip_prefix = "backtrace-0.3.66",
        build_file = Label("//third_party/rust/crates/remote:BUILD.backtrace-0.3.66.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__base64ct__1_1_1",
        url = "https://crates.io/api/v1/crates/base64ct/1.1.1/download",
        type = "tar.gz",
        sha256 = "e6b4d9b1225d28d360ec6a231d65af1fd99a2a095154c8040689617290569c5c",
        strip_prefix = "base64ct-1.1.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.base64ct-1.1.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__bitflags__1_3_2",
        url = "https://crates.io/api/v1/crates/bitflags/1.3.2/download",
        type = "tar.gz",
        sha256 = "bef38d45163c2f1dde094a7dfd33ccf595c92905c8f8f4fdc18d06fb1037718a",
        strip_prefix = "bitflags-1.3.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.bitflags-1.3.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__block_buffer__0_10_2",
        url = "https://crates.io/api/v1/crates/block-buffer/0.10.2/download",
        type = "tar.gz",
        sha256 = "0bf7fe51849ea569fd452f37822f606a5cabb684dc918707a0193fd4664ff324",
        strip_prefix = "block-buffer-0.10.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.block-buffer-0.10.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__byteorder__1_4_3",
        url = "https://crates.io/api/v1/crates/byteorder/1.4.3/download",
        type = "tar.gz",
        sha256 = "14c189c53d098945499cdfa7ecc63567cf3886b3332b312a5b4585d8d3a6a610",
        strip_prefix = "byteorder-1.4.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.byteorder-1.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cc__1_0_73",
        url = "https://crates.io/api/v1/crates/cc/1.0.73/download",
        type = "tar.gz",
        sha256 = "2fff2a6927b3bb87f9595d67196a70493f627687a71d87a0d692242c33f58c11",
        strip_prefix = "cc-1.0.73",
        build_file = Label("//third_party/rust/crates/remote:BUILD.cc-1.0.73.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cfg_if__0_1_10",
        url = "https://crates.io/api/v1/crates/cfg-if/0.1.10/download",
        type = "tar.gz",
        sha256 = "4785bdd1c96b2a846b2bd7cc02e86b6b3dbf14e7e53446c4f54c92a361040822",
        strip_prefix = "cfg-if-0.1.10",
        build_file = Label("//third_party/rust/crates/remote:BUILD.cfg-if-0.1.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cfg_if__1_0_0",
        url = "https://crates.io/api/v1/crates/cfg-if/1.0.0/download",
        type = "tar.gz",
        sha256 = "baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd",
        strip_prefix = "cfg-if-1.0.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.cfg-if-1.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__clap__2_34_0",
        url = "https://crates.io/api/v1/crates/clap/2.34.0/download",
        type = "tar.gz",
        sha256 = "a0610544180c38b88101fecf2dd634b174a62eef6946f84dfc6a7127512b381c",
        strip_prefix = "clap-2.34.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.clap-2.34.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__console__0_15_0",
        url = "https://crates.io/api/v1/crates/console/0.15.0/download",
        type = "tar.gz",
        sha256 = "a28b32d32ca44b70c3e4acd7db1babf555fa026e385fb95f18028f88848b3c31",
        strip_prefix = "console-0.15.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.console-0.15.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__const_oid__0_6_2",
        url = "https://crates.io/api/v1/crates/const-oid/0.6.2/download",
        type = "tar.gz",
        sha256 = "9d6f2aa4d0537bcc1c74df8755072bd31c1ef1a3a1b85a68e8404a8c353b7b8b",
        strip_prefix = "const-oid-0.6.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.const-oid-0.6.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__cpufeatures__0_2_2",
        url = "https://crates.io/api/v1/crates/cpufeatures/0.2.2/download",
        type = "tar.gz",
        sha256 = "59a6001667ab124aebae2a495118e11d30984c3a653e99d86d58971708cf5e4b",
        strip_prefix = "cpufeatures-0.2.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.cpufeatures-0.2.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__crc32fast__1_3_2",
        url = "https://crates.io/api/v1/crates/crc32fast/1.3.2/download",
        type = "tar.gz",
        sha256 = "b540bd8bc810d3885c6ea91e2018302f68baba2129ab3e88f32389ee9370880d",
        strip_prefix = "crc32fast-1.3.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.crc32fast-1.3.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__crypto_bigint__0_2_11",
        url = "https://crates.io/api/v1/crates/crypto-bigint/0.2.11/download",
        type = "tar.gz",
        sha256 = "f83bd3bb4314701c568e340cd8cf78c975aa0ca79e03d3f6d1677d5b0c9c0c03",
        strip_prefix = "crypto-bigint-0.2.11",
        build_file = Label("//third_party/rust/crates/remote:BUILD.crypto-bigint-0.2.11.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__crypto_common__0_1_5",
        url = "https://crates.io/api/v1/crates/crypto-common/0.1.5/download",
        type = "tar.gz",
        sha256 = "2ccfd8c0ee4cce11e45b3fd6f9d5e69e0cc62912aa6a0cb1bf4617b0eba5a12f",
        strip_prefix = "crypto-common-0.1.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.crypto-common-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ctor__0_1_22",
        url = "https://crates.io/api/v1/crates/ctor/0.1.22/download",
        type = "tar.gz",
        sha256 = "f877be4f7c9f246b183111634f75baa039715e3f46ce860677d3b19a69fb229c",
        strip_prefix = "ctor-0.1.22",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ctor-0.1.22.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__der__0_4_5",
        url = "https://crates.io/api/v1/crates/der/0.4.5/download",
        type = "tar.gz",
        sha256 = "79b71cca7d95d7681a4b3b9cdf63c8dbc3730d0584c2c74e31416d64a90493f4",
        strip_prefix = "der-0.4.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.der-0.4.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__derive_more__0_14_1",
        url = "https://crates.io/api/v1/crates/derive_more/0.14.1/download",
        type = "tar.gz",
        sha256 = "6d944ac6003ed268757ef1ee686753b57efc5fcf0ebe7b64c9fc81e7e32ff839",
        strip_prefix = "derive_more-0.14.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.derive_more-0.14.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__deser_hjson__1_0_2",
        url = "https://crates.io/api/v1/crates/deser-hjson/1.0.2/download",
        type = "tar.gz",
        sha256 = "1f486ff51f3ecdf9364736375a4b358b6eb9f02555d5324fa4837c00b5aa23f5",
        strip_prefix = "deser-hjson-1.0.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.deser-hjson-1.0.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__digest__0_10_3",
        url = "https://crates.io/api/v1/crates/digest/0.10.3/download",
        type = "tar.gz",
        sha256 = "f2fb860ca6fafa5552fb6d0e816a69c8e49f0908bf524e30a90d97c85892d506",
        strip_prefix = "digest-0.10.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.digest-0.10.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__digest__0_9_0",
        url = "https://crates.io/api/v1/crates/digest/0.9.0/download",
        type = "tar.gz",
        sha256 = "d3dd60d1080a57a05ab032377049e0591415d2b31afd7028356dbf3cc6dcb066",
        strip_prefix = "digest-0.9.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.digest-0.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__directories__4_0_1",
        url = "https://crates.io/api/v1/crates/directories/4.0.1/download",
        type = "tar.gz",
        sha256 = "f51c5d4ddabd36886dd3e1438cb358cdcb0d7c499cb99cb4ac2e38e18b5cb210",
        strip_prefix = "directories-4.0.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.directories-4.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__dirs_sys__0_3_7",
        url = "https://crates.io/api/v1/crates/dirs-sys/0.3.7/download",
        type = "tar.gz",
        sha256 = "1b1d1d91c932ef41c0f2663aa8b0ca0342d444d842c06914aa0a7e352d0bada6",
        strip_prefix = "dirs-sys-0.3.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.dirs-sys-0.3.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__encode_unicode__0_3_6",
        url = "https://crates.io/api/v1/crates/encode_unicode/0.3.6/download",
        type = "tar.gz",
        sha256 = "a357d28ed41a50f9c765dbfe56cbc04a64e53e5fc58ba79fbc34c10ef3df831f",
        strip_prefix = "encode_unicode-0.3.6",
        build_file = Label("//third_party/rust/crates/remote:BUILD.encode_unicode-0.3.6.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__env_logger__0_8_4",
        url = "https://crates.io/api/v1/crates/env_logger/0.8.4/download",
        type = "tar.gz",
        sha256 = "a19187fea3ac7e84da7dacf48de0c45d63c6a76f9490dae389aead16c243fce3",
        strip_prefix = "env_logger-0.8.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.env_logger-0.8.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__erased_serde__0_3_21",
        url = "https://crates.io/api/v1/crates/erased-serde/0.3.21/download",
        type = "tar.gz",
        sha256 = "81d013529d5574a60caeda29e179e695125448e5de52e3874f7b4c1d7360e18e",
        strip_prefix = "erased-serde-0.3.21",
        build_file = Label("//third_party/rust/crates/remote:BUILD.erased-serde-0.3.21.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__fastrand__1_7_0",
        url = "https://crates.io/api/v1/crates/fastrand/1.7.0/download",
        type = "tar.gz",
        sha256 = "c3fcf0cee53519c866c09b5de1f6c56ff9d647101f81c1964fa632e148896cdf",
        strip_prefix = "fastrand-1.7.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.fastrand-1.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__flate2__1_0_24",
        url = "https://crates.io/api/v1/crates/flate2/1.0.24/download",
        type = "tar.gz",
        sha256 = "f82b0f4c27ad9f8bfd1f3208d882da2b09c301bc1c828fd3a00d0216d2fbbff6",
        strip_prefix = "flate2-1.0.24",
        build_file = Label("//third_party/rust/crates/remote:BUILD.flate2-1.0.24.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__generic_array__0_14_5",
        url = "https://crates.io/api/v1/crates/generic-array/0.14.5/download",
        type = "tar.gz",
        sha256 = "fd48d33ec7f05fbfa152300fdad764757cbded343c1aa1cff2fbaf4134851803",
        strip_prefix = "generic-array-0.14.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.generic-array-0.14.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__getrandom__0_2_7",
        url = "https://crates.io/api/v1/crates/getrandom/0.2.7/download",
        type = "tar.gz",
        sha256 = "4eb1a864a501629691edf6c15a593b7a51eebaa1e8468e9ddc623de7c9b58ec6",
        strip_prefix = "getrandom-0.2.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.getrandom-0.2.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ghost__0_1_5",
        url = "https://crates.io/api/v1/crates/ghost/0.1.5/download",
        type = "tar.gz",
        sha256 = "b93490550b1782c589a350f2211fff2e34682e25fed17ef53fc4fa8fe184975e",
        strip_prefix = "ghost-0.1.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ghost-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__gimli__0_26_1",
        url = "https://crates.io/api/v1/crates/gimli/0.26.1/download",
        type = "tar.gz",
        sha256 = "78cc372d058dcf6d5ecd98510e7fbc9e5aec4d21de70f65fea8fecebcd881bd4",
        strip_prefix = "gimli-0.26.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.gimli-0.26.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__heck__0_3_3",
        url = "https://crates.io/api/v1/crates/heck/0.3.3/download",
        type = "tar.gz",
        sha256 = "6d621efb26863f0e9924c6ac577e8275e5e6b77455db64ffa6c65c904e9e132c",
        strip_prefix = "heck-0.3.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.heck-0.3.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hermit_abi__0_1_19",
        url = "https://crates.io/api/v1/crates/hermit-abi/0.1.19/download",
        type = "tar.gz",
        sha256 = "62b467343b94ba476dcb2500d242dadbb39557df889310ac77c5d99100aaac33",
        strip_prefix = "hermit-abi-0.1.19",
        build_file = Label("//third_party/rust/crates/remote:BUILD.hermit-abi-0.1.19.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__hex__0_4_3",
        url = "https://crates.io/api/v1/crates/hex/0.4.3/download",
        type = "tar.gz",
        sha256 = "7f24254aa9a54b5c858eaee2f5bccdb46aaf0e486a595ed5fd8f86ba55232a70",
        strip_prefix = "hex-0.4.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.hex-0.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__humantime__2_1_0",
        url = "https://crates.io/api/v1/crates/humantime/2.1.0/download",
        type = "tar.gz",
        sha256 = "9a3a5bfb195931eeb336b2a7b4d761daec841b97f947d34394601737a7bba5e4",
        strip_prefix = "humantime-2.1.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.humantime-2.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__indicatif__0_16_2",
        url = "https://crates.io/api/v1/crates/indicatif/0.16.2/download",
        type = "tar.gz",
        sha256 = "2d207dc617c7a380ab07ff572a6e52fa202a2a8f355860ac9c38e23f8196be1b",
        strip_prefix = "indicatif-0.16.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.indicatif-0.16.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__instant__0_1_12",
        url = "https://crates.io/api/v1/crates/instant/0.1.12/download",
        type = "tar.gz",
        sha256 = "7a5bbe824c507c5da5956355e86a746d82e0e1464f65d862cc5e71da70e94b2c",
        strip_prefix = "instant-0.1.12",
        build_file = Label("//third_party/rust/crates/remote:BUILD.instant-0.1.12.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__inventory__0_2_3",
        url = "https://crates.io/api/v1/crates/inventory/0.2.3/download",
        type = "tar.gz",
        sha256 = "84344c6e0b90a9e2b6f3f9abe5cc74402684e348df7b32adca28747e0cef091a",
        strip_prefix = "inventory-0.2.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.inventory-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__itoa__1_0_2",
        url = "https://crates.io/api/v1/crates/itoa/1.0.2/download",
        type = "tar.gz",
        sha256 = "112c678d4050afce233f4f2852bb2eb519230b3cf12f33585275537d7e41578d",
        strip_prefix = "itoa-1.0.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.itoa-1.0.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__lazy_static__1_4_0",
        url = "https://crates.io/api/v1/crates/lazy_static/1.4.0/download",
        type = "tar.gz",
        sha256 = "e2abad23fbc42b3700f2f279844dc832adb2b2eb069b2df918f455c4e18cc646",
        strip_prefix = "lazy_static-1.4.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.lazy_static-1.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libc__0_2_126",
        url = "https://crates.io/api/v1/crates/libc/0.2.126/download",
        type = "tar.gz",
        sha256 = "349d5a591cd28b49e1d1037471617a32ddcda5731b99419008085f72d5a53836",
        strip_prefix = "libc-0.2.126",
        build_file = Label("//third_party/rust/crates/remote:BUILD.libc-0.2.126.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libm__0_2_2",
        url = "https://crates.io/api/v1/crates/libm/0.2.2/download",
        type = "tar.gz",
        sha256 = "33a33a362ce288760ec6a508b94caaec573ae7d3bbbd91b87aa0bad4456839db",
        strip_prefix = "libm-0.2.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.libm-0.2.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libudev__0_3_0",
        url = "https://crates.io/api/v1/crates/libudev/0.3.0/download",
        type = "tar.gz",
        sha256 = "78b324152da65df7bb95acfcaab55e3097ceaab02fb19b228a9eb74d55f135e0",
        strip_prefix = "libudev-0.3.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.libudev-0.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libudev_sys__0_1_4",
        url = "https://crates.io/api/v1/crates/libudev-sys/0.1.4/download",
        type = "tar.gz",
        sha256 = "3c8469b4a23b962c1396b9b451dda50ef5b283e8dd309d69033475fa9b334324",
        strip_prefix = "libudev-sys-0.1.4",
        patches = [
            "@//third_party/rust/crates/patches:libudev-sys-0.1.4.patch",
        ],
        patch_args = [
            "-p1",
        ],
        build_file = Label("//third_party/rust/crates/remote:BUILD.libudev-sys-0.1.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__libusb1_sys__0_5_0",
        url = "https://crates.io/api/v1/crates/libusb1-sys/0.5.0/download",
        type = "tar.gz",
        sha256 = "e22e89d08bbe6816c6c5d446203b859eba35b8fa94bf1b7edb2f6d25d43f023f",
        strip_prefix = "libusb1-sys-0.5.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.libusb1-sys-0.5.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__log__0_4_17",
        url = "https://crates.io/api/v1/crates/log/0.4.17/download",
        type = "tar.gz",
        sha256 = "abb12e687cfb44aa40f41fc3978ef76448f9b6038cad6aef4259d3c095a2382e",
        strip_prefix = "log-0.4.17",
        build_file = Label("//third_party/rust/crates/remote:BUILD.log-0.4.17.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mach__0_1_2",
        url = "https://crates.io/api/v1/crates/mach/0.1.2/download",
        type = "tar.gz",
        sha256 = "2fd13ee2dd61cc82833ba05ade5a30bb3d63f7ced605ef827063c63078302de9",
        strip_prefix = "mach-0.1.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.mach-0.1.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mach__0_3_2",
        url = "https://crates.io/api/v1/crates/mach/0.3.2/download",
        type = "tar.gz",
        sha256 = "b823e83b2affd8f40a9ee8c29dbc56404c1e34cd2710921f2801e2cf29527afa",
        strip_prefix = "mach-0.3.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.mach-0.3.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__memchr__2_5_0",
        url = "https://crates.io/api/v1/crates/memchr/2.5.0/download",
        type = "tar.gz",
        sha256 = "2dffe52ecf27772e601905b7522cb4ef790d2cc203488bbd0e2fe85fcb74566d",
        strip_prefix = "memchr-2.5.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.memchr-2.5.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__memoffset__0_6_5",
        url = "https://crates.io/api/v1/crates/memoffset/0.6.5/download",
        type = "tar.gz",
        sha256 = "5aa361d4faea93603064a027415f07bd8e1d5c88c9fbf68bf56a285428fd79ce",
        strip_prefix = "memoffset-0.6.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.memoffset-0.6.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__miniz_oxide__0_5_3",
        url = "https://crates.io/api/v1/crates/miniz_oxide/0.5.3/download",
        type = "tar.gz",
        sha256 = "6f5c75688da582b8ffc1f1799e9db273f32133c49e048f614d22ec3256773ccc",
        strip_prefix = "miniz_oxide-0.5.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.miniz_oxide-0.5.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mio__0_7_14",
        url = "https://crates.io/api/v1/crates/mio/0.7.14/download",
        type = "tar.gz",
        sha256 = "8067b404fe97c70829f082dec8bcf4f71225d7eaea1d8645349cb76fa06205cc",
        strip_prefix = "mio-0.7.14",
        build_file = Label("//third_party/rust/crates/remote:BUILD.mio-0.7.14.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__mio_signals__0_1_5",
        url = "https://crates.io/api/v1/crates/mio-signals/0.1.5/download",
        type = "tar.gz",
        sha256 = "119701964987706f4147cff32b09ae64019be6417a90fda6f96cfac0348e8b79",
        strip_prefix = "mio-signals-0.1.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.mio-signals-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__miow__0_3_7",
        url = "https://crates.io/api/v1/crates/miow/0.3.7/download",
        type = "tar.gz",
        sha256 = "b9f1c5b025cda876f66ef43a113f91ebc9f4ccef34843000e0adf6ebbab84e21",
        strip_prefix = "miow-0.3.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.miow-0.3.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__nix__0_17_0",
        url = "https://crates.io/api/v1/crates/nix/0.17.0/download",
        type = "tar.gz",
        sha256 = "50e4785f2c3b7589a0d0c1dd60285e1188adac4006e8abd6dd578e1567027363",
        strip_prefix = "nix-0.17.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.nix-0.17.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__nix__0_24_1",
        url = "https://crates.io/api/v1/crates/nix/0.24.1/download",
        type = "tar.gz",
        sha256 = "8f17df307904acd05aa8e32e97bb20f2a0df1728bbc2d771ae8f9a90463441e9",
        strip_prefix = "nix-0.24.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.nix-0.24.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ntapi__0_3_7",
        url = "https://crates.io/api/v1/crates/ntapi/0.3.7/download",
        type = "tar.gz",
        sha256 = "c28774a7fd2fbb4f0babd8237ce554b73af68021b5f695a3cebd6c59bac0980f",
        strip_prefix = "ntapi-0.3.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ntapi-0.3.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_bigint_dig__0_7_0",
        url = "https://crates.io/api/v1/crates/num-bigint-dig/0.7.0/download",
        type = "tar.gz",
        sha256 = "4547ee5541c18742396ae2c895d0717d0f886d8823b8399cdaf7b07d63ad0480",
        strip_prefix = "num-bigint-dig-0.7.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num-bigint-dig-0.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_integer__0_1_45",
        url = "https://crates.io/api/v1/crates/num-integer/0.1.45/download",
        type = "tar.gz",
        sha256 = "225d3389fb3509a24c93f5c29eb6bde2586b98d9f016636dff58d7c6f7569cd9",
        strip_prefix = "num-integer-0.1.45",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num-integer-0.1.45.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_iter__0_1_43",
        url = "https://crates.io/api/v1/crates/num-iter/0.1.43/download",
        type = "tar.gz",
        sha256 = "7d03e6c028c5dc5cac6e2dec0efda81fc887605bb3d884578bb6d6bf7514e252",
        strip_prefix = "num-iter-0.1.43",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num-iter-0.1.43.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_traits__0_2_15",
        url = "https://crates.io/api/v1/crates/num-traits/0.2.15/download",
        type = "tar.gz",
        sha256 = "578ede34cf02f8924ab9447f50c28075b4d3e5b269972345e7e0372b38c6cdcd",
        strip_prefix = "num-traits-0.2.15",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num-traits-0.2.15.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_enum__0_5_7",
        url = "https://crates.io/api/v1/crates/num_enum/0.5.7/download",
        type = "tar.gz",
        sha256 = "cf5395665662ef45796a4ff5486c5d41d29e0c09640af4c5f17fd94ee2c119c9",
        strip_prefix = "num_enum-0.5.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num_enum-0.5.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__num_enum_derive__0_5_7",
        url = "https://crates.io/api/v1/crates/num_enum_derive/0.5.7/download",
        type = "tar.gz",
        sha256 = "3b0498641e53dd6ac1a4f22547548caa6864cc4933784319cd1775271c5a46ce",
        strip_prefix = "num_enum_derive-0.5.7",
        build_file = Label("//third_party/rust/crates/remote:BUILD.num_enum_derive-0.5.7.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__number_prefix__0_4_0",
        url = "https://crates.io/api/v1/crates/number_prefix/0.4.0/download",
        type = "tar.gz",
        sha256 = "830b246a0e5f20af87141b25c173cd1b609bd7779a4617d6ec582abaf90870f3",
        strip_prefix = "number_prefix-0.4.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.number_prefix-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__object__0_25_3",
        url = "https://crates.io/api/v1/crates/object/0.25.3/download",
        type = "tar.gz",
        sha256 = "a38f2be3697a57b4060074ff41b44c16870d916ad7877c17696e063257482bc7",
        strip_prefix = "object-0.25.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.object-0.25.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__object__0_29_0",
        url = "https://crates.io/api/v1/crates/object/0.29.0/download",
        type = "tar.gz",
        sha256 = "21158b2c33aa6d4561f1c0a6ea283ca92bc54802a93b263e910746d679a7eb53",
        strip_prefix = "object-0.29.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.object-0.29.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__once_cell__1_13_0",
        url = "https://crates.io/api/v1/crates/once_cell/1.13.0/download",
        type = "tar.gz",
        sha256 = "18a6dbe30758c9f83eb00cbea4ac95966305f5a7772f3f42ebfc7fc7eddbd8e1",
        strip_prefix = "once_cell-1.13.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.once_cell-1.13.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pem_rfc7468__0_2_4",
        url = "https://crates.io/api/v1/crates/pem-rfc7468/0.2.4/download",
        type = "tar.gz",
        sha256 = "84e93a3b1cc0510b03020f33f21e62acdde3dcaef432edc95bea377fbd4c2cd4",
        strip_prefix = "pem-rfc7468-0.2.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.pem-rfc7468-0.2.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pkcs1__0_2_4",
        url = "https://crates.io/api/v1/crates/pkcs1/0.2.4/download",
        type = "tar.gz",
        sha256 = "116bee8279d783c0cf370efa1a94632f2108e5ef0bb32df31f051647810a4e2c",
        strip_prefix = "pkcs1-0.2.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.pkcs1-0.2.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pkcs8__0_7_6",
        url = "https://crates.io/api/v1/crates/pkcs8/0.7.6/download",
        type = "tar.gz",
        sha256 = "ee3ef9b64d26bad0536099c816c6734379e45bbd5f14798def6809e5cc350447",
        strip_prefix = "pkcs8-0.7.6",
        build_file = Label("//third_party/rust/crates/remote:BUILD.pkcs8-0.7.6.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__pkg_config__0_3_25",
        url = "https://crates.io/api/v1/crates/pkg-config/0.3.25/download",
        type = "tar.gz",
        sha256 = "1df8c4ec4b0627e53bdf214615ad287367e482558cf84b109250b37464dc03ae",
        strip_prefix = "pkg-config-0.3.25",
        build_file = Label("//third_party/rust/crates/remote:BUILD.pkg-config-0.3.25.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ppv_lite86__0_2_16",
        url = "https://crates.io/api/v1/crates/ppv-lite86/0.2.16/download",
        type = "tar.gz",
        sha256 = "eb9f9e6e233e5c4a35559a617bf40a4ec447db2e84c20b55a6f83167b7e57872",
        strip_prefix = "ppv-lite86-0.2.16",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ppv-lite86-0.2.16.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_crate__1_1_3",
        url = "https://crates.io/api/v1/crates/proc-macro-crate/1.1.3/download",
        type = "tar.gz",
        sha256 = "e17d47ce914bf4de440332250b0edd23ce48c005f59fab39d3335866b114f11a",
        strip_prefix = "proc-macro-crate-1.1.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.proc-macro-crate-1.1.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_error__1_0_4",
        url = "https://crates.io/api/v1/crates/proc-macro-error/1.0.4/download",
        type = "tar.gz",
        sha256 = "da25490ff9892aab3fcf7c36f08cfb902dd3e71ca0f9f9517bea02a73a5ce38c",
        strip_prefix = "proc-macro-error-1.0.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.proc-macro-error-1.0.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro_error_attr__1_0_4",
        url = "https://crates.io/api/v1/crates/proc-macro-error-attr/1.0.4/download",
        type = "tar.gz",
        sha256 = "a1be40180e52ecc98ad80b184934baf3d0d29f979574e439af5a55274b35f869",
        strip_prefix = "proc-macro-error-attr-1.0.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.proc-macro-error-attr-1.0.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro2__0_4_30",
        url = "https://crates.io/api/v1/crates/proc-macro2/0.4.30/download",
        type = "tar.gz",
        sha256 = "cf3d2011ab5c909338f7887f4fc896d35932e29146c12c8d01da6b22a80ba759",
        strip_prefix = "proc-macro2-0.4.30",
        build_file = Label("//third_party/rust/crates/remote:BUILD.proc-macro2-0.4.30.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__proc_macro2__1_0_40",
        url = "https://crates.io/api/v1/crates/proc-macro2/1.0.40/download",
        type = "tar.gz",
        sha256 = "dd96a1e8ed2596c337f8eae5f24924ec83f5ad5ab21ea8e455d3566c69fbcaf7",
        strip_prefix = "proc-macro2-1.0.40",
        build_file = Label("//third_party/rust/crates/remote:BUILD.proc-macro2-1.0.40.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__quote__0_6_13",
        url = "https://crates.io/api/v1/crates/quote/0.6.13/download",
        type = "tar.gz",
        sha256 = "6ce23b6b870e8f94f81fb0a363d65d86675884b34a09043c81e5562f11c1f8e1",
        strip_prefix = "quote-0.6.13",
        build_file = Label("//third_party/rust/crates/remote:BUILD.quote-0.6.13.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__quote__1_0_20",
        url = "https://crates.io/api/v1/crates/quote/1.0.20/download",
        type = "tar.gz",
        sha256 = "3bcdf212e9776fbcb2d23ab029360416bb1706b1aea2d1a5ba002727cbcab804",
        strip_prefix = "quote-1.0.20",
        build_file = Label("//third_party/rust/crates/remote:BUILD.quote-1.0.20.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand__0_8_5",
        url = "https://crates.io/api/v1/crates/rand/0.8.5/download",
        type = "tar.gz",
        sha256 = "34af8d1a0e25924bc5b7c43c079c942339d8f0a8b57c39049bef581b46327404",
        strip_prefix = "rand-0.8.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rand-0.8.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_chacha__0_3_1",
        url = "https://crates.io/api/v1/crates/rand_chacha/0.3.1/download",
        type = "tar.gz",
        sha256 = "e6c10a63a0fa32252be49d21e7709d4d4baf8d231c2dbce1eaa8141b9b127d88",
        strip_prefix = "rand_chacha-0.3.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rand_chacha-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rand_core__0_6_3",
        url = "https://crates.io/api/v1/crates/rand_core/0.6.3/download",
        type = "tar.gz",
        sha256 = "d34f1408f55294453790c48b2f1ebbb1c5b4b7563eb1f418bcfcfdbb06ebb4e7",
        strip_prefix = "rand_core-0.6.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rand_core-0.6.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__raw_tty__0_1_0",
        url = "https://crates.io/api/v1/crates/raw_tty/0.1.0/download",
        type = "tar.gz",
        sha256 = "51f512d7504049ef0d3f5d48d8aa5129beaea4fccfaf5c500c9b60101394f8b1",
        strip_prefix = "raw_tty-0.1.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.raw_tty-0.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__redox_syscall__0_2_13",
        url = "https://crates.io/api/v1/crates/redox_syscall/0.2.13/download",
        type = "tar.gz",
        sha256 = "62f25bc4c7e55e0b0b7a1d43fb893f4fa1361d0abe38b9ce4f323c2adfe6ef42",
        strip_prefix = "redox_syscall-0.2.13",
        build_file = Label("//third_party/rust/crates/remote:BUILD.redox_syscall-0.2.13.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__redox_users__0_4_3",
        url = "https://crates.io/api/v1/crates/redox_users/0.4.3/download",
        type = "tar.gz",
        sha256 = "b033d837a7cf162d7993aded9304e30a83213c648b6e389db233191f891e5c2b",
        strip_prefix = "redox_users-0.4.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.redox_users-0.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__regex__1_6_0",
        url = "https://crates.io/api/v1/crates/regex/1.6.0/download",
        type = "tar.gz",
        sha256 = "4c4eb3267174b8c6c2f654116623910a0fef09c4753f8dd83db29c48a0df988b",
        strip_prefix = "regex-1.6.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.regex-1.6.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__regex_syntax__0_6_27",
        url = "https://crates.io/api/v1/crates/regex-syntax/0.6.27/download",
        type = "tar.gz",
        sha256 = "a3f87b73ce11b1619a3c6332f45341e0047173771e8b8b73f87bfeefb7b56244",
        strip_prefix = "regex-syntax-0.6.27",
        build_file = Label("//third_party/rust/crates/remote:BUILD.regex-syntax-0.6.27.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__remove_dir_all__0_5_3",
        url = "https://crates.io/api/v1/crates/remove_dir_all/0.5.3/download",
        type = "tar.gz",
        sha256 = "3acd125665422973a33ac9d3dd2df85edad0f4ae9b00dafb1a05e43a9f5ef8e7",
        strip_prefix = "remove_dir_all-0.5.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.remove_dir_all-0.5.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rsa__0_5_0",
        url = "https://crates.io/api/v1/crates/rsa/0.5.0/download",
        type = "tar.gz",
        sha256 = "e05c2603e2823634ab331437001b411b9ed11660fbc4066f3908c84a9439260d",
        strip_prefix = "rsa-0.5.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rsa-0.5.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rusb__0_8_1",
        url = "https://crates.io/api/v1/crates/rusb/0.8.1/download",
        type = "tar.gz",
        sha256 = "d9a5084628cc5be77b1c750b3e5ee0cc519d2f2491b3f06b78b3aac3328b00ad",
        strip_prefix = "rusb-0.8.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rusb-0.8.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rustc_demangle__0_1_21",
        url = "https://crates.io/api/v1/crates/rustc-demangle/0.1.21/download",
        type = "tar.gz",
        sha256 = "7ef03e0a2b150c7a90d01faf6254c9c48a41e95fb2a8c2ac1c6f0d2b9aefc342",
        strip_prefix = "rustc-demangle-0.1.21",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rustc-demangle-0.1.21.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__rustc_version__0_2_3",
        url = "https://crates.io/api/v1/crates/rustc_version/0.2.3/download",
        type = "tar.gz",
        sha256 = "138e3e0acb6c9fb258b19b67cb8abd63c00679d2851805ea151465464fe9030a",
        strip_prefix = "rustc_version-0.2.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.rustc_version-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__ryu__1_0_10",
        url = "https://crates.io/api/v1/crates/ryu/1.0.10/download",
        type = "tar.gz",
        sha256 = "f3f6f92acf49d1b98f7a81226834412ada05458b7364277387724a237f062695",
        strip_prefix = "ryu-1.0.10",
        build_file = Label("//third_party/rust/crates/remote:BUILD.ryu-1.0.10.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__semver__0_9_0",
        url = "https://crates.io/api/v1/crates/semver/0.9.0/download",
        type = "tar.gz",
        sha256 = "1d7eb9ef2c18661902cc47e535f9bc51b78acd254da71d375c2f6720d9a40403",
        strip_prefix = "semver-0.9.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.semver-0.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__semver_parser__0_7_0",
        url = "https://crates.io/api/v1/crates/semver-parser/0.7.0/download",
        type = "tar.gz",
        sha256 = "388a1df253eca08550bef6c72392cfe7c30914bf41df5269b68cbd6ff8f570a3",
        strip_prefix = "semver-parser-0.7.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.semver-parser-0.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde__1_0_139",
        url = "https://crates.io/api/v1/crates/serde/1.0.139/download",
        type = "tar.gz",
        sha256 = "0171ebb889e45aa68b44aee0859b3eede84c6f5f5c228e6f140c0b2a0a46cad6",
        strip_prefix = "serde-1.0.139",
        build_file = Label("//third_party/rust/crates/remote:BUILD.serde-1.0.139.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_derive__1_0_139",
        url = "https://crates.io/api/v1/crates/serde_derive/1.0.139/download",
        type = "tar.gz",
        sha256 = "dc1d3230c1de7932af58ad8ffbe1d784bd55efd5a9d84ac24f69c72d83543dfb",
        strip_prefix = "serde_derive-1.0.139",
        build_file = Label("//third_party/rust/crates/remote:BUILD.serde_derive-1.0.139.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serde_json__1_0_82",
        url = "https://crates.io/api/v1/crates/serde_json/1.0.82/download",
        type = "tar.gz",
        sha256 = "82c2c1fdcd807d1098552c5b9a36e425e42e9fbd7c6a37a8425f390f781f7fa7",
        strip_prefix = "serde_json-1.0.82",
        build_file = Label("//third_party/rust/crates/remote:BUILD.serde_json-1.0.82.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__serialport__4_2_0",
        url = "https://crates.io/api/v1/crates/serialport/4.2.0/download",
        type = "tar.gz",
        sha256 = "aab92efb5cf60ad310548bc3f16fa6b0d950019cb7ed8ff41968c3d03721cf12",
        strip_prefix = "serialport-4.2.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.serialport-4.2.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__sha2__0_10_2",
        url = "https://crates.io/api/v1/crates/sha2/0.10.2/download",
        type = "tar.gz",
        sha256 = "55deaec60f81eefe3cce0dc50bda92d6d8e88f2a27df7c5033b42afeb1ed2676",
        strip_prefix = "sha2-0.10.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.sha2-0.10.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__shellwords__1_1_0",
        url = "https://crates.io/api/v1/crates/shellwords/1.1.0/download",
        type = "tar.gz",
        sha256 = "89e515aa4699a88148ed5ef96413ceef0048ce95b43fbc955a33bde0a70fcae6",
        strip_prefix = "shellwords-1.1.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.shellwords-1.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__smallvec__1_9_0",
        url = "https://crates.io/api/v1/crates/smallvec/1.9.0/download",
        type = "tar.gz",
        sha256 = "2fd0db749597d91ff862fd1d55ea87f7855a744a8425a64695b6fca237d1dad1",
        strip_prefix = "smallvec-1.9.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.smallvec-1.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__spin__0_5_2",
        url = "https://crates.io/api/v1/crates/spin/0.5.2/download",
        type = "tar.gz",
        sha256 = "6e63cff320ae2c57904679ba7cb63280a3dc4613885beafb148ee7bf9aa9042d",
        strip_prefix = "spin-0.5.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.spin-0.5.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__spki__0_4_1",
        url = "https://crates.io/api/v1/crates/spki/0.4.1/download",
        type = "tar.gz",
        sha256 = "5c01a0c15da1b0b0e1494112e7af814a678fec9bd157881b49beac661e9b6f32",
        strip_prefix = "spki-0.4.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.spki-0.4.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__strsim__0_8_0",
        url = "https://crates.io/api/v1/crates/strsim/0.8.0/download",
        type = "tar.gz",
        sha256 = "8ea5119cdb4c55b55d432abb513a0429384878c15dde60cc77b1c99de1a95a6a",
        strip_prefix = "strsim-0.8.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.strsim-0.8.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__structopt__0_3_26",
        url = "https://crates.io/api/v1/crates/structopt/0.3.26/download",
        type = "tar.gz",
        sha256 = "0c6b5c64445ba8094a6ab0c3cd2ad323e07171012d9c98b0b15651daf1787a10",
        strip_prefix = "structopt-0.3.26",
        build_file = Label("//third_party/rust/crates/remote:BUILD.structopt-0.3.26.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__structopt_derive__0_4_18",
        url = "https://crates.io/api/v1/crates/structopt-derive/0.4.18/download",
        type = "tar.gz",
        sha256 = "dcb5ae327f9cc13b68763b5749770cb9e048a99bd9dfdfa58d0cf05d5f64afe0",
        strip_prefix = "structopt-derive-0.4.18",
        build_file = Label("//third_party/rust/crates/remote:BUILD.structopt-derive-0.4.18.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__subtle__2_4_1",
        url = "https://crates.io/api/v1/crates/subtle/2.4.1/download",
        type = "tar.gz",
        sha256 = "6bdef32e8150c2a081110b42772ffe7d7c9032b606bc226c8260fd97e0976601",
        strip_prefix = "subtle-2.4.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.subtle-2.4.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__syn__0_15_44",
        url = "https://crates.io/api/v1/crates/syn/0.15.44/download",
        type = "tar.gz",
        sha256 = "9ca4b3b69a77cbe1ffc9e198781b7acb0c7365a883670e8f1c1bc66fba79a5c5",
        strip_prefix = "syn-0.15.44",
        build_file = Label("//third_party/rust/crates/remote:BUILD.syn-0.15.44.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__syn__1_0_98",
        url = "https://crates.io/api/v1/crates/syn/1.0.98/download",
        type = "tar.gz",
        sha256 = "c50aef8a904de4c23c788f104b7dddc7d6f79c647c7c8ce4cc8f73eb0ca773dd",
        strip_prefix = "syn-1.0.98",
        build_file = Label("//third_party/rust/crates/remote:BUILD.syn-1.0.98.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__synstructure__0_12_6",
        url = "https://crates.io/api/v1/crates/synstructure/0.12.6/download",
        type = "tar.gz",
        sha256 = "f36bdaa60a83aca3921b5259d5400cbf5e90fc51931376a9bd4a0eb79aa7210f",
        strip_prefix = "synstructure-0.12.6",
        build_file = Label("//third_party/rust/crates/remote:BUILD.synstructure-0.12.6.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__tempfile__3_3_0",
        url = "https://crates.io/api/v1/crates/tempfile/3.3.0/download",
        type = "tar.gz",
        sha256 = "5cdb1ef4eaeeaddc8fbd371e5017057064af0911902ef36b39801f67cc6d79e4",
        strip_prefix = "tempfile-3.3.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.tempfile-3.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__termcolor__1_1_3",
        url = "https://crates.io/api/v1/crates/termcolor/1.1.3/download",
        type = "tar.gz",
        sha256 = "bab24d30b911b2376f3a13cc2cd443142f0c81dda04c118693e35b3835757755",
        strip_prefix = "termcolor-1.1.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.termcolor-1.1.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__terminal_size__0_1_17",
        url = "https://crates.io/api/v1/crates/terminal_size/0.1.17/download",
        type = "tar.gz",
        sha256 = "633c1a546cee861a1a6d0dc69ebeca693bf4296661ba7852b9d21d159e0506df",
        strip_prefix = "terminal_size-0.1.17",
        build_file = Label("//third_party/rust/crates/remote:BUILD.terminal_size-0.1.17.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__textwrap__0_11_0",
        url = "https://crates.io/api/v1/crates/textwrap/0.11.0/download",
        type = "tar.gz",
        sha256 = "d326610f408c7a4eb6f51c37c330e496b08506c9457c9d34287ecc38809fb060",
        strip_prefix = "textwrap-0.11.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.textwrap-0.11.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__thiserror__1_0_31",
        url = "https://crates.io/api/v1/crates/thiserror/1.0.31/download",
        type = "tar.gz",
        sha256 = "bd829fe32373d27f76265620b5309d0340cb8550f523c1dda251d6298069069a",
        strip_prefix = "thiserror-1.0.31",
        build_file = Label("//third_party/rust/crates/remote:BUILD.thiserror-1.0.31.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__thiserror_impl__1_0_31",
        url = "https://crates.io/api/v1/crates/thiserror-impl/1.0.31/download",
        type = "tar.gz",
        sha256 = "0396bc89e626244658bef819e22d0cc459e795a5ebe878e6ec336d1674a8d79a",
        strip_prefix = "thiserror-impl-1.0.31",
        build_file = Label("//third_party/rust/crates/remote:BUILD.thiserror-impl-1.0.31.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__toml__0_5_9",
        url = "https://crates.io/api/v1/crates/toml/0.5.9/download",
        type = "tar.gz",
        sha256 = "8d82e1a7758622a465f8cee077614c73484dac5b836c02ff6a40d5d1010324d7",
        strip_prefix = "toml-0.5.9",
        build_file = Label("//third_party/rust/crates/remote:BUILD.toml-0.5.9.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__typenum__1_15_0",
        url = "https://crates.io/api/v1/crates/typenum/1.15.0/download",
        type = "tar.gz",
        sha256 = "dcf81ac59edc17cc8697ff311e8f5ef2d99fcbd9817b34cec66f90b6c3dfd987",
        strip_prefix = "typenum-1.15.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.typenum-1.15.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__typetag__0_1_8",
        url = "https://crates.io/api/v1/crates/typetag/0.1.8/download",
        type = "tar.gz",
        sha256 = "4080564c5b2241b5bff53ab610082234e0c57b0417f4bd10596f183001505b8a",
        strip_prefix = "typetag-0.1.8",
        build_file = Label("//third_party/rust/crates/remote:BUILD.typetag-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__typetag_impl__0_1_8",
        url = "https://crates.io/api/v1/crates/typetag-impl/0.1.8/download",
        type = "tar.gz",
        sha256 = "e60147782cc30833c05fba3bab1d9b5771b2685a2557672ac96fa5d154099c0e",
        strip_prefix = "typetag-impl-0.1.8",
        build_file = Label("//third_party/rust/crates/remote:BUILD.typetag-impl-0.1.8.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_ident__1_0_1",
        url = "https://crates.io/api/v1/crates/unicode-ident/1.0.1/download",
        type = "tar.gz",
        sha256 = "5bd2fe26506023ed7b5e1e315add59d6f584c621d037f9368fea9cfb988f368c",
        strip_prefix = "unicode-ident-1.0.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.unicode-ident-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_segmentation__1_9_0",
        url = "https://crates.io/api/v1/crates/unicode-segmentation/1.9.0/download",
        type = "tar.gz",
        sha256 = "7e8820f5d777f6224dc4be3632222971ac30164d4a258d595640799554ebfd99",
        strip_prefix = "unicode-segmentation-1.9.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.unicode-segmentation-1.9.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_width__0_1_9",
        url = "https://crates.io/api/v1/crates/unicode-width/0.1.9/download",
        type = "tar.gz",
        sha256 = "3ed742d4ea2bd1176e236172c8429aaf54486e7ac098db29ffe6529e0ce50973",
        strip_prefix = "unicode-width-0.1.9",
        build_file = Label("//third_party/rust/crates/remote:BUILD.unicode-width-0.1.9.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_xid__0_1_0",
        url = "https://crates.io/api/v1/crates/unicode-xid/0.1.0/download",
        type = "tar.gz",
        sha256 = "fc72304796d0818e357ead4e000d19c9c174ab23dc11093ac919054d20a6a7fc",
        strip_prefix = "unicode-xid-0.1.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.unicode-xid-0.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__unicode_xid__0_2_3",
        url = "https://crates.io/api/v1/crates/unicode-xid/0.2.3/download",
        type = "tar.gz",
        sha256 = "957e51f3646910546462e67d5f7599b9e4fb8acdd304b087a6494730f9eebf04",
        strip_prefix = "unicode-xid-0.2.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.unicode-xid-0.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__vcpkg__0_2_15",
        url = "https://crates.io/api/v1/crates/vcpkg/0.2.15/download",
        type = "tar.gz",
        sha256 = "accd4ea62f7bb7a82fe23066fb0957d48ef677f6eeb8215f372f52e48bb32426",
        strip_prefix = "vcpkg-0.2.15",
        build_file = Label("//third_party/rust/crates/remote:BUILD.vcpkg-0.2.15.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__vec_map__0_8_2",
        url = "https://crates.io/api/v1/crates/vec_map/0.8.2/download",
        type = "tar.gz",
        sha256 = "f1bddf1187be692e79c5ffeab891132dfb0f236ed36a43c7ed39f1165ee20191",
        strip_prefix = "vec_map-0.8.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.vec_map-0.8.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__version_check__0_9_4",
        url = "https://crates.io/api/v1/crates/version_check/0.9.4/download",
        type = "tar.gz",
        sha256 = "49874b5167b65d7193b8aba1567f5c7d93d001cafc34600cee003eda787e483f",
        strip_prefix = "version_check-0.9.4",
        build_file = Label("//third_party/rust/crates/remote:BUILD.version_check-0.9.4.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__void__1_0_2",
        url = "https://crates.io/api/v1/crates/void/1.0.2/download",
        type = "tar.gz",
        sha256 = "6a02e4885ed3bc0f2de90ea6dd45ebcbb66dacffe03547fadbb0eeae2770887d",
        strip_prefix = "void-1.0.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.void-1.0.2.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__wasi__0_11_0_wasi_snapshot_preview1",
        url = "https://crates.io/api/v1/crates/wasi/0.11.0+wasi-snapshot-preview1/download",
        type = "tar.gz",
        sha256 = "9c8d87e72b64a3b4db28d11ce29237c246188f4f51057d65a7eab63b7987e423",
        strip_prefix = "wasi-0.11.0+wasi-snapshot-preview1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.wasi-0.11.0+wasi-snapshot-preview1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi__0_3_9",
        url = "https://crates.io/api/v1/crates/winapi/0.3.9/download",
        type = "tar.gz",
        sha256 = "5c839a674fcd7a98952e593242ea400abe93992746761e38641405d28b00f419",
        strip_prefix = "winapi-0.3.9",
        build_file = Label("//third_party/rust/crates/remote:BUILD.winapi-0.3.9.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_i686_pc_windows_gnu__0_4_0",
        url = "https://crates.io/api/v1/crates/winapi-i686-pc-windows-gnu/0.4.0/download",
        type = "tar.gz",
        sha256 = "ac3b87c63620426dd9b991e5ce0329eff545bccbbb34f3be09ff6fb6ab51b7b6",
        strip_prefix = "winapi-i686-pc-windows-gnu-0.4.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.winapi-i686-pc-windows-gnu-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_util__0_1_5",
        url = "https://crates.io/api/v1/crates/winapi-util/0.1.5/download",
        type = "tar.gz",
        sha256 = "70ec6ce85bb158151cae5e5c87f95a8e97d2c0c4b001223f33a334e3ce5de178",
        strip_prefix = "winapi-util-0.1.5",
        build_file = Label("//third_party/rust/crates/remote:BUILD.winapi-util-0.1.5.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__winapi_x86_64_pc_windows_gnu__0_4_0",
        url = "https://crates.io/api/v1/crates/winapi-x86_64-pc-windows-gnu/0.4.0/download",
        type = "tar.gz",
        sha256 = "712e227841d057c1ee1cd2fb22fa7e5a5461ae8e48fa2ca79ec42cfc1931183f",
        strip_prefix = "winapi-x86_64-pc-windows-gnu-0.4.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.winapi-x86_64-pc-windows-gnu-0.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__zerocopy__0_5_0",
        url = "https://crates.io/api/v1/crates/zerocopy/0.5.0/download",
        type = "tar.gz",
        sha256 = "5e59ec1d2457bd6c0dd89b50e7d9d6b0b647809bf3f0a59ac85557046950b7b2",
        strip_prefix = "zerocopy-0.5.0",
        build_file = Label("//third_party/rust/crates/remote:BUILD.zerocopy-0.5.0.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__zerocopy_derive__0_3_1",
        url = "https://crates.io/api/v1/crates/zerocopy-derive/0.3.1/download",
        type = "tar.gz",
        sha256 = "a0fbc82b82efe24da867ee52e015e58178684bd9dd64c34e66bdf21da2582a9f",
        strip_prefix = "zerocopy-derive-0.3.1",
        build_file = Label("//third_party/rust/crates/remote:BUILD.zerocopy-derive-0.3.1.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__zeroize__1_4_3",
        url = "https://crates.io/api/v1/crates/zeroize/1.4.3/download",
        type = "tar.gz",
        sha256 = "d68d9dcec5f9b43a30d38c49f91dfedfaac384cb8f085faca366c26207dd1619",
        strip_prefix = "zeroize-1.4.3",
        build_file = Label("//third_party/rust/crates/remote:BUILD.zeroize-1.4.3.bazel"),
    )

    maybe(
        http_archive,
        name = "raze__zeroize_derive__1_3_2",
        url = "https://crates.io/api/v1/crates/zeroize_derive/1.3.2/download",
        type = "tar.gz",
        sha256 = "3f8f187641dad4f680d25c4bfc4225b418165984179f26ca76ec4fb6441d3a17",
        strip_prefix = "zeroize_derive-1.3.2",
        build_file = Label("//third_party/rust/crates/remote:BUILD.zeroize_derive-1.3.2.bazel"),
    )
