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

Resource    ../keywords/common.robot
Resource    ../keywords/oek.robot

Suite Setup  CommonSetupTeardown.Suite Setup
Suite Teardown    CommonSetupTeardown.Suite Teardown

Test Setup    Setup VMs

Test Timeout  120 minutes

*** Variables ***
${filename}=    /root/custom
${large_filename}=    /root/large

*** Test Cases ***
Create And Revert VM Snapshots
    [Tags]    DEBUG_Create_And_Revert_VM_Snapshots
    [Documentation]     Create And Revert VM Snapshots

    ${vm_names}=    Get Dictionary Keys    ${machines_info}

    FOR    ${vm_name}    IN    @{vm_names}
        Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True
        Execute Command    touch ${filename}
        Close Connection
        Virtualization.Create Snapshot    ${vm_name}    my_snapshot

        Virtualization.Revert to Snapshot    ${vm_name}
        ...    ${machines_info['${vm_name}']['ip']}    clean
        Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True
        ${rc}=    Execute Command    ls ${filename}    return_stdout=False	   return_rc=True
        Should Not Be Equal As Integers    ${rc}    0
        Close Connection

        Virtualization.Revert to Snapshot    ${vm_name}
        ...    ${machines_info['${vm_name}']['ip']}    my_snapshot
        Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True
        ${rc}=    Execute Command    ls ${filename}    return_stdout=False	   return_rc=True
        Should Be Equal As Integers    ${rc}    0
        Close Connection
    END

Create Snapshot With Reserved Name
    [Tags]    DEBUG_Create_Snapshot_With_Reserved_Name
    [Documentation]     Create Snapshot With Reserved Name

    ${vm_names}=    Get Dictionary Keys    ${machines_info}
    ${vm_name}=    Get From List    ${vm_names}    0

    Run Keyword and Expect Error    TypeError: *    Virtualization.Create Snapshot
    ...    ${vm_name}    clean
    Run Keyword and Expect Error    TypeError: *    Virtualization.Create Snapshot
    ...    ${vm_name}    deploy

Test Snapshot Creation On Fail
    [Tags]    DEBUG_Test_Snapshot_Creation_On_Fail
    [Documentation]     Test Snapshot Creation On Fail
    [Teardown]    Run Keywords    CommonSetupTeardown.Test Teardown    Check Snapshot On Fail

    ${vm_names}=    Get Dictionary Keys    ${machines_info}

    FOR    ${vm_name}    IN    @{vm_names}
        Open Connection    ${machines_info['${vm_name}']['ip']}
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True
        Execute Command    touch ${filename}
    END

    Fail    Expected Fail

Reserve Invalid Physical Machine
    [Tags]    DEBUG_Reserve_Invalid_Physical_Machine
    [Documentation]     Reserve Invalid Physical Machine
    [Setup]    Pass Execution    Test Setup not needed

    Run Keyword and Expect Error    LookupError: *    PhysicalMachines.Reserve Physical Machine
    ...    invalid_machine

Reserve One Physical Machine And Test LV Snapshots
    [Tags]    DEBUG_Reserve_One_Physical_Machine_And_Test_LV_Snapshots
    [Documentation]     Reserve One Physical Machine And Test LV Snapshots
    [Setup]    Pass Execution    Test Setup not needed

    Pass Execution If    len(${env_config['physical_machines']}) != 1
    ...    This test requires exactly one entry in 'physical_nodes' dictionary

    # Reserve one machine
    ${machine_name}    ${machine_info}=    PhysicalMachines.Reserve Physical Machine    ${EMPTY}

    # Reserving the same machine for the second time should fail because it is already locked
    Run Keyword and Expect Error    OSError: Not enough free physical machines
    ...    PhysicalMachines.Reserve Physical Machine    ${EMPTY}

    # Release all locks and reserve the machine once again
    PhysicalMachines.Cleanup
    PhysicalMachines.Reserve Physical Machine    ${EMPTY}

    # Create a snapshot, create a large and small files and revert to the snapshot
    ${snapshot_size}=    Set Variable    66.00g
    PhysicalMachines.Create Snapshot    ${machine_name}    test-snap    ${snapshot_size}

    Open Connection    ${machine_info['ip']}    timeout=2 minutes
    Login With Public Key    ${machine_info['username']}    /root/.ssh/id_rsa    look_for_keys=True

    Execute Command    dd if\=/dev/zero of\=${large_filename} bs\=1MB count\=2048
    Execute Command    rm -f ${large_filename}
    Execute Command    touch ${filename}

    Close Connection

    # Revert to test snapshot and recreate it
    PhysicalMachines.Revert To Snapshot And Recreate    ${machine_name}    test-snap

    Open Connection    ${machine_info['ip']}    timeout=2 minutes
    Login With Public Key    ${machine_info['username']}    /root/.ssh/id_rsa    look_for_keys=True

    # File should be missing
    ${rc}=    Execute Command    ls ${filename}    return_stdout=False	   return_rc=True
    Should Not Be Equal As Integers    ${rc}    0

    # test-snap should be present and its size should be the same as the original one
    ${stdout}=    Execute Command    lvs --noheadings --select 'lv_name=test-snap' --options lv_size
    ${new_snapshot_size}=    Strip String     ${stdout}
    Should Be Equal    ${snapshot_size}    ${new_snapshot_size}

    Close Connection

    # Revert without recreating the snapshot
    PhysicalMachines.Revert To Snapshot    ${machine_name}    test-snap

