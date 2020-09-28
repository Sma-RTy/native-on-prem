#!/bin/python3
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation

"""
    Cron/Jenkins test execution script

    This script can be copied to a test machine and run
    manually/scheduled to run using cron/Jenkins.
    It pulls configuration options from environment variables:
      - github_token
      - http_proxy
      - https_proxy
      - vm_default_name

    The script stores the artifacts from each run in 'artifacts'
    directory which will be created in the script's file parent folder.
"""

import argparse
import os
import shutil
import subprocess
import json
import time
import signal
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('-t', '--tags', nargs='+', help='Specifies tags to run', required=False)
parser.add_argument('-b', '--branch', help="Checkout 'test' to a given branch", required=False)
args = parser.parse_args()

github_token = os.getenv('github_token')
git_repo_url = "https://" + github_token + "@github.com/otcshare/test.git"

# All paths are based on the location of this file
root_dir = str(Path(__file__).parent.absolute())
artifacts_path = root_dir + "/artifacts"
test_repo_path = root_dir + "/test"
robot_entrypoint = test_repo_path + "/robot/run_tests.py"
env_conf_default_file = test_repo_path + "/robot/resources/variables/env.json"
robot_output_path = test_repo_path + "/robot/workdir"

robot_args = [robot_entrypoint, ]
if args.tags:
    robot_args.append('--tags')
    robot_args.extend(args.tags)

# Clone fresh 'test' repo
if Path(test_repo_path).exists():
    shutil.rmtree(test_repo_path)
subprocess.run(['git', 'clone', git_repo_url, test_repo_path], check=True)
if args.branch:
    subprocess.run(['git', 'checkout', args.branch], cwd=test_repo_path, check=True)

# Parse 'env.json' file
with open(env_conf_default_file, 'r') as f:
    env = json.load(f)

# Set environment settings
env['proxy']['enable'] = True
env['proxy']['remove_old'] = True
env['proxy']['http'] = os.getenv('http_proxy')
env['proxy']['https'] = os.getenv('https_proxy')
env['proxy']['yum'] = os.getenv('http_proxy')
env['proxy']['ftp'] = os.getenv('ftp_proxy')
env['proxy']['noproxy'] = os.getenv('no_proxy')

env['github_token'] = github_token

env['vm']['default_name'] = os.getenv('vm_default_name')

# Overwrite 'env.json'
with open(env_conf_default_file, 'w') as f:
    json.dump(env, f, indent=4)

# Run Tests
robot_entrypoint_proc = subprocess.Popen(robot_args)

# Propagate KeyboardInterrupt signal to the Robot Entrypoint process
try:
    while robot_entrypoint_proc.poll() is None:
        time.sleep(0.1)
except KeyboardInterrupt:
    robot_entrypoint_proc.send_signal(signal.SIGINT)
    robot_entrypoint_proc.wait(timeout=30)

# Collect artifacts
Path(artifacts_path).mkdir(parents=True, exist_ok=True)
for subdir in os.listdir(robot_output_path):
    shutil.copytree(os.path.join(robot_output_path, subdir),
                    os.path.join(artifacts_path, subdir))

# TODO: Publish the artifacts
