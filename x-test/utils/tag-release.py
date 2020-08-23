#!/usr/bin/env python3
#
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2020 Intel Corporation
#
"""Command-line script applying a tag to specified set of git repositories"""

# Standard library imports
import argparse
import configparser
import json
import os
import re
import subprocess
import sys
import tempfile
import requests

_USE_COLOR_FLAG = False
_USE_COLOR_ARG = "--use-color"
_GIT_CLONE_DEPTH = 50
_GIT_MAX_COMMITS_CHECK = 10

def _parse_options(args):
    parser = argparse.ArgumentParser(
        description="Apply a tag to specified set of git repositories")

    parser.add_argument(
        _USE_COLOR_ARG, action="store_true", dest="use_color",
        help="Use console colors to highlight important information")

    parser.add_argument(
        "--push-tags", action="store_true", dest="push_tags",
        help="Push the created tags to remote repositories")

    parser.add_argument(
        "--github-token", action="store", dest="github_token",
        help="Github token authentication, could be generated on GitHub website: \
              Profile\\Developer settings\\Personal access tokens\\Generate new token")

    parser.add_argument(
        "--release-desc-file", action="store", metavar="PATH", dest="release_desc_file",
        help="PATH to a file containing description to be associated with GitHub release."
             " The same description will be used for all the released repositories."
             " The description is in GitHub markdown format.")

    parser.add_argument(
        "--release", action="store", metavar="NAME", dest="release_title",
        help="NAME of a GitHub release."
             " The same name will be used for all the released repositories.")

    parser.add_argument(
        "--final-release", action="store_true", dest="final_release",
        default=False,
        help="Attach the _Latest release_ label to the created GitHub release to indicate that it"
             " is final or official. When this option is not specified, the _Pre-release_ label"
             " will be used.")

    default_tmp_dir_path = "."
    parser.add_argument(
        "--tmp-dir", action="store", metavar="PATH", dest="tmp_dir_path",
        default=default_tmp_dir_path,
        help="Directory to create a temporary working directory in (default: {0:s})".format(
            default_tmp_dir_path))

    parser.add_argument(
        "structure_file_path", action="store",
        help="Path to the project structure JSON file")

    parser.add_argument(
        "tag_name", action="store",
        help="Tag to be applied to all the repositories specified by the project structure file")

    return parser.parse_args(args)

def _debug(msg):
    if _USE_COLOR_FLAG:
        import colorama
        msg = "{0}{1}DEBUG: {2:s}{3}\n".format(
            colorama.Fore.WHITE, colorama.Style.DIM,
            msg, colorama.Style.RESET_ALL)
    else:
        msg = "DEBUG: {0:s}\n".format(msg)
    sys.stderr.write(msg)

def _error(msg):
    if _USE_COLOR_FLAG:
        import colorama
        msg = "{0}ERROR: {1:s}{2}\n".format(colorama.Fore.RED, msg, colorama.Style.RESET_ALL)
    else:
        msg = "ERROR: {0:s}\n".format(msg)
    sys.stderr.write(msg)


def _warning(msg):
    if _USE_COLOR_FLAG:
        import colorama
        msg = "{0}WARNING: {1:s}{2}\n".format(colorama.Fore.RED, msg, colorama.Style.RESET_ALL)
    else:
        msg = "WARNING: {0:s}\n".format(msg)
    sys.stderr.write(msg)


def _subprocess_run(cmd, **run_params):
    cmd_str = " ".join(cmd)
    cwd = run_params.get("cwd", ".")

    if _USE_COLOR_FLAG:
        import colorama
        msg = (
            "+[cwd={0:s}]\n"
            "+{1}{2}{3:s}{4}\n".format(
                cwd, colorama.Fore.WHITE, colorama.Style.BRIGHT,
                cmd_str, colorama.Style.RESET_ALL))
    else:
        msg = (
            "+[cwd={0:s}]\n"
            "+{1:s}\n".format(cwd, cmd_str))
    sys.stderr.write(msg)

    return subprocess.run(cmd, **run_params)

def _load_json(file_name):
    try:
        with open(file_name) as data_file:
            data = json.load(data_file)
    except IOError as err:
        _error("JSON file ('{0:s}') I/O error\n    {1}".format(file_name, err))
        sys.exit(1)

    return data

def _load_file(name):
    try:
        with open(name) as file:
            data = file.read()
    except IOError as err:
        _error("File ('{0:s}') I/O error\n    {1}".format(file, err))
        sys.exit(1)

    return data

