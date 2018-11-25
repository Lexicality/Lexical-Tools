#!/usr/bin/env python
import argparse
import itertools
import json
import logging
import os
import os.path
import shutil
import subprocess
from glob import iglob
from typing import Callable, Iterable, Iterator, List, Optional, Tuple, TypeVar, cast

import semver

# from typing import Any, Dict, List, Optional, cast
# from mypy_extensions import TypedDict

log = logging.getLogger(__name__)


AddonData = dict  # Dict[str, Any]
# TypedDict(
#     "AddonData",
#     {
#         # Built in gmod
#         "title": str,
#         "type": str,
#         "tags": List[str],
#         "ignore": List[str],
#         # Stuff I sometimes put in anyway
#         "author": Optional[str],
#         "contact": Optional[str],
#         "license": Optional[str],
#         # Stuff for this tool
#         "workshopid": int,  # From gmosh
#         "version": str,
#         "include": List[str],
#         "import": List[str],
#         "versionables": List[str],
#     },
# )

BUILD_DIR = "_build"
ADDON_DIR = "addons"

ALL_ADDONS = [
    os.path.splitext(os.path.basename(file))[0] for file in iglob(f"{ADDON_DIR}/*.json")
]

VALID_BUMPS = [
    "major",
    "minor",
    "patch",
    "pre",
    "premajor",
    "preminor",
    "prepatch",
    "prerelease",
]

TEXT_EXTENSIONS = [".lua"]

T = TypeVar("T")


