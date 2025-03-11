# Quake .map file linter
# LICENSE:

from collections.abc import Generator


class Result():
    def __init__(self, filename, message, **kwargs):
        self.filename = filename
        self.message = message
        self.level = kwargs.get("level", "INFO")
        self.line = kwargs.get("line", 0)
        self.col = kwargs.get("col", 0)
        self.rule = kwargs.get("rule", "")


class BaseLinter():
    def __init__(self, config: dict = {}):
        super(BaseLinter, self).__init__()
        self.config = {}
        if self.__class__.__name__ in config.keys():
            self.config.update(config[self.__class__.__name__])

    def lint(self, target_file: str) -> Generator[Result]:
        yield None


class MultiplayerStartsLinter(BaseLinter):
    def __init__(self, config: dict = {}):
        super(MultiplayerStartsLinter, self).__init__()
        self.config["minimum_starts"] = {
            "deathmatch": 4,
            "coop": 4
        }
        if self.__class__.__name__ in config.keys():
            self.config.update(config[self.__class__.__name__])

    def lint(self, target_file: str) -> Generator[Result]:
        with open(target_file, "r") as map_file:
            map_data = map_file.read()
        for start_type, min_count in self.config["minimum_starts"].items():
            if map_data.count(f"info_player_{start_type}") < min_count:
                yield Result(filename=target_file,
                             message=f"Not enough {start_type} starts, expecting {min_count}",
                             level="ERROR:",
                             rule=f"min_{start_type}_starts")


class PylintFormatter():
    def __init__(self):
        super(PylintFormatter, self).__init__()

    def format_result(self, result: Result):
        print(f"{result.filename}:{result.line}:{result.col}: "
              f"[{result.rule}] {result.level} {result.message}")


if __name__ == "__main__":
    import argparse
    import glob
    import json
    import os

    parser = argparse.ArgumentParser()

    parser.add_argument("-c", "--config_file", required=False,
                        help="The configuration file to use.", type=str)
    parser.add_argument("mapfile", nargs="*", default=glob.glob("lq1/maps/src/*/*.map"),
                        help="A list of .map files to read.")

    args = parser.parse_args()
    formatter = PylintFormatter()
    config = {}
    if not args.config_file and os.path.isfile(".qmaplint.json"):
        args.config_file = os.path.abspath(".qmaplint.json")
    if args.config_file and not os.path.isfile(args.config_file):
        print(f"Configuration file {args.config_file} not found!")
        exit(1)
    elif args.config_file and os.path.isfile(args.config_file):
        print(f"Loading {args.config_file}...")
        with open(args.config_file, "r") as config_file:
            try:
                config = json.loads(config_file.read())
            except Exception as exc:
                print(f"Failed to read configuration file {args.config_file}! Error: {exc}")
                exit(1)

    linters = [cls for cls in locals().values()
               if type(cls) is type
               and issubclass(cls, BaseLinter)
               and cls is not BaseLinter]
    for linter in linters:
        for filename in args.mapfile:
            for result in linter(config=config).lint(filename):
                formatter.format_result(result)