def _clone_repo(repo_data):
    commit = repo_data.get("commit")
    # Unfortunately, it is not currently possible to shallow clone anything other than a branch and
    #  it is a likely scenario that someone will want to tag a specific commit (let's say that
    #  shortly before the tagging someone merged to the master branch something that shouldn't be
    #  included in the release. Because of that, if commit is specified for specific repository, it
    #  will allways be cloned fully and then the commit will be checked out.
    if commit is None:
        _subprocess_run(
            ["git", "clone"] + ["--depth={0:d}".format(_GIT_CLONE_DEPTH)] +
            [repo_data["clone url"], repo_data["path"]], check=True)
    else:
        _subprocess_run(
            ["git", "clone"] + [repo_data["clone url"], repo_data["path"]], check=True)
        _subprocess_run(["git", "checkout", commit], cwd=repo_data["path"], check=True)

    outcome = _subprocess_run(
        ["git", "rev-parse", "HEAD"], cwd=repo_data["path"],
        stdout=subprocess.PIPE, check=True)
    lines = outcome.stdout.decode().strip().splitlines()

    if len(lines) > 1:
        _warning(
            "The `git rev-parse HEAD` command resulted in multiple lines of output. The"
            " first line will be used and all the following lines ignored")

    if re.match("^[0-9a-f]{40}$", lines[0]) is None:
        _error(
            "Unexpected output of the `git rev-parse HEAD` command ('{0:s}' instead of"
            " a commit sha".format(lines[0]))
        sys.exit(1)

    repo_data["head sha"] = lines[0]

    outcome = _subprocess_run(
        ["git", "log", "--format=format:%H"], cwd=repo_data["path"],
        stdout=subprocess.PIPE, check=True)
    lines = outcome.stdout.decode().strip().splitlines()
    repo_data["history shas"] = lines

    outcome = _subprocess_run(
        ["git", "log", "--format=format:%an"], cwd=repo_data["path"],
        stdout=subprocess.PIPE, check=True)
    lines = outcome.stdout.decode().strip().splitlines()
    repo_data["authors commits"] = lines

    _debug("{0:s} repository HEAD is at {1:s}".format(repo_data["dir name"], repo_data["head sha"]))

def _get_last_authors_commits(repo_data, ahead_count):
    authors_list = []
    authors = ""
    last_commit_idx = min(ahead_count, _GIT_MAX_COMMITS_CHECK)
    for autor in repo_data["authors commits"][:last_commit_idx]:
        if autor not in authors_list:
            authors_list.append(autor)
            authors += " " + autor
    return authors

def _verify_modules_consistency(repo_data, repo_lut):
    modules_config = configparser.ConfigParser()
    modules_config.read(os.path.join(repo_data["path"], ".gitmodules"))

    for section in modules_config.sections():
        path = modules_config.get(section, "path")
        url = modules_config.get(section, "url")

        outcome = _subprocess_run(
            ["git", "submodule", "status", path], cwd=repo_data["path"],
            stdout=subprocess.PIPE, check=True)

        lines = outcome.stdout.decode().strip().splitlines()

        if len(lines) > 1:
            _warning(
                "git submodule command resulted in multiple lines of output. The first"
                " line will be used and all the following lines ignored")

        match = re.match("^[-+U](?P<sha>[0-9a-f]{{40}}) {0:s}$".format(re.escape(path)), lines[0])

        if match is None:
            _error(
                "Failed to parse output ('{0:s}') of a `git submodule status` command"
                "".format(lines[0]))
            sys.exit(1)

        referenced_sha = match.group("sha")

        try:
            referenced_repo = repo_lut[url]
        except KeyError:
            _warning(
                "The {0:s} repository references a submodule {1:s} which couldn't be found in the"
                " structure.json file".format(repo_data["dir name"], url))
            return True

        if referenced_sha != referenced_repo["head sha"]:
            index_ref_sha = referenced_repo["history shas"].index(referenced_repo["head sha"]) if \
                            referenced_repo["head sha"] in referenced_repo["history shas"] else None
            index_submodule_sha = referenced_repo["history shas"].index(referenced_sha) if \
                            referenced_sha in referenced_repo["history shas"] else None
            if index_ref_sha is None or index_submodule_sha is None:
                if referenced_repo.get("commit") is None:
                    autors = _get_last_authors_commits(referenced_repo, _GIT_CLONE_DEPTH)
                    history_info = (
                        'Open repository is more then {0:d} commits ahead,'
                        ' following people forgot to update submodule:\n\t{1:s}'
                        ''.format(_GIT_CLONE_DEPTH, autors))
                else:
                    history_info = (
                        'Open repository is incorrect set, please check "commit" in structure.json')
            else:
                ahead_count = index_submodule_sha - index_ref_sha
                if ahead_count > 0:
                    autors = _get_last_authors_commits(referenced_repo, ahead_count)
                    history_info = (
                        'Open repository is {0:d} commits ahead,'
                        ' following people forgot to update submodule:\n\t{1:s}'
                        ''.format(ahead_count, autors))
                else:
                    history_info = (
                        'Enhanced repository is {0:d} commits ahead, please check if submodule'
                        ' ("commit") is correctly set in structure.json'
                        ''.format(abs(ahead_count)))

            if _USE_COLOR_FLAG:
                import colorama
                bright = colorama.Style.BRIGHT
                normal = colorama.Style.NORMAL
            else:
                bright = ""
                normal = ""

            _error(
                "Submodule mismatch:\n"
                "    {0}{2:s}{1} repository references {0}{3:s}{1} as its {0}{4:s}{1}"
                " submodule\n"
                "    {0}{5:s}{1} repository HEAD is at {0}{6:s}{1}\n"
                "    {0}{7:s}{1}\n"
                "".format(
                    bright, normal,
                    repo_data["dir name"], referenced_sha, path,
                    referenced_repo["dir name"], referenced_repo["head sha"],
                    history_info))
            return False
    return True

