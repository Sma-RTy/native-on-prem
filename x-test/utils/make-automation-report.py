#!/usr/bin/env python3
#
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2020 Intel Corporation
#
"""Command-line script generating the integration tests automation progress report"""

# Standard library imports
import argparse
import decimal
import os
import re
import subprocess
import sys

_CSV_OUTPUT_ARG = "--csv-output"


def parse_options(args):
    """Parse command-line options"""
    parser = argparse.ArgumentParser(
        description="Generate integration tests automation progress report")

    default_test_repo_path = os.path.relpath(
        os.path.join(
            os.path.dirname(os.path.realpath(__file__)), ".."))

    parser.add_argument(
        "--test-repo", action="store", metavar="PATH", dest="test_repo_path",
        default=default_test_repo_path,
        help=(
            "Path to the test repository to be analyzed (default: {0:s})"
            "".format(default_test_repo_path)))
    parser.add_argument(
        _CSV_OUTPUT_ARG, action="store_true", dest="csv_flag",
        help="Print the results table in the CSV format")
    parser.add_argument(
        "-s", "--summary", action="store_true", dest="summary",
        help="Provide test set summary")

    return parser.parse_args(args)


def normalize_tc_id(raw):
    """Normalize test case id
    The matching pattern is more liberal than the desired id"""
    m = re.match(r"^ITP/(?P<mode>(NED|ONP|OFF))/(?P<suite>[\d]+)/(?P<case>[\d]+)$", raw)
    return "ITP/{0:s}/{1:02d}/{2:02d}".format(
        m.group("mode"), int(m.group("suite")), int(m.group("case")))


def normalize_ts_id(raw):
    """Normalize test suite id
    The matching pattern is more liberal than the desired id"""
    m = re.match(r"^ITP/(?P<mode>(NED|ONP|OFF))/(?P<suite>[\d]+)$", raw)
    return "ITP/{0:s}/{1:02d}".format(m.group("mode"), int(m.group("suite")))


def extract_ts_id(raw):
    """Extract test suite id from test case id"""
    m = re.match(r"^ITP/(?P<mode>(NED|ONP|OFF))/(?P<suite>[\d]+)/(?P<case>[\d]+)$", raw)

    return "ITP/{0:s}/{1:02d}".format(m.group("mode"), int(m.group("suite")))


def extract_automated_cases(robot_suites_path):
    """Extract set of identifiers of already automated cases"""

    handle = subprocess.run(
        ["grep", "-Erwoh", r"ITP/(NED|ONP|OFF)/[[:digit:]]+/[[:digit:]]+", robot_suites_path],
        stdout=subprocess.PIPE, check=True)
    robot_tcs = handle.stdout.decode().strip().splitlines()
    robot_tc_set = set(normalize_tc_id(id) for id in robot_tcs)
    return robot_tc_set


def extract_documented_suites(itp_path):
    """Extract a list of documented (known) test suites"""
    handle = subprocess.run(
        ["grep", "-Erwh", r"# ITP/(NED|ONP|OFF)/[[:digit:]]+ *:", itp_path],
        stdout=subprocess.PIPE, check=True)
    lines = handle.stdout.decode().strip().splitlines()

    pattern = re.compile(r"^.*# (?P<id>ITP/(NED|ONP|OFF)/[\d]+) *: *(?P<name>[A-Za-z0-9].*)$")

    def __make_desc(line):
        match = pattern.match(line)

        return {
            "ts_id": normalize_ts_id(match.group("id")),
            "title": match.group("name").strip()
        }

    return [__make_desc(line) for line in lines]


def extract_documented_cases(itp_path, automated_tc_set):
    """Extract a list of documented (known) test cases"""

    handle = subprocess.run(
        ["grep", "-Erwh", r"## ITP/(NED|ONP|OFF)/[[:digit:]]+/[[:digit:]]+", itp_path],
        stdout=subprocess.PIPE, check=True)
    lines = handle.stdout.decode().strip().splitlines()

    pattern = re.compile(
        r"^.*## (?P<id>ITP/(NED|ONP|OFF)/[\d]+/[\d]+) *: *(?P<name>[A-Za-z0-9].*)$")

    def __make_desc(line):
        match = pattern.match(line)
        fixed_id = normalize_tc_id(match.group("id"))

        return {
            "tc_id": fixed_id,
            "ts_id": extract_ts_id(match.group("id")),
            "title": match.group("name").strip(),
            "robot": fixed_id in automated_tc_set
        }

    return [__make_desc(line) for line in lines]


