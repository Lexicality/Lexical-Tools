#!/usr/bin/env python3

import itertools
import json
import logging
import os
import os.path
import shutil
import subprocess
from datetime import datetime
from glob import iglob
from typing import cast

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
#         "include": List[str],
#     },
# )

BUILD_DIR = "_build"


class Addon:
    name: str
    datafile: str
    data: AddonData

    def __init__(self, name: str) -> None:
        self.name = name
        self._load_data()
        self.build_dir = os.path.join(BUILD_DIR, name)
        # self.data = {}

    def _load_data(self) -> None:
        self.datafile = f"addons/{self.name}.json"
        # Throw an error if the file doesn't exist
        os.stat(self.datafile)

        with open(self.datafile, mode="rt") as f:
            self.data = cast(AddonData, json.load(f))

    def copy_to_build(self) -> None:
        log.info("%s: Copying to build directory", self.name)
        # TODO: Be clever about last modified dates etc and diff the directories

        if os.path.isdir(self.build_dir):
            log.debug("Build directory %s already exists, deleting", self.build_dir)
            shutil.rmtree(self.build_dir)

        for file in itertools.chain.from_iterable(
            iglob(path) for path in self.data["include"]
        ):
            source = os.path.relpath(file)
            dest = os.path.join(self.build_dir, source)
            dirname = os.path.dirname(dest)

            log.debug("Creating build directory %s", dirname)
            os.makedirs(dirname, exist_ok=True)
            log.debug("Copying %s to %s", source, dest)
            shutil.copyfile(source, dest)

        dest = os.path.join(self.build_dir, "addon.json")

        log.debug("Copying %s to %s", self.datafile, dest)
        shutil.copyfile(self.datafile, dest)

    def _target_gma_name(self) -> str:
        now = datetime.utcnow().strftime(r"%Y-%m-%d")
        # TODO: Semver?
        return f"{self.name}_{now}_{self.data['workshopid']}.gma"

    def build(self) -> None:
        log.info("%s: Building GMA", self.name)
        target = os.path.join(BUILD_DIR, self._target_gma_name())
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


def main():
    logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")

    moneypot = Addon("moneypot")

    moneypot.copy_to_build()
    moneypot.build()


if __name__ == "__main__":
    main()
