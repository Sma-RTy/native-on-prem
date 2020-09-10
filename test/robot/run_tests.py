#!/usr/bin/python3

import os
import argparse
import time
import subprocess
import signal
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('-t', '--tags', nargs='+', help='Specifies tags to run', required=False)
parser.add_argument('--devel-dump', action='store_true', help='Skip cleanup step and dump VMs config for use with '
                                                              '--devel-vms-conf')
parser.add_argument('--devel-vms-conf', help='Skip setup step and use the VMs from the config dumped by --devel-dump',
                    required=False)
parser.add_argument('--force-cleanup', action='store_true', help='Forces cleanup of VMs', required=False)
parser.add_argument('--use-physical-machines', action='store_true', help='Use only physical machines instead of VMs', required=False)
parser.add_argument('--use-physical-nodes', action='store_true', help='Use only physical Edge Nodes instead of VMs', required=False)
parser.add_argument('--use-physical-controllers', action='store_true', help='Use only physical Edge Controllers instead of VMs', required=False)
parser.add_argument('--non-rt-kernel', action='store_true', help='Disable RT kernel', required=False)
args = parser.parse_args()

DATE_STRING = os.popen(r'date +%Y-%m-%d---%H-%M-%S-%3N').read().strip()
ROBOT_BASE_DIR = Path(__file__).parent.absolute()
ROBOT_WORK_DIR = str(ROBOT_BASE_DIR.joinpath('workdir', DATE_STRING))
ROBOT_LOG_DIR = str(ROBOT_BASE_DIR.joinpath('workdir', DATE_STRING, 'logs'))
ROBOT_BASE_DIR = str(ROBOT_BASE_DIR)

os.makedirs(ROBOT_LOG_DIR)

print("ROBOT_BASE_DIR set to: {}".format(ROBOT_BASE_DIR))
print("ROBOT_WORK_DIR set to: {}".format(ROBOT_WORK_DIR))
print("ROBOT_LOG_DIR set to: {}".format(ROBOT_LOG_DIR))

robot_args = ['robot',
              '--variable', 'RUN_UID:{}'.format(DATE_STRING),
              '--variable', 'ROBOT_BASE_DIR:{}'.format(ROBOT_BASE_DIR),
              '--variable', 'ROBOT_WORK_DIR:{}'.format(ROBOT_WORK_DIR),
              '--variable', 'ROBOT_LOG_DIR:{}'.format(ROBOT_LOG_DIR),
              '--outputdir', ROBOT_LOG_DIR,
              '--loglevel', 'TRACE:TRACE',
              '--variable', 'ENV_CONFIG_FILE:{}/resources/variables/env.json'.format(ROBOT_BASE_DIR),
              ]

# Include each tag from the command line
include_debug = False
if args.tags:
    for tag in args.tags:
        robot_args.extend(['--include', tag])
        if tag.startswith('DEBUG'):
            include_debug = True

if not include_debug:
    robot_args.extend(['--exclude', 'DEBUG*'])

# Set devel variables
robot_args.extend(['--variable', 'DEVEL_DUMP:{}'.format(args.devel_dump)])
if args.devel_vms_conf:
    robot_args.extend(['--variable', 'DEVEL_VMS_CONF:{}'.format(args.devel_vms_conf)])

# Set force cleanup
robot_args.extend(['--variable', 'FORCE_CLEANUP:{}'.format(args.force_cleanup)])

# Set use physical machines
robot_args.extend(['--variable', 'USE_PHYSICAL_CONTROLLERS:{}'.format(args.use_physical_machines or args.use_physical_controllers)])
robot_args.extend(['--variable', 'USE_PHYSICAL_NODES:{}'.format(args.use_physical_machines or args.use_physical_nodes)])

# Non-RT kernel
robot_args.extend(['--variable', 'NON_RT_KERNEL:{}'.format(args.non_rt_kernel)])

# Testsuites entrypoint
robot_args.append('{}/testsuites'.format(ROBOT_BASE_DIR))

robot_proc = subprocess.Popen(robot_args)

# Propagate KeyboardInterrupt signal to the Robot process
try:
    while robot_proc.poll() is None:
        time.sleep(0.1)
except KeyboardInterrupt:
    robot_proc.send_signal(signal.SIGINT)
    robot_proc.wait(timeout=30)
