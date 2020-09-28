# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
import copy
import json
import os
import subprocess
import time
import yaml
from types import SimpleNamespace
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn


_retry_args_defaults = {
    'count': 30,
    'sleep_interval': 5,
    'exc_type': Exception,
    'console': True,
}


def retry_decorator(**decorator_kwargs):
    """Decorator used to run a given function a number of times.

    Available parameters are defined in '_retry_args_defaults'.
    """

    # Get arguments from the decorator_kwargs and create variables from dictionary
    retry_args = copy.deepcopy(_retry_args_defaults)
    for key in decorator_kwargs:
        if key not in retry_args:
            raise KeyError("'{}' parameter not found in accepted arguments: {}".format(key, _retry_args_defaults.keys()))
        retry_args[key] = decorator_kwargs[key]

    # Create and populate namespace with arguments from decorator_kwargs
    ns_args = SimpleNamespace(**retry_args)

    def decorator(func):
        def result(*args, **kwargs):
            last_exception = ns_args.exc_type
            for _ in range(ns_args.count):
                try:
                    return func(*args, **kwargs)
                except ns_args.exc_type as err:
                    logger.info("Caught exception: {}".format(err))
                    last_exception = err
                    pass
                args_str = ', '.join([str(arg) for arg in args])
                logger.info("Retrying {}({}) in {} seconds...".format(func.__name__, args_str, ns_args.sleep_interval),
                    also_console=ns_args.console)
                time.sleep(ns_args.sleep_interval)
            raise last_exception

        return result

    return decorator


def run_and_log_output(*args, directory='.', console=False):
    """Runs a command and logs output to a Robot Log file and optionally as well to the console.

    :param [str] args: command and arguments
    :param str directory: current working directory
    :param bool console: log to console as well

    :return: return code from a command
    """

    proc = subprocess.Popen(args, cwd=directory, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    all_lines = list()
    while True:
        line = proc.stdout.readline()
        if line == b'' and proc.poll() is not None:
            break
        if line:
            all_lines.append(line.decode('utf-8', errors='replace'))
            if console:
                logger.console(line, newline=False)
    logger.info('\n'.join(all_lines))

    return proc.poll()


def sanitize_testsuite_name(suite_name):
    """Sanitize Test Suite name so that it can be used as a directory name, snapshot name, etc.

    :return: Test Suite name without 'Testsuites.' prefix and with spaces and slashes replaced with underscores
    """
    # Example Test Suite name 'Testsuites.Suite Name'
    return suite_name[suite_name.find('.') + 1:].replace(' ', '_').replace('/', '_')


def dump_machines_config(machines_info, run_uid, setup_info):
    """
    Dumps machines config for another run (triggered when DEVEL_DUMP == True) to ${deployment_dir}/machines_info.json.

    :param str run_uid: Unique ID of a current run
    :param dict machines_info: Dictionary with machines info
        {
            'machine_name1': {'hostname': str, 'snapshots': [str]},
            'machine_name2': {'hostname': str, 'snapshots': [str]},
            ...
        }
    """

    machines_config = dict()
    machines_config['machines'] = machines_info
    machines_config['run_uid'] = run_uid
    machines_config['workdir'] = BuiltIn().get_variable_value("${deployment_dir}")
    machines_config['setup'] = setup_info

    machines_info_path = '{}/machines_info.json'.format(BuiltIn().get_variable_value("${deployment_dir}"))

    with open(machines_info_path, 'w') as f:
        json.dump(machines_config, f, indent=4)

    logger.info("Dumped machines_config to '{}'".format(machines_info_path), also_console=True)
    logger.debug("machines_config = {}".format(machines_config))


def run_ssh_command(hostname, ssh_client, *args, **kwargs):
    """
    Run ssh command on already connected SSHClient.

    :param str hostname: Hostname.
    :param SSHClient ssh_client: Connected SSHClient.
    :param list args: Positional arguments for exec_command.
    :param dict kwargs: Named arguments for exec_command.
    """

    _, stdout, stderr = ssh_client.exec_command(*args, **kwargs)

    stdout_str = stdout.read().decode("utf-8", "replace")

    if args:
        command = args[0]
    elif kwargs and "command" in kwargs:
        command = kwargs["command"]
    else:
        command = ""

    rc = stdout.channel.recv_exit_status()
    if rc != 0:
        stderr_str = stderr.read().decode("utf-8", "replace")
        raise RuntimeError(("Command failed on {}\n"
                            "command: '{}'\n"
                            "rc: {}\n"
                            "stdout: {}\n"
                            "stderr: {}").format(hostname, command, rc, stdout_str, stderr_str))
    logger.debug("command: '{}'\noutput: '{}'".format(command, stdout_str))
    return stdout_str


def get_variable_from_file(file_path, variable):
    workdir = BuiltIn().get_variable_value("${deployment_dir}")
    file_path = os.path.join(workdir, 'oek', file_path)

    with open(file_path, 'r') as f:
        document = yaml.safe_load(f)

    return document[variable]


def set_variable_in_file(file_path, variable, value):
    document = None
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            document = yaml.safe_load(f)

    # If a file is empty then the 'document' is None
    if not document:
        document = dict()
    document[variable] = value

    with open(file_path, 'w+') as f:
        yaml.safe_dump(document, f, sort_keys=False)
