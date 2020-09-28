# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation

# Test Suite collects all Test Cases using a common setup and its filename is a description of a setup, e.g.:
#  - 2 nodes, 1 controller, On-Prem, HDDL role enabled in OEK: OnPrem_2_nodes_1_controller_HDDL.robot
#
# Such Suite granulation is dictated by long setup duration. This way each Test in Suite uses the same machines and in
# Test Setup (which is launched at the beginning of each Test) we can revert all changes caused by previous Tests which
# is much quicker than creating fresh VMs and deploying Openness.

*** Settings ***
Documentation    Suite documentation

# Here you can import custom python libraries. They are needed mainly for using Python libraries which are not exposed
# directly in Robot Framework or for functions which would be cumbersome in Robot because of its syntax limitations.
# E.g. you can't use 'while' loops, nested 'for' loops, 'if' blocks etc.
# Include paths should be relative to the Test Suite file.
Library    ../libraries/Utils.py
Library    ../libraries/Virtualization.py
Library    ../libraries/PhysicalMachines.py
Library    ../libraries/CommonSetupTeardown.py
Library    ../libraries/Oek.py

# Those are Robot Framework libraries (https://robotframework.org/robotframework/).
Library    SSHLibrary
Library    Collections
Library    Process
Library    String
Library    yaml

# Keywords (Robot Framework counterpart of functions) which could be used in different Suites are kept in separate
# files.
Resource    ../keywords/common.robot
Resource    ../keywords/oek.robot

# 'Suite Setup' and 'Suite Teardown' is called once per Suite (before the first and after the last TC). It's a good
# place to Setup the VMs, deploy Openness and other activities which need to be run to have a working environment for
# Tests and then clean it up in Teardown. Common Suite Setup and Suite Teardown are located in CommonSetupTeardown.py
# library and should be used by every Suite.
#
# In this example 'Suite Setup' will run a local keyword 'Setup And Deploy' which calls Common Suite Setup from the
# python library and performs other setup and deployment tasks.
# 'Suite Teardown' directly calls Common Suite Teardown because this is all we need to do in our case. If you need to
# do some additional cleaning up you can create a local teardown keyword and call Common Suite Teardown from there.
Suite Setup    Setup And Deploy
Suite Teardown    CommonSetupTeardown.Suite Teardown

# Default 'Test Setup' and 'Test Teardown' (called for each Test).
# They can be overriden by [Setup] section directly in Test Case body.
#
# In this example we use a local keyword for 'Test Setup' because there's more than 1 thing we need to do.
# For 'Test Teardown' all we need to do is to close all SSH connections.
Test Setup    Test Setup
Test Teardown    Close All Connections

# Time for Suite execution.
Test Timeout  180 minutes

# Enforced tags for each TC in this Suite.
Force Tags    ne

*** Variables ***
@{nic_vfs}=    any    any

*** Test Cases ***
Test Something Important
    [Tags]    tags    for    test
    [Documentation]    Multiline
    ...                test
    ...                documentation

    # Here you should write your test code

Test Another Thing
    [Tags]    different    tags    for    test
    [Documentation]    Multiline
    ...                test
    ...                documentation

    # Here you should write your test code

*** Keywords ***
# This keyword is used as a Suite Setup. It adds Setup Stages and then calls common Suite Setup from CommonSetupTeardown.
# If we are in Developer Mode (enabled when '--devel-vms-conf' param is passed to the starting script) then the setup will start from
# the last unfinished recoverable stage.
Setup And Deploy
    # Because of the fact that the machine names need to be retrieved from the config file, in developer mode we must provide
    # Test-Suite-specific variables that will be set to those names.
    ${controller_names}=    Create List    controller
    ${node_names}=    Create List    node01
    CommonSetupTeardown.Set Machine Name Vars    ${controller_names}    ${node_names}

    # Setup Stages are executed in order they are added.
    # They are used to retry Suite Setup from the last unfinished recoverable stage.
    # Please note that after a recoverable stage is added, all consecutive stages must be recoverable as well.
    CommonSetupTeardown.Add Setup Stage    Setup Machines    recoverable=${False}
    CommonSetupTeardown.Add Setup Stage    Deploy    recoverable=${True}
    CommonSetupTeardown.Add Setup Stage    Create Snapshots    recoverable=${True}

    # Run Setup Stages
    CommonSetupTeardown.Suite Setup

# In this keyword we should create VMs and/or reserve PMs and expose ${machines_info} as a Suite Variable.
Setup Machines
    # This dictionary holds information about VMs such as their IPs, MAC address, their type (controller or edgenode)
    # and others. It is needed by many other keywords.
    ${machines_info}    Create Dictionary

    # Here we are using a clone_vm() method of Virtualization class from Virtualization.py library.
    # Spaces in method name are replaced by underscores and all characters are transformed to lowercase.
    # E.g. we could also write 'Virtualization.CLONE VM' and it would also map to Virtualization.clone_vm() method.
    ${controller}    ${node_info}=    Virtualization.Clone VM    controller
    Set to Dictionary    ${machines_info}    ${controller}    ${node_info}

    ${node01}    ${node_info}=    Virtualization.Clone VM    node01    domain_xml_path=${ROBOT_BASE_DIR}/resources/xml/default_node_domain.xml    nic_vfs=${nic_vfs}
    Set to Dictionary    ${machines_info}    ${node01}    ${node_info}

    # ${machines_info} will be accessible from anywhere in this Suite after setting is as a Suite Variable.
    Log Dictionary    ${machines_info}
    Set Suite Variable    &{machines_info}

    # Machine names will be kept in the following variables
    Set Suite Variable    ${controller}
    Set Suite Variable    ${node01}

    Set hostname    ${controller}
    Set hostname    ${node01}

# Deploy Openness in desired mode.
Deploy
    # For long running tasks we should use Utils.Run And Log Output with console=True parameter in order to print the
    # logs of a command to the screen and to the log file at the same time.
    ${rc}=    Utils.Run And Log Output    ./deploy_ne.sh    directory=${deployment_dir}/oek    console=True
    Should Be Equal    ${rc}    ${0}

# Keyword for 'deploy' snapshot creation
Create Snapshots
    Virtualization.Create snapshot    ${controller}    deploy    is_custom=False
    Virtualization.Create snapshot    ${node01}    deploy    is_custom=False

# Before each Test we should revert the machines to the desired state. Most of the times it's a snapshot created just
# after the deploy is finished.
Test Setup
    Virtualization.Revert to Snapshot    ${controller}    ${machines_info['${controller}']['ip']}    deploy
    Virtualization.Revert to Snapshot    ${node01}    ${machines_info['${node01}']['ip']}    deploy
