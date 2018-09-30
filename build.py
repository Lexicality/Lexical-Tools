#!/usr/bin/env python3

import itertools
import json
from glob import iglob
import shutil
from typing import NewType
import os.path
import os
import logging

log = logging.getLogger(__name__)

AddonData = NewType("AddonData", dict)

BUILD_DIR = "_build"


def copy_files(build_dir: str, addon_data: AddonData) -> None:
    # TODO: Be clever about last modified dates etc and diff the directories

    if os.path.isdir(build_dir):
        log.debug("Build directory %s already exists, deleting", build_dir)
        shutil.rmtree(build_dir)

    for file in itertools.chain.from_iterable(
        iglob(path) for path in addon_data["include"]
    ):
        source = os.path.relpath(file)
        dest = os.path.join(build_dir, source)
        dirname = os.path.dirname(dest)

        log.debug("Creating build directory %s", dirname)
        os.makedirs(dirname, exist_ok=True)
        log.debug("Copying %s to %s", source, dest)
        shutil.copyfile(source, dest)


def get_addon_json(name: str) -> str:
    file = f"addons/{name}.json"
    # Throw an error if the file doesn't exist
    os.stat(file)
    return file


def copy_addon_json(filename: str, build_dir: str) -> None:
    dest = os.path.join(build_dir, "addon.json")

    log.debug("Copying %s to %s", filename, dest)
    shutil.copyfile(filename, dest)


def get_addon_data(filename: str) -> AddonData:
    with open(filename, mode="rt") as f:
        return json.load(f)


def main():
    logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")
    name = "moneypot"

    build_dir = os.path.join(BUILD_DIR, name)
    file = get_addon_json(name)

    data = get_addon_data(file)

    copy_files(build_dir, data)
    copy_addon_json(file, build_dir)


if __name__ == "__main__":
    main()