def _challenge_colorama(options):
    if not options.use_color:
        return

    try:
        import colorama
    except ImportError:
        sys.stderr.write(
            "\n"
            " ERROR: Couldn't import the third party 'colorama' python module. You can\n"
            "  either omit the '{0:s}' command-line option (it doesn't influence the\n"
            "  script functionality or simply install the module e.g. by using one of the\n"
            "  following commands (if applicable):\n\n"
            " $ sudo apt install python3-colorama\n"
            " $ sudo pip3 install colorama\n".format(_USE_COLOR_ARG))
        sys.exit(1)

def main(options):
    """Script entry function"""
    if options.tag_name == "":
        _error("Tag name not specified")
        return 1

    _challenge_colorama(options)
    global _USE_COLOR_FLAG
    _USE_COLOR_FLAG = options.use_color

    repos_path = tempfile.TemporaryDirectory(dir=options.tmp_dir_path).name

    struct_data = _load_json(options.structure_file_path)

    release_content = ""

    if options.release_desc_file is not None:
        release_content = _load_file(options.release_desc_file)

    _debug(
        "{0:s}:\n{1:s}".format(
            options.structure_file_path, json.dumps(struct_data, indent=4, sort_keys=False)))

    repo_lut = dict((r["module url"], r) for r in struct_data["repos"])

    for repo in struct_data["repos"]:
        repo["dir name"] = os.path.basename(repo["clone url"])
        repo["path"] = os.path.join(repos_path, repo["dir name"])
        _clone_repo(repo)

    verification_errors = []
    for repo in struct_data["repos"]:
        if not _verify_modules_consistency(repo, repo_lut):
            verification_errors.append(
                {
                    "type": "module consistency",
                    "repo": repo
                })

    if verification_errors:
        _error(
            "Submodule inconsistency detected in case of following repositories:\n   * {0:s}"
            "".format("\n   * ".join(e["repo"]["dir name"] for e in verification_errors)))
        return 1

    if options.release_title is not None and options.github_token is None:
        _error("Missing GitHub token detected when release is activated")
        return 1

    for repo in struct_data["repos"]:
        _subprocess_run(["git", "tag", options.tag_name], cwd=repo["path"], check=True)

    if options.push_tags:
        for repo in struct_data["repos"]:
            _subprocess_run(
                ["git", "push", "origin", options.tag_name], cwd=repo["path"], check=True)

    if options.release_title is not None:
        head = {'Authorization': 'token {}'.format(options.github_token)}
        for repo in struct_data["repos"]:
            post_data = {'tag_name': options.tag_name,
                         'target_commitish': repo["head sha"],
                         'name': options.release_title,
                         'body': release_content,
                         'draft': False,
                         'prerelease': not options.final_release}
            repo_name = os.path.splitext(repo["dir name"])[0]
            api_url = "https://api.github.com/repos/otcshare/{0:s}/releases".format(repo_name)
            post_response = requests.post(api_url, data=json.dumps(post_data), headers=head)
            if not post_response.ok:
                _error(
                    "GitHub post request failed with error code: {0:d}"
                    .format(post_response.status_code))
    return 0


if __name__ == '__main__':
    sys.exit(main(_parse_options(sys.argv[1:])))
