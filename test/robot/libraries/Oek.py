# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
import os
import yaml
import re
from pathlib import Path
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn

class Oek(object):
    """Class for interacting with openness-experience-kits module.
    """

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'

    def __init__(self):
        pass

    def set_environment_config(self, env_config):
        """Sets enviroment variables.

        :param dict env_config: a dict of environment variables containing information such as the default base VM.
        """

    def get_group_vars_file_path(self, group='all'):
        """Returns path to a specified group vars file

        :param str group: Group as in inventory.ini file ('all' by default).
        """

        deployment_dir = BuiltIn().get_variable_value("${deployment_dir}")

        path = Path("{}/native-on-prem/oek/group_vars/{}/10-default.yml".format(deployment_dir, group))

        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch(exist_ok=True)
        return str(path)

    def get_host_vars_file_path(self, host):
        """Returns path to a specified host vars file

        :param str group: Host as in inventory.ini file.
        """

        deployment_dir = BuiltIn().get_variable_value("${deployment_dir}")

        path = Path("{}/native-on-prem/oek/host_vars/{}.yml".format(deployment_dir, host))

        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch(exist_ok=True)
        return str(path)

    def get_proxy_settings(self):
        """Get proxy settings from OEK.

        :return: Dictionary with proxy settings
            {
                'enabled': bool,
                'http_proxy': str,
                'https_proxy': str,
                'ftp_proxy': str,
                'no_proxy': str
            }
        """

        vars_path = self.get_group_vars_file_path()
        with open(vars_path, 'r') as f:
            variables = yaml.safe_load(f)

        proxy_vars = dict()
        proxy_vars['enabled'] = variables['proxy_enable']
        proxy_vars['http_proxy'] = variables['proxy_http']
        proxy_vars['https_proxy'] = variables['proxy_https']
        proxy_vars['ftp_proxy'] = variables['proxy_ftp']
        proxy_vars['no_proxy'] = variables['proxy_noproxy']

        return proxy_vars

    def update_inventory_file(self, inventory_file=None, controller_group=True, edgenode_group=True):
        """Fill OEK inventory file with machines data from $machines_info.

        :param str inventory_file: Path to inventory file
        :param bool controller_group: Process the controller_group if True.
        :param bool edgenode_group: Process the edgenode_group if True.
        """

        if not inventory_file:
            deployment_dir = BuiltIn().get_variable_value("${deployment_dir}")
            inventory_file = "{}/native-on-prem/oek/inventory.ini".format(deployment_dir)

        machines_info = BuiltIn().get_variable_value("${machines_info}")
        single_node = True if len(machines_info) == 1 else False

        # Updated inventory content
        inventory_blocks = list()

        # Helper variables for file processing
        copy_previous = True
        last_pos = 0

        # Get the inventory
        with open(inventory_file, 'r') as f:
            inventory = f.read()

        # Pattern for matching the section header with optional following whitespace characters e.g.:
        # ^[SectionName]\n
        # ^    [SectionName]  \n
        section_header_regexp = re.compile(
            r'[^\S\r\n]*(\[\S+\]).*\n', re.MULTILINE)

        for section_match in section_header_regexp.finditer(inventory):
            # Copy unprocessed content from sections other than [controller_group], [edgenode_group] and [all]
            if copy_previous:
                inventory_blocks.append(inventory[last_pos:section_match.start()])

            # Copy the section header
            inventory_blocks.append(
                inventory[section_match.start():section_match.end()])
            last_pos = section_match.end()

            copy_previous = False
            section_name = section_match.groups()[0]

            if controller_group and section_name == '[controller_group]':
                for machine in machines_info:
                    if single_node or machines_info[machine]['type'] == 'controller':
                        inventory_blocks.append('{}\n'.format(machine + "-ctrl" if single_node else machine))
                inventory_blocks.append('\n')

            elif edgenode_group and section_name == '[edgenode_group]':
                for machine in machines_info:
                    if single_node or machines_info[machine]['type'] == 'edgenode':
                        inventory_blocks.append('{}\n'.format(machine + "-node" if single_node else machine))
                inventory_blocks.append('\n')

            elif section_name == '[all]':
                for machine in machines_info:
                    username = machines_info[machine]['username']

                    # We need to use IP in the inventory because some components require that
                    if single_node:
                        inventory_blocks.append("{name}-ctrl ansible_ssh_user={user} ansible_host={host}\n"
                            "{name}-node ansible_ssh_user={user} ansible_host={host}\n".format(name=machine, user=username, host=machines_info[machine]['ip']))
                    else:
                        inventory_blocks.append('{} ansible_ssh_user={} ansible_host={}\n'.format(machine, username, machines_info[machine]['ip']))
                inventory_blocks.append('\n')
            else:
                # Unhandled section - copy its content to the result file
                copy_previous = True

        # Copy remaining sections
        if copy_previous:
            inventory_blocks.append(inventory[last_pos:])

        with open(inventory_file, 'w') as f:
            f.write(''.join(inventory_blocks))