def main(options):
    """Script entry function"""
    automated_tc_set = extract_automated_cases(
        os.path.join(options.test_repo_path, "robot", "testsuites"))
    documented_tcs = extract_documented_cases(
        os.path.join(options.test_repo_path, "itp"), automated_tc_set)
    documented_tss = extract_documented_suites(
        os.path.join(options.test_repo_path, "itp"))
    ts_name_lut = dict((ts["ts_id"], ts["title"]) for ts in documented_tss)

    automated_cnt = len([tc for tc in documented_tcs if tc["robot"]])
    total_cnt = len(documented_tcs)

    def __calc_ratio(part, total):
        ratio = (decimal.Decimal("{0:d}.0000".format(part)) / decimal.Decimal(total) * 100)
        return ratio.quantize(decimal.Decimal("0.00"), decimal.ROUND_HALF_UP)

    automated_ratio = __calc_ratio(automated_cnt, total_cnt)
    sorted_tc = sorted(documented_tcs, key=lambda tc: tc["tc_id"])

    if options.summary:
        def __make_ts_row(ts_id):
            return {
                "ts_id": ts_id,
                "ts_name": ts_name_lut.get(ts_id, ""),
                "total_cnt": 0,
                "automated_cnt": 0,
                "ratio": decimal.Decimal("0.0000"),
                "priority": 1
            }

        set_lut = dict(
            (ts_id, __make_ts_row(ts_id))
            for ts_id in set(tc["ts_id"] for tc in sorted_tc))

        for case in sorted_tc:
            ts_row = set_lut[case["ts_id"]]
            ts_row["total_cnt"] += 1
            ts_row["automated_cnt"] += (1 if case["robot"] else 0)

        sorted_ts = sorted(set_lut.values(), key=lambda ts: ts["ts_id"])

        for ts in sorted_ts:
            ts["ratio"] = __calc_ratio(ts["automated_cnt"], ts["total_cnt"])
            if ts["automated_cnt"] == ts["total_cnt"]:
                ts["priority"] = 99



    if options.csv_flag:
        if options.summary:
            print(
                '"Test Set Id", "Test Set Name", "Total TC Count", "Automated TC Count",'
                ' "Automation Ratio", "Priority"')
            for ts in sorted_ts:
                print(
                    '"{0:s}", "{1:s}", "{2:d}", "{3:d}", "{4:14.2f}%", "{5:d}"'
                    ''.format(
                        ts["ts_id"], ts["ts_name"], ts["total_cnt"], ts["automated_cnt"],
                        ts["ratio"], ts["priority"]))
        else:
            print('"Test Case Id", "Test Set Id", "Test Case Name", "Automated"')
            for tc in sorted_tc:
                print(
                    '"{0:s}", "{1:s}", "{2:s}", {3:d}'
                    ''.format(tc["tc_id"], tc["ts_id"], tc["title"], 1 if tc["robot"] else 0))
    else:
        try:
            import tabulate
        except ImportError:
            sys.stderr.write(
                "\n"
                " ERROR: Couldn't import the third party 'tabulate' python module. You can\n"
                "  either use the '{0:s}' command-line option to work it around or\n"
                "  simply install the module e.g. by using one of the following commands\n"
                "  (if applicable):\n\n"
                " $ sudo apt install python3-tabulate\n"
                " $ sudo pip3 install tabulate\n".format(_CSV_OUTPUT_ARG))
            return 1

        if options.summary:
            print(
                tabulate.tabulate(
                    [[ts["ts_id"], ts["ts_name"], ts["total_cnt"], ts["automated_cnt"],
                      "{0:14.2f}%".format(ts["ratio"]), ts["priority"]] for ts in sorted_ts] +
                    [["", "Total", total_cnt, automated_cnt,
                      "{0:14.2f}%".format(automated_ratio), ""]],
                    headers=[
                        "Test Set Id", "Test Set Name", "Total TC Count",
                        "Automated TC Count", "Automation Ratio", "Priority"],
                    tablefmt="orgtbl"))
        else:
            print(
                tabulate.tabulate(
                    [[tc["tc_id"], tc["ts_id"], tc["title"], tc["robot"]]
                     for tc in sorted_tc] +
                    [["", "", "", "{0:14.2f}%".format(automated_ratio)]],
                    headers=["Test Case Id", "Test Set Id", "Title", "Automated"],
                    tablefmt="orgtbl"))

    return 0


if __name__ == '__main__':
    sys.exit(main(parse_options(sys.argv[1:])))
