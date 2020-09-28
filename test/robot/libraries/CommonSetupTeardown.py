# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
import json
import os
import subprocess
from pathlib import Path

from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn

import pymysql


class CommonSetupTeardown(object):
    """Class for interacting with openness-experience-kits module.
    """

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'
    INVALID_ID = -1

    def __init__(self):
        self._setup_stages = list()
        self._setup_last_id = self.INVALID_ID

        self._controller_name_vars = []
        self._node_name_vars = []

        self._DEFAULT_SQLITE_DB_PATH = "{}/db/resource.db".format(BuiltIn().get_variable_value("${ROBOT_BASE_DIR}"))

    def _validate_setup_conf(self, devel_vms_conf):
        if 'setup' not in devel_vms_conf:
            raise RuntimeError("'setup' information not available in Machines Info cfg file, please re-run the tests with fresh setup.")

        num_stages_ts = len(self._setup_stages)
        num_stages_conf = len(devel_vms_conf['setup']['stages'])

        if num_stages_ts != num_stages_conf:
            raise RuntimeError("Setup configuration incompatible! Number of stages in TestSuite: {}, number of stages in config file: {}.".format(
                num_stages_ts, num_stages_conf))

        # Check if all stages in Test Suite match the corresponding stage in config file.
        for ts_stage, conf_stage in zip(self._setup_stages, devel_vms_conf['setup']['stages']):
            if ts_stage != conf_stage:
                raise RuntimeError("Setup configuration incompatible. Test Suite stage '{}' differs from corresponding config stage '{}'.".format(
                    ts_stage, conf_stage))

        if devel_vms_conf['setup']['last_id'] == self.INVALID_ID:
            raise RuntimeError("Previous execution failed before Setup started, please re-run the tests with fresh setup.")

    def _set_node_names_from_config(self, suite_controller_names, suite_node_names, machines_info):
        # Find controller machines in cfg
        controllers = list(filter(lambda machine: machines_info[machine]['type'] == 'controller', machines_info))
        logger.info('Controller machines: {}'.format(controllers))
        if len(controllers) != len(suite_controller_names):
            raise RuntimeError('Suite Controller names ({}) and Config Controller names ({}) number mismatch'.format(suite_controller_names, controllers))

        # Set controller names as suite variables
        for suite_controller_name, controller in zip(suite_controller_names, controllers):
            logger.info("Setting ${{{}}} = '{}'".format(suite_controller_name, controller), also_console=True)
            BuiltIn().set_suite_variable("${{{suite_controller_name}}}".format(suite_controller_name=suite_controller_name), controller)

        # Find node machines in cfg
        nodes = list(filter(lambda machine: machines_info[machine]['type'] == 'edgenode', machines_info))
        logger.info('Node machines: {}'.format(nodes))
        if len(nodes) != len(suite_node_names):
            raise RuntimeError('Suite Node names ({}) and Config Node names ({}) number mismatch'.format(suite_node_names, nodes))

        # Set node names as suite variables
        for suite_node_name, node in zip(suite_node_names, nodes):
            logger.info("Setting ${{{}}} = '{}'".format(suite_node_name, node), also_console=True)
            BuiltIn().set_suite_variable("${{{suite_node_name}}}".format(suite_node_name=suite_node_name), node)

    def _set_sqlite_default_conf(self, env):
        # Set a default path for SQLite Resource DB file if it's not provided
        if 'url' not in env['resource_db'] or not env['resource_db']['url']:
            Path(self._DEFAULT_SQLITE_DB_PATH).parent.mkdir(parents=True, exist_ok=True)

            env['resource_db']['url'] = self._DEFAULT_SQLITE_DB_PATH
            BuiltIn().set_suite_variable("${env_config}", env)

    def _provide_default_values(self, env):
        # Resource DB configuration
        if env['resource_db']['backend'] == 'sqlite':
            self._set_sqlite_default_conf(env)


    def clean_node_enrollment_from_controller(self, controller_ip):
        """Cleans node enrollment data from controller database
        """
        db_connection = pymysql.connect(
        host=controller_ip,
        port=8083,
        user="root",
        passwd="pass",
        database="controller_ce"
        )

        db_cursor = db_connection.cursor()

        db_cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        db_cursor.execute("TRUNCATE TABLE node_grpc_targets")
        db_cursor.execute("TRUNCATE TABLE credentials")
        db_cursor.execute("TRUNCATE TABLE nodes")
        db_cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

        db_connection.close()

    def load_global_vm_env_settings(self):
        """Loads config from ${ENV_CONFIG_FILE} and exposes it as a global variable ${env_config}.
        """

        env_conf_file = BuiltIn().get_variable_value("${ENV_CONFIG_FILE}")
        with open(env_conf_file, 'r') as f:
            env_config = json.load(f)

            # Set default values for omitted fields
            self._provide_default_values(env_config)
            BuiltIn().set_global_variable('${env_config}', env_config)

            logger.info('\nEnv file used: {}'.format(env_conf_file), also_console=True)
            logger.info('{}'.format(env_config), also_console=True)


    def set_deployment_workdir(self):
        """Sets the deployment workdir as a Suite Variable ${deployment_dir}.

        The deployment workdir is a folder created by test execution which created currently used VMs (it's not a current
        workdir when in devel mode).
        It is created by joining execution workdir with Suite Name: ${ROBOT_WORK_DIR}/${SUITE NAME}
        """

        vms_conf_path = BuiltIn().get_variable_value("${DEVEL_VMS_CONF}")
        if vms_conf_path:
            # In Devel mode
            with open(vms_conf_path, 'r') as f:
                devel_vms_conf = json.load(f)
            BuiltIn().set_suite_variable("${deployment_dir}", devel_vms_conf['workdir'])
        else:
            workdir = BuiltIn().get_variable_value("${ROBOT_WORK_DIR}")
            assert workdir is not None, "${ROBOT_WORK_DIR} is None!"

            suite_name = BuiltIn().get_variable_value("${SUITE NAME}")
            assert suite_name is not None, 'SUITE NAME variable is not set!'

            utils_lib = BuiltIn().get_library_instance('Utils')

            deployment_dir = os.path.join(workdir, utils_lib.sanitize_testsuite_name(suite_name))
            if not os.path.exists(deployment_dir):
                os.makedirs(deployment_dir)

            BuiltIn().set_suite_variable("${deployment_dir}", deployment_dir)

    def set_machine_name_vars(self, controller_name_vars=[], node_name_vars=[]):
        """Set machine name variables.

        Given variables will be set to machine names from Machine Info config file.

        :param [str] controller_name_vars: List of Controller machine name variables.
        :param [str] node_name_vars: List of Node machine name variables.
        """

        self._controller_name_vars = controller_name_vars
        self._node_name_vars = node_name_vars
        logger.info('Controller name variables set to: {}'.format(self._controller_name_vars))
        logger.info('Node name variables set to: {}'.format(self._node_name_vars))

    def add_setup_stage(self, keyword, *keyword_args, **config_kwargs):
        """Add a Setup Stage.

        Keyword will be executed with *args when suite_setup() is called.
        If a stage is recoverable it will be retried in next test execution in developer mode when
        --devel-vms-conf is passed as an argument.
        Setup Stages will be executed in order they were added.
        Once a recoverable stage is added all consecutive stages must be recoverable as well.

        :param str keyword: Stage keyword
        :param list keyword_args: Keyword arguments
        :param dict config_kwargs: Stage configuration arguments. List of configuration options:
            :param bool recoverable: Indicates whether the stage can be retried in consecutive executions.
                                     Most likely recoverable stages go after VM creation and PM reservation.
        """

        # Stage configuration options with default values
        config_options = {
            'recoverable': False
        }

        # Get options from config_kwargs
        for opt in config_kwargs:
            if opt not in config_options:
                raise KeyError("'{}' parameter not found in accepted arguments: {}".format(opt, ", ".join(config_options.keys())))
        config_options[opt] = config_kwargs[opt]

        stage_dict = {'keyword': keyword, 'keyword_args': list(keyword_args), 'recoverable': config_options['recoverable']}

        # Make sure unrecoverable stage isn't added after recoverable one
        if self._setup_stages:
            if not config_options['recoverable'] and self._setup_stages[-1]['recoverable']:
                raise ValueError("Can't add unrecoverable stage '{}' after recoverable one: '{}'".format(
                    stage_dict, self._setup_stages[-1]))

        self._setup_stages.append(stage_dict)
        logger.info('Added setup stage {}'.format(stage_dict))

    def suite_setup(self):
        """Common Suite Setup - loads VMs config from file if in devel mode and executes Setup Stages added with add_setup_stage().
        """

        self.load_global_vm_env_settings()
        self.set_deployment_workdir()

        virtualization_lib = BuiltIn().get_library_instance('Virtualization')
        physical_machines_lib = BuiltIn().get_library_instance('PhysicalMachines')
        oek_lib = BuiltIn().get_library_instance('Oek')
        resource_mgr_lib = BuiltIn().get_library_instance('ResourceMgr')

        # Set environment config
        env = BuiltIn().get_variable_value("${env_config}")
        virtualization_lib.set_environment_config(env)
        physical_machines_lib.set_environment_config(env)
        oek_lib.set_environment_config(env)

        # Connect to Resource DB
        resource_mgr_lib.connect(**env['resource_db'])

        vms_conf_path = BuiltIn().get_variable_value("${DEVEL_VMS_CONF}")
        if vms_conf_path:
            with open(vms_conf_path, 'r') as f:
                devel_vms_conf = json.load(f)

            self._validate_setup_conf(devel_vms_conf)

            # Get last setup stage ID
            setup_id = devel_vms_conf['setup']['last_id']
            if setup_id < len(self._setup_stages) and \
                not self._setup_stages[setup_id]['recoverable']:
                raise RuntimeError("Can't retry unrecoverable setup stage '{}'".format(self._setup_stages[setup_id]))

            # Update the libraries using machines info file
            BuiltIn().set_suite_variable("${machines_info}", devel_vms_conf['machines'])
            virtualization_lib.use_existing_setup(devel_vms_conf['run_uid'])

            physical_machines = list()
            machines = devel_vms_conf['machines']
            for machine in machines:
                if machines[machine]['is_physical']:
                    physical_machines_lib.update_snapshot_list(machine, machines[machine]['snapshots'])
                    physical_machines.append(machine)

            physical_machines_lib.use_machines(physical_machines)

            # Set variables provided in set_machine_name_vars() to the names from devel_vms_conf
            self._set_node_names_from_config(self._controller_name_vars, self._node_name_vars, machines)

            logger.info('DEVEL MODE: Machines configuration loaded from a file: {}'.format(vms_conf_path), also_console=True)
        else:
            setup_id = 0

        # Run setup stages
        while True:
            self._setup_last_id = setup_id
            if setup_id >= len(self._setup_stages):
                break

            stage = self._setup_stages[setup_id]

            logger.info('------', also_console=True)
            logger.info('{}. Setup Stage: {}'.format(setup_id+1, stage), also_console=True)
            logger.info('------', also_console=True)
            BuiltIn().run_keyword(stage['keyword'], *stage['keyword_args'])

            setup_id += 1

    def suite_teardown(self):
        """Common Suite Teardown.
        """

        devel_dump = BuiltIn().get_variable_value("${DEVEL_DUMP}")
        vms_conf_path = BuiltIn().get_variable_value("${DEVEL_VMS_CONF}")

        virtualization_lib = BuiltIn().get_library_instance('Virtualization')
        physical_machines_lib = BuiltIn().get_library_instance('PhysicalMachines')
        utils_lib = BuiltIn().get_library_instance('Utils')

        # Make sure ${deployment_dir} is set
        if not BuiltIn().get_variable_value("${deployment_dir}"):
            self.set_deployment_workdir()

        # Dump machines config file
        if devel_dump == 'True' or vms_conf_path:
            machines_info = BuiltIn().get_variable_value("${machines_info}")
            utils_lib.dump_machines_config(machines_info, virtualization_lib.get_run_uid(),
                {'stages': self._setup_stages, 'last_id': self._setup_last_id})

        force_cleanup = BuiltIn().get_variable_value("${FORCE_CLEANUP}")

        if force_cleanup == 'True':
            virtualization_lib.return_vfs_to_host()
            virtualization_lib.cleanup()
            physical_machines_lib.cleanup()
        elif devel_dump == 'False' and vms_conf_path is None:
            # Not in devel mode
            suite_status = BuiltIn().get_variable_value("${SUITE STATUS}")
            assert suite_status is not None, "${SUITE STATUS} is None!"

            physical_machines_lib.cleanup()
            virtualization_lib.return_vfs_to_host()

            if suite_status == 'PASS':
                virtualization_lib.cleanup()
            else:
                virtualization_lib.suspend_vms()

    def test_teardown(self):
        """Common Test Teardown - creates a snapshot if TC failed.
        """

        test_status = BuiltIn().get_variable_value("${TEST STATUS}")
        assert test_status is not None, "${TEST STATUS} is None!"

        force_cleanup = BuiltIn().get_variable_value("${FORCE_CLEANUP}")

        if test_status == 'FAIL' and force_cleanup == 'False':
            time_string = os.popen(r'date +%H-%M-%S-%3N').read().strip()
            test_name = BuiltIn().get_variable_value("${TEST NAME}")
            test_name = test_name.replace(' ', '_').replace('/', '_')

            snapshot_name = "{}_{}".format(time_string, test_name)

            virtualization_lib = BuiltIn().get_library_instance('Virtualization')

            machines_info = BuiltIn().get_variable_value("${machines_info}")
            for machine in machines_info:
                if not machines_info[machine]['is_physical']:
                    virtualization_lib.create_snapshot(machine, snapshot_name)
                    machines_info[machine]['snapshots'].append(snapshot_name)

            BuiltIn().set_suite_variable("${machines_info}", machines_info)

    def clone_vm_or_reserve_physical_machine(self, machine_type, vm_args, pm_args):
        virtualization_lib = BuiltIn().get_library_instance('Virtualization')
        physical_machines_lib = BuiltIn().get_library_instance('PhysicalMachines')

        use_phys_controller = BuiltIn().get_variable_value("${USE_PHYSICAL_CONTROLLERS}")
        logger.info('USE_PHYSICAL_CONTROLLERS = {}'.format(use_phys_controller), also_console=True)

        use_phys_node = BuiltIn().get_variable_value("${USE_PHYSICAL_NODES}")
        logger.info('USE_PHYSICAL_NODES = {}'.format(use_phys_node), also_console=True)

        logger.info('Machine type: {}'.format(machine_type), also_console=True)
        logger.info('PM arguments: {}'.format(pm_args), also_console=True)
        logger.info('VM arguments: {}'.format(vm_args), also_console=True)

        if machine_type == 'controller':
            if use_phys_controller == 'True':
                return physical_machines_lib.reserve_physical_machine(**pm_args)
            else:
                return virtualization_lib.clone_vm(**vm_args)
        elif machine_type == 'edgenode':
            if use_phys_node == 'True':
                return physical_machines_lib.reserve_physical_machine(**pm_args)
            else:
                return virtualization_lib.clone_vm(**vm_args)