OEK Group Variables Paths
    [Tags]    DEBUG_OEK_Group_Variables_Paths
    [Documentation]     OEK Group Variables Paths
    [Setup]    Pass Execution    Test Setup not needed

    Copy native repo

    Test OEK Variable Paths


*** Keywords ***
Setup VMs
    ${machines_info}    Create Dictionary

    ${vm}=    Virtualization.Clone VM    debug
    Set to Dictionary    ${machines_info}    &{vm}

    ${vm}=    Virtualization.Clone VM    debug2
    Set to Dictionary    ${machines_info}    &{vm}

    Log Dictionary    ${machines_info}
    Set Suite Variable    &{machines_info}

Check Snapshot On Fail
    ${vm_names}=    Get Dictionary Keys    ${machines_info}

    FOR    ${vm_name}    IN    @{vm_names}
        # Custom file should be absent on clean snapshot
        Virtualization.Revert To Snapshot    ${vm_name}    ${machines_info['${vm_name}']['ip']}
        ...    clean

        Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True

        ${rc}=    Execute Command    ls ${filename}    return_stdout=False	   return_rc=True
        Should Not Be Equal As Integers    ${rc}    0

        Close Connection

        # Custom file should be present on a snapshot created after file
        ${last_snap}=    Get From List    ${machines_info['${vm_name}']['snapshots']}    -1
        Virtualization.Revert To Snapshot    ${vm_name}    ${machines_info['${vm_name}']['ip']}
        ...    ${last_snap}

        Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
        Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
        ...    look_for_keys=True

        ${rc}=    Execute Command    ls ${filename}    return_stdout=False	   return_rc=True
        Should Be Equal As Integers    ${rc}    0

        Close Connection
    END

Check First Enabled Second Disabled Role
    [Arguments]    ${role_name}    ${first_role}    ${second_role}

    Should Match Regexp    ${first_role}    ^ *- role: *${role_name}
    Should Match Regexp    ${second_role}    ^ *\# *- role: *${role_name}

Check Unchanged Role
    [Arguments]    ${orig_role}    ${updated_role}

    ${orig_role}=    Strip String    ${orig_role}
    ${updated_role}=    Strip String    ${updated_role}
    Should Be Equal    ${orig_role}    ${updated_role}

Test OEK Variable Paths
    ${all_path}=    Oek.Get Group Vars File Path
    Should Match Regexp    ${all_path}    .*oek/group_vars/all/10-default\\.yml
    OperatingSystem.File Should Exist    ${all_path}

    ${edgenode_path}=    Oek.Get Group Vars File Path    group=edgenode
    Should Match Regexp    ${edgenode_path}    .*oek/group_vars/edgenode/10-default\\.yml$
    OperatingSystem.File Should Exist    ${edgenode_path}

    ${node_vars_path}=    Oek.Get Host Vars File Path    custom_node
    Should Match Regexp    ${node_vars_path}    .*oek/host_vars/custom_node\\.yml$
    OperatingSystem.File Should Exist    ${node_vars_path}