class Addon:
    name: str
    datafile: str
    data: AddonData
    version: semver.SemVer
    sub_addons: List["Addon"]

    def __init__(self, name: str) -> None:
        self.name = name
        self._load_data()
        self.build_dir = os.path.join(BUILD_DIR, name)
        self.version = semver.parse(self.data.get("version", "0.0.0"), loose=True)
        self._load_subaddons()
        # self.data = {}

    def _load_data(self) -> None:
        self.datafile = os.path.normpath(f"{ADDON_DIR}/{self.name}.json")
        # Throw an error if the file doesn't exist
        os.stat(self.datafile)

        with open(self.datafile, mode="rt") as f:
            self.data = cast(AddonData, json.load(f))

    def _load_subaddons(self) -> None:
        self.sub_addons = [Addon(name) for name in self.data.get("import", [])]

    def _listiculate(self, action: Callable[["Addon"], Iterable[T]]) -> Iterator[T]:
        return itertools.chain(
            action(self),
            itertools.chain.from_iterable(
                addon._listiculate(action) for addon in self.sub_addons
            ),
        )

    def _get_versionables(self) -> Iterator[Tuple[str, str]]:
        return self._listiculate(
            lambda addon: (
                (name, f"{name}_v{addon.version.format().replace('.', '_')}")
                for name in addon.data.get("versionables", [])
            )
        )
        pass

    def _get_files(self) -> Iterator[str]:
        return itertools.chain.from_iterable(
            iglob(path)
            for path in self._listiculate(lambda addon: addon.data["include"])
        )

    def copy_to_build(self) -> None:
        log.info("%s: Copying to build directory", self.name)

        if os.path.isdir(self.build_dir):
            log.debug("Build directory %s already exists, deleting", self.build_dir)
            shutil.rmtree(self.build_dir)

        versionables = list(self._get_versionables())

        for file in self._get_files():
            source = os.path.relpath(file)

            dest = source
            for old, new in versionables:
                dest = dest.replace(old, new)

            dest = os.path.join(self.build_dir, dest)

            dirname = os.path.dirname(dest)
            log.debug("Creating build directory %s", dirname)
            os.makedirs(dirname, exist_ok=True)

            (_, ext) = os.path.splitext(dest)
            if versionables and ext in TEXT_EXTENSIONS:
                log.debug("Copying %s to %s via sed", source, dest)

                with open(source, "r") as f:
                    filedata = f.read()

                for old, new in versionables:
                    filedata = filedata.replace(old, new)

                with open(dest, "w") as f:
                    f.write(filedata)
            else:
                log.debug("Copying %s to %s", source, dest)
                shutil.copyfile(source, dest)

        dest = os.path.join(self.build_dir, "addon.json")

        log.debug("Copying %s to %s", self.datafile, dest)
        shutil.copyfile(self.datafile, dest)

    def _target_gma_name(self) -> str:
        name = f"{self.name}_v{self.version.format()}"
        wsid = self.data.get("workshopid", None)
        if wsid:
            name += f"_{wsid}"

        return os.path.join(BUILD_DIR, name + ".gma")

    def build(self) -> None:
        log.info("%s: Building GMA", self.name)
        target = self._target_gma_name()
        log.debug("Creating GMA %s from %s", target, self.build_dir)
        res = subprocess.run(
            ["gmad", "create", "-folder", self.build_dir, "-out", target],
            stdout=subprocess.PIPE,
            # Garry doesn't belive in stderr but some day he might
            stderr=subprocess.STDOUT,
            encoding="utf-8",
        )

        if res.returncode != 0:
            log.critical("Unable to create GMA")
            log.critical(res.stdout)
            # ?
            res.check_returncode()

    def write_data(self) -> None:
        with open(self.datafile, mode="wt") as f:
            json.dump(self.data, f, indent="\t")

    def bump_version(self, release: str, identifier: Optional[str] = None) -> None:
        log.info("%s: Building version by %s", self.name, release)
        self.version.inc(release, identifier)
        self.data["version"] = self.version.format()
        log.debug("Version is now %s", self.data["version"])

    def gma_exists(self) -> bool:
        return os.path.isfile(self._target_gma_name())

    def update(self, changes: str) -> None:
        log.info("%s: Uploading %s to the workshop", self.name, self.version)
        target = self._target_gma_name()
        workshopid = str(self.data["workshopid"])
        res = subprocess.run(
            [
                "gmpublish",
                "update",
                "-id",
                workshopid,
                "-addon",
                target,
                "-changes",
                changes,
            ],
            stdout=subprocess.PIPE,
            # Garry doesn't belive in stderr but some day he might
            stderr=subprocess.STDOUT,
            encoding="utf-8",
        )

        if res.returncode != 0:
            log.critical("Unable to update to the workshop")
            log.critical(res.stdout)
            # ?
            res.check_returncode()
        else:
            log.info(res.stdout)


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    actions = parser.add_subparsers(dest="action")

    parser.add_argument("addon", choices=ALL_ADDONS)

    actions.add_parser("build")

    bump_args = actions.add_parser("bump")
    bump_args.add_argument("release", choices=VALID_BUMPS)
    bump_args.add_argument("pretag", nargs="?")

    release_args = actions.add_parser("release")
    release_args.add_argument("--bump", choices=VALID_BUMPS, const="minor", nargs="?")
    release_args.add_argument("--changes")

    return parser.parse_args()


def get_changes() -> str:
    lines = []

    print("Enter changes, . to stop")
    while True:
        try:
            line = input().strip()
        except EOFError:
            break

        if line == ".":
            break

        lines.append(line)

    return "\n".join(lines).strip()


def main():
    logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")

    args = get_args()
    logging.debug("Doing a %s", args.action)

    addon = Addon(args.addon)

    if args.action == "build":
        addon.copy_to_build()
        addon.build()
    elif args.action == "bump":
        addon.bump_version(args.release, args.pretag)
        addon.write_data()
    elif args.action == "release":
        changes = args.changes
        if not changes:
            changes = get_changes()

        if args.bump:
            addon.bump_version(args.bump)
            addon.write_data()

        changes = f"v{addon.version}: {changes}"

        if not addon.gma_exists():
            addon.copy_to_build()
            addon.build()

        addon.update(changes)


if __name__ == "__main__":
    main()
