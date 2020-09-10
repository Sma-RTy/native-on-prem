*** Settings ***
Documentation    Suite description
Library    ../libraries/Utils.py
Library    ../libraries/resource_mgr/ResourceMgr.py
Library    ../libraries/Virtualization.py
Library    ../libraries/PhysicalMachines.py
Library    ../libraries/CommonSetupTeardown.py
Library    ../libraries/Oek.py
Library    SSHLibrary
Library    Collections
Library    Process
Library    DateTime
Resource    ../keywords/common.robot
Resource    ../keywords/onprem.robot
Resource    ../keywords/oek.robot
Suite Setup    Setup And Deploy
Suite Teardown    CommonSetupTeardown.Suite Teardown
Test Timeout  180 minutes
Force Tags    onprem


*** Test Cases ***

Verify realtime kernel, grub and tuned customization
    [Tags]    ITP/ONP/01/03    onprem
    [Documentation]    Setup different RT kernel, grub parameters and tuned profile

    ${node_vars_path}=    Oek.Get Host Vars File Path    node01
    Restore file backup    ${node_vars_path}

    ${kernel_version}=    Set Variable    3.10.0-1062.9.1.rt56.1033.el7.x86_64

    ${line}=    Set Variable    kernel_version: ${kernel_version}
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    tuned_skip: true
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    additional_grub_params: "debug"
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    hugepage_amount: "500"
    Append To File    ${node_vars_path}    ${line}${\n}

    Log    Host config file content after customization:    console=True
    ${rc}=    Utils.Run And Log Output    cat    ${node_vars_path}    console=True
    Should Be Equal    ${rc}    ${0}

    Virtualization.Revert To Snapshot    node01    ${machines_info['node01']['ip']}    clean
    Set hostname    node01
    Update VM system time    node01

    Deploy Node in Onprem mode

    ${stdout}    ${stderr}    ${rc}=    Run Command On Remote Host
    ...    node01    tuned-adm active    True
    Should Be Equal As Integers    ${rc}    0
    Should Not Contain    ${stdout}    realtime

    ${stdout}    ${stderr}    ${rc}=    Run Command On Remote Host
    ...    node01    cat /proc/cmdline    True
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${stdout}    debug
    Should Contain    ${stdout}    hugepagesz=2M
    Should Contain    ${stdout}    hugepages=500
    Should Contain    ${stdout}    intel_iommu=on
    Should Contain    ${stdout}    iommu=pt
    Should Contain    ${stdout}    ${kernel_version}


Verify non-RT kernel, grub and tuned customization
    [Tags]    ITP/ONP/01/04    onprem
    [Documentation]    Setup different non-RT kernel, grub parameters and tuned profile

    ${node_vars_path}=    Oek.Get Host Vars File Path    node01
    Restore file backup    ${node_vars_path}

    ${kernel_version}=    Set Variable    3.10.0-1062.el7.x86_64

    ${line}=    Set Variable    kernel_repo_url: ""
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    kernel_package: kernel
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    kernel_devel_package: kernel-devel
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    kernel_version: ${kernel_version}
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    tuned_packages:
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Catenate    SEPARATOR=/ - http://linuxsoft.cern.ch/cern/centos/7
    ...    updates/x86_64/Packages/tuned-2.11.0-5.el7_7.1.noarch.rpm
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    tuned_profile: balanced
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    tuned_vars: ""
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    hugepage_amount: "200"
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable
    ...    default_grub_params: "hugepagesz={{ hugepage_size }} hugepages={{ hugepage_amount }}"
    Append To File    ${node_vars_path}    ${line}${\n}

    ${line}=    Set Variable    dpdk_kernel_devel: ""
    Append To File    ${node_vars_path}    ${line}${\n}

    Log    Host config file content after customization:    console=True
    ${rc}=    Utils.Run And Log Output    cat    ${node_vars_path}    console=True
    Should Be Equal    ${rc}    ${0}

    Virtualization.Revert To Snapshot    node01    ${machines_info['node01']['ip']}    clean
    Set hostname    node01
    Update VM system time    node01

    Deploy Node in Onprem mode

    ${cmd}=    Set Variable    tuned-adm active
    @{out}=    Run Command On Remote Host    node01    ${cmd}    True
    Should Be Equal As Integers    ${out[2]}    0
    Should Contain Any    ${out[0]}    balanced    virtual-guest

    # Redirect present, as tuned-adm returns stdout on stderr output, but we also check rc code
    @{out}=    Run Command On Remote Host    node01    tuned-adm --version 2>&1    True
    Should Contain    ${out[0]}    2.11

    @{out}=    Run Command On Remote Host    node01    cat /proc/cmdline    True
    Should Be Equal As Integers    ${out[2]}    0
    Should Contain    ${out[0]}    hugepagesz=2M
    Should Contain    ${out[0]}    hugepages=200
    Should Not Contain    ${out[0]}    intel_iommu=on
    Should Not Contain    ${out[0]}    iommu=pt
    Should Contain    ${out[0]}    ${kernel_version}


*** Keywords ***
Setup And Deploy
    ${controller_names}=    Create List    controller
    ${node_names}=    Create List    node01
    CommonSetupTeardown.Set Machine Name Vars    ${controller_names}    ${node_names}

    CommonSetupTeardown.Add Setup Stage    Setup Machines    recoverable=${False}
    CommonSetupTeardown.Add Setup Stage    Configure OEK    recoverable=${False}
    CommonSetupTeardown.Add Setup Stage    Deploy Controller in Onprem mode    recoverable=${True}
    CommonSetupTeardown.Add Setup Stage    Create Snapshot    recoverable=${True}

    CommonSetupTeardown.Suite Setup


Setup Machines
    ${machines_info}    Create Dictionary

    ${vm}    ${node_info}=    Virtualization.Clone VM    controller
    Set to Dictionary    ${machines_info}    ${vm}    ${node_info}

    ${vm}    ${node_info}=    Virtualization.Clone VM    node01
    ...    domain_xml_path=${ROBOT_BASE_DIR}/resources/xml/default_node_domain.xml
    Set to Dictionary    ${machines_info}    ${vm}    ${node_info}

    Log Dictionary    ${machines_info}
    Set Suite Variable    &{machines_info}

    Set hostname    controller


Configure OEK
    Mark oek node as controller    controller
    Mark oek node as edgenode    node01
    Copy native repo
    Update Oek Config Files
    Oek.Update Inventory File

    ${node_vars_path}=    Oek.Get Host Vars File Path    node01
    Make file backup    ${node_vars_path}


Deploy Controller in Onprem mode
    ${rc}=    Utils.Run And Log Output    ./deploy_onprem.sh    controller
    ...    directory=${deployment_dir}/oek    console=True
    Should Be Equal    ${rc}    ${0}


Create Snapshot
    Virtualization.Create snapshot    controller    deploy    is_custom=False


Deploy Node in Onprem mode
    ${rc}=    Utils.Run And Log Output    ./deploy_onprem.sh    node
    ...    directory=${deployment_dir}/oek    console=True
    Should Be Equal    ${rc}    ${0}
