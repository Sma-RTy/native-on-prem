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
Library    Oek
Resource    ../keywords/common.robot
Resource    ../keywords/onprem.robot
Resource    ../keywords/oek.robot
Suite Setup    Setup And Deploy
Suite Teardown    CommonSetupTeardown.Suite Teardown
Test Setup    Onprem Test Setup
Test Teardown    Onprem Test Teardown

Test Timeout  180 minutes
Force Tags    onprem    OnPrem_1_node_1_controller_defaults

*** Variables ***
${vm_app_filename}    test_vm_app.qcow2
${vm_app_username}    root
${vm_app_password}    root

*** Test Cases ***

Verify that entries added to EdgeDNS through Controller UI can be resolved
    [Tags]    ITP/ONP/02/04
    [Documentation]    Name resolution for entries added through Controller UI
    ...                * and matching local.mec domain
    Build Sample Apps
    Download Producer and Consumer Sample App Files from build_vm
    Upload Producer and Consumer Sample App Files to Controler WWW Folder
    # Upload test_vm app to Controler WWW Folder

    ${fqdn}=    Set Variable    test.edgenode1.local.mec
    ${dns_query_cmd}=    Set Variable    ping ${fqdn} -c 1
    ${dns_json_content}=    CATENATE    SEPARATOR=
    ...    {
    ...      "name":"Sample DNS configuration",
    ...      "records":{
    ...        "a":[
    ...          {
    ...            "name":"${fqdn}",
    ...            "description": "dns local entry",
    ...            "alias":false,
    ...            "values":[
    ...              "192.168.122.1"
    ...            ]
    ...          }
    ...        ]
    ...      }
    ...    }

    # Send PATCH request so that nts and edgednssvr will fully start
    Wait Until Keyword Succeeds    1 min    10s    Send Interfaces Patch Request to Node
    ...    ${controller}    ${node01}
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    nts
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    mec-app-edgednssvr

    Add Node DNS Entry on Controller    ${controller}    ${node01}    ${dns_json_content}

    # 1/2 Test DNS from Sample Docker App

    #Add app to controller and deploy on node
    Add Sample Docker App to Controller    ${controller}    producer
    ...    https://${machines_info['${controller}']['ip']}/producer.tar
    Deploy Sample App on Node    ${controller}    ${node01}    producer

    # Verify sample app is deployed properly and in running state
    ${app_id}=    Get Application ID from Controller    ${controller}    producer
    Wait Until Keyword Succeeds    2 min    10s     Verify Docker Container Is Present By Name
    ...    ${node01}    ${app_id}
    Send Service Command to Docker Container By Name    ${node01}    ${app_id}    start
    Wait Until Keyword Succeeds    2 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    ${app_id}

    # Send DNS query and verify response
    Open Connection    ${machines_info['${node01}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${node01}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${stdout}    ${stderr}    ${rc}=    Execute Command    docker run -t ${app_id} ${dns_query_cmd}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${rc}    ${0}

    # # 2/2 - Test DNS form Sample VM

    # Add Sample VM app to Controller    ${controller}    test_vm
    #    https://${machines_info['${controller}']['ip']}/${vm_app_filename}    1    1024
    # Deploy Sample VM on Node    ${controller}    ${node01}    test_vm
    # Wait Until Keyword Succeeds    3 min    30s    Verify App State on Node is in Required State
    # ...    ${controller}    ${node01}    test_vm    deployed

    # ${vm_app_id}=    Get Application ID from Controller    ${controller}    test_vm

    # Open Connection    ${machines_info['${node01}']['ip']}    timeout=4 minutes
    # Login    ${machines_info['${node01}']['username']}    ${env_config['vm']['password']}
    # # - start VM on remote
    # ${stdout}    ${stderr}    ${rc}=    Execute Command    virsh start ${vm_app_id}
    # ...    return_stdout=True    return_stderr=True    return_rc=True
    # Should Be Equal    ${rc}    ${0}
    # # - wait for virtual OS to be ready; we assume 1 min at most
    # # to let it bring up all services (including sshd)
    # Sleep    60
    # # - obtain VM IP address via virsh command
    # ${content}=    Catenate    virsh domifaddr --source lease ${vm_app_id}
    #...    | grep ipv4 | awk '{ print $4 }' | awk -F/ '{ print $1 }'
    # ${vm_app_ip}    ${stderr}    ${rc}=    Execute Command    ${content}
    #...    return_stdout=True    return_stderr=True    return_rc=True
    # Should Be Equal    ${rc}    ${0}
    # Close Connection
    # # - run query from Robot host
    # ${content}=    Catenate    ssh -o StrictHostKeyChecking=no -J
    # ...    ${env_config['vm']['username']}@${machines_info['${node01}']['ip']}
    # ...    ${vm_app_username}@${vm_app_ip} ${dns_query_cmd}
    # ${cmd}=    Set Variable    ${content}
    # ${rc}    ${stdout}=    Run and Return RC and Output    ${cmd}
    # Should Be Equal    ${rc}    ${0}


Verify that internet names resolution works
    [Tags]    ITP/ONP/02/03
    [Documentation]    Verify name resolution google.com for VMs and containers
    Build Sample Apps
    Download Producer and Consumer Sample App Files from build_vm
    Upload Producer and Consumer Sample App Files to Controler WWW Folder
    # Upload test_vm app to Controler WWW Folder

    # Send PATCH request so that nts and edgednssvr will fully start
    Wait Until Keyword Succeeds    1 min    10s    Send Interfaces Patch Request to Node
    ...    ${controller}    ${node01}
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    nts
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    mec-app-edgednssvr

    # 1/2 Test Sample Docker App

    # Add app to ${controller} and deploy on node
    Add Sample Docker App to Controller    ${controller}    producer
    ...    https://${machines_info['${controller}']['ip']}/producer.tar
    Deploy Sample App on Node    ${controller}    ${node01}    producer

    # Verify sample app is deployed properly and in running state
    ${id}=    Get Application ID from Controller    ${controller}    producer
    Wait Until Keyword Succeeds    2 min    10s     Verify Docker Container Is Present By Name
    ...    ${node01}    ${id}
    Send Service Command to Docker Container By Name    ${node01}    ${id}    start
    Wait Until Keyword Succeeds    2 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    ${id}

    # Verification steps
    ${stdout}    ${stderr}    ${rc}=    Run Command in Docker Container By Name
    ...    ${node01}    ${id}    nslookup google.com
    Should Be Equal    ${rc}    ${0}

    # # 2/2 Test Sample VM

    # Add Sample VM app to Controller    ${controller}    test_vm
    # ...    https://${machines_info['${controller}']['ip']}/${vm_app_filename}    2    1024
    # Deploy Sample VM on Node    ${controller}    ${node01}    test_vm
    # ${id}=    Get Application ID from Controller    ${controller}    test_vm

    # Wait Until Keyword Succeeds    3 min    30s    Verify App State on Node is in Required State
    # ...    ${controller}    ${node01}    test_vm    deployed

    # # Connect to Node, start VM (default is offline)
    # Open Connection    ${machines_info['${node01}']['ip']}    timeout=4 minutes
    # Login    ${machines_info['${node01}']['username']}    ${env_config['vm']['password']}
    # ${stdout}    ${stderr}    ${rc}=    Execute Command    virsh start ${id}    return_stdout=True
    # ...    return_stderr=True    return_rc=True
    # Should Be Equal    ${rc}    ${0}

    # # Wait for virtual OS to be ready; we assume 1 min at most to let
    # # it bring up all services (including sshd)
    # Sleep    60

    # # Obtain vm app IP address via virsh command
    # ${content}=    Catenate        virsh domifaddr --source lease ${id} | grep ipv4
    # ...    | awk '{ print $4 }' | awk -F/ '{ print $1 }'
    # ...    return_stdout=True    return_stderr=True    return_rc=True
    # ${vm_app_ip}    ${stderr}    ${rc}=    Execute Command    ${content}
    # Should Be Equal    ${rc}    ${0}

    # Close Connection

    # # Run dns query check
    # ${cmd}=    Set Variable     nslookup google.com
    # ${content}=    Catenate    sshpass -p '${vm_app_password}' ssh -o StrictHostKeyChecking=no
    # ...    -o PubkeyAuthentication=no -J
    # ...    ${env_config['vm']['username']}@${machines_info['${node01}']['ip']}
    # ...    ${vm_app_username}@${vm_app_ip} ${cmd}
    # ${rc}    ${stdout}=    Run and Return RC and Output    ${content}
    # Should Be Equal    ${rc}    ${0}


Verify OpenNESS services name resolution in a container and a VM
    [Tags]    ITP/ONP/02/02
    [Documentation]    Verify name resolution of eaa.community.appliance.mec and
    ...                syslog.community.appliance.mec works
    Build Sample Apps
    Download Producer and Consumer Sample App Files from build_vm
    Upload Producer and Consumer Sample App Files to Controler WWW Folder
    # Upload test_vm app to Controler WWW Folder

    # Send PATCH request so that nts and edgednssvr will fully start
    Wait Until Keyword Succeeds    1 min    10s    Send Interfaces Patch Request to Node
    ...    ${controller}    ${node01}
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    nts
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    mec-app-edgednssvr

    # 1/2 Test Sample Docker App

    # Add app to ${controller} and deploy on node
    Add Sample Docker App to Controller    ${controller}    producer
    ...    https://${machines_info['${controller}']['ip']}/producer.tar
    Deploy Sample App on Node    ${controller}    ${node01}    producer

    # Verify sample app is deployed properly and in running state
    ${id}=    Get Application ID from Controller    ${controller}    producer
    Wait Until Keyword Succeeds    2 min    10s    Verify Docker Container Is Present By Name
    ...    ${node01}    ${id}
    Send Service Command to Docker Container By Name    ${node01}    ${id}    start
    Wait Until Keyword Succeeds    2 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    ${id}

    # Verification steps
    ${stdout}    ${stderr}    ${rc}=    Run Command in Docker Container By Name    ${node01}
    ...    ${id}    nslookup eaa.openness
    Should Be Equal    ${rc}    ${0}

    ${stdout}    ${stderr}    ${rc}=    Run Command in Docker Container By Name    ${node01}
    ...    ${id}    nslookup syslog.openness
    Should Be Equal    ${rc}    ${0}

    # # 2/2 Test Sample VM

    # Add Sample VM app to Controller    ${controller}    test_vm
    # ...    https://${machines_info['${controller}']['ip']}/${vm_app_filename}    2    1024
    # Deploy Sample VM on Node    ${controller}    ${node01}    test_vm
    # ${id}=    Get Application ID from Controller    ${controller}    test_vm

    # Wait Until Keyword Succeeds    3 min    30s    Verify App State on Node is in Required State
    # ...    ${controller}    ${node01}    test_vm    deployed

    # # Connect to Node, start VM (default is offline)
    # Open Connection    ${machines_info['${node01}']['ip']}    timeout=4 minutes
    # Login    ${machines_info['${node01}']['username']}    ${env_config['vm']['password']}
    # ${stdout}    ${stderr}    ${rc}=    Execute Command    virsh start ${id}
    # ...    return_stdout=True    return_stderr=True    return_rc=True
    # Should Be Equal    ${rc}    ${0}

    # # Wait for virtual OS to be ready; we assume 1 min at most
    # # to let it bring up all services (including sshd)
    # Sleep    60

    # # Obtain vm app IP address via virsh command
    # ${content}=    Catenate    virsh domifaddr --source lease ${id} | grep ipv4 | awk
    # ...   '{ print $4 }' | awk -F/ '{ print $1 }'
    # ...    return_stdout=True    return_stderr=True    return_rc=True
    # ${vm_app_ip}    ${stderr}    ${rc}=    Execute Command    ${content}
    # Should Be Equal    ${rc}    ${0}

    # Close Connection

    # # Run dns query check (1of2)
    # ${cmd}=    Set Variable     nslookup syslog.openness
    # ${content}=    Catenate    sshpass -p '${vm_app_password}' ssh
    # ...    -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -J
    # ...    ${env_config['vm']['username']}@${machines_info['${node01}']['ip']}
    # ...    ${vm_app_username}@${vm_app_ip} ${cmd}
    # ${rc}    ${stdout}=    Run and Return RC and Output    ${content}
    # Should Be Equal    ${rc}    ${0}

    # # Run dns query check (2of2)
    # ${cmd}=    Set Variable     nslookup eaa.openness
    # ${conent}=    Catenate    sshpass -p '${vm_app_password} ssh -o StrictHostKeyChecking=no -o
    # ...    PubkeyAuthentication=no -J
    # ...    ${env_config['vm']['username']}@${machines_info['${node01}']['ip']}
    # ...    ${vm_app_username}@${vm_app_ip} ${cmd}
    # ${rc}    ${stdout}=    Run and Return RC and Output    ${content}
    # Should Be Equal    ${rc}    ${0}


Get Edge Node interfaces
    [Tags]    ITP/ONP/02/06
    [Documentation]    Get available network interfaces from Controller (through Rest API) and
    ...                EdgeNode. Verify if the amount of interfaces matches
    ...                (no requirements available)
    # Send PATCH request so that nts and edgednssvr will fully start
    Wait Until Keyword Succeeds    1 min    10s    Send Interfaces Patch Request to Node
    ...    ${controller}    ${node01}
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    nts
    Wait Until Keyword Succeeds    1 min    10s    Verify Docker Container Is Running By Name
    ...    ${node01}    mec-app-edgednssvr

    # Get Node interfaces IDs from Controller (REST API)
    ${ctrl_list}=    Get List of Network Interfaces IDs from Controller
    ...    ${controller}    ${node01}

    # Get Node interfaces directly from Node (directly from OS)
    ${node_list}=    Get List of Network Interfaces IDs from Node    ${node01}

    ${ctrl_list_count}=    Get Length    ${ctrl_list}
    ${node_list_count}=    Get Length    ${node_list}
    Should Be Equal    ${ctrl_list_count}    ${node_list_count}


Consumer and Producer Sample Apps deployment in OnPrem Mode with Stand Alone EAA
    [Documentation]    Verify if Consumer and Producer Sample Apps are able to
    ...                communicate to Stand Alone EAA and EAA is able to
    ...                communicate with EVA in Appliance (in OnPrem Mode)
    [Tags]    ITP/ONP/02/01
    Build Sample Apps
    Download Producer and Consumer Sample App Files from build_vm
    Upload Producer and Consumer Sample App Files to Controler WWW Folder
    # Upload test_vm app to Controler WWW Folder

    # Send PATCH request so that nts and edgednssvr will fully start
    # Timeout is present, to make sure all internal communication starts
    Wait Until Keyword Succeeds    1 min    10s    Send Interfaces Patch Request to Node
    ...    ${controller}    ${node01}
    Sleep    60

    Add Sample Docker App to Controller    ${controller}    producer
    ...    https://${machines_info['${controller}']['ip']}/producer.tar
    Add Sample Docker App to Controller    ${controller}    consumer
    ...    https://${machines_info['${controller}']['ip']}/consumer.tar
    Deploy Sample App on Node    ${controller}    ${node01}    producer
    Deploy Sample App on Node    ${controller}    ${node01}    consumer

    # We wait until Controller informs Node about app presence and
    # Node deploys it through Docker service. It is assumed to take ~1 min
    # Instead of using UI, we check apps states by sending http requests
    Log    Waiting for sample apps to be deployed on Node...    console=True

    FOR    ${index}    IN RANGE    30
        ${producer}=    Get Application Status on Node    ${controller}    ${node01}    producer
        ${consumer}=    Get Application Status on Node    ${controller}    ${node01}    consumer
        Log    ...application statuses returned: ${producer} ${consumer}
        Run Keyword If    ("${producer}" == "deployed") and ("${consumer}" == "deployed")
        ...    Exit For Loop
        Sleep    10
    END
    Run Keyword If    ${index} == 29    Fail
    ...    Producer or Consumer app was not deployed successfully

    ${producer_app_id}=    Get Application ID from Controller    ${controller}  producer
    ${consumer_app_id}=    Get Application ID from Controller    ${controller}  consumer

    # Establish connection to ${node01}, as all Docker checks will be run there
    Open Connection    ${machines_info['${node01}']['ip']}    timeout=2 minutes    alias=node01
    Login With Public Key    ${machines_info['${node01}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${prod_content}=    Catenate    docker ps -a | grep
    ...    ${producer_app_id}.*Created.*${producer_app_id}
    ${stdout}=    Execute Command    ${prod_content}
    Should Not Be Empty    ${stdout}
    ${cons_content}=    Catenate    docker ps -a | grep
    ...    ${consumer_app_id}.*Created.*${consumer_app_id}
    ${stdout}=    Execute Command    ${cons_content}
    Should Not Be Empty    ${stdout}

    # Start Producer sample app on ${node01} and verify logs
    Set Application Status on Node    ${controller}    ${node01}    producer    start
    Sleep    60
    ${app_status}=    Get Application Status on Node    ${controller}    ${node01}    producer
    Should Contain    ${app_status}    running

    Verify Docker Container Is Running By Name    ${node01}     ${producer_app_id}

    Switch Connection    node01
    Wait Until Keyword Succeeds    1 min    10s    Check Producer Logs    ${producer_app_id}

    # Start Consumer sample app on ${node01} and verify logs
    Set Application Status on Node    ${controller}    ${node01}    consumer    start
    Sleep    10
    ${app_status}=    Get Application Status on Node    ${controller}    ${node01}    consumer
    Should Contain    ${app_status}    running

    Verify Docker Container Is Running By Name    ${node01}     ${producer_app_id}

    Switch Connection    node01
    Wait Until Keyword Succeeds    1 min    10s    Check Consumer Logs    ${consumer_app_id}


Deploy Edge Controller in OnPrem mode
    [Tags]    ITP/ONP/01/01    onprem
    [Documentation]    Test walks through controller deployment procedure and asserts that:
    ...                * edgecontroller repository is checked out
    ...                * docker is installed and configured
    ...                * openness containers are running
    Verify os proxy setup    ${controller}
    Verify service is running    ${controller}    docker
    Verify service is enabled    ${controller}    docker
    Verify docker service proxy setup    ${controller}
    OnPrem Verify controller docker images    ${controller}
    OnPrem Verify controller docker containers    ${controller}
    Verify OpenNESS UI TCP port is listening    ${controller}
    ${env_commit_id}=    Get branch commit id set in env file
    ...    ${controller}    /opt/edgecontroller
    ${remote_commit_id}=    Get branch HEAD commit id from remote host
    ...    ${controller}    /opt/edgecontroller
    Should Be Equal    ${env_commit_id}    ${remote_commit_id}


Deploy Edge Node in OnPrem mode
    [Tags]    ITP/ONP/01/02    onprem
    [Documentation]    Test walks through node deployment procedure and asserts that:
    ...                * edgenode repository is checked out
    ...                * docker is installed and configured
    ...                * openness containers are running
    Verify os proxy setup    ${node01}
    Verify service is running    ${node01}    docker
    Verify service is enabled    ${node01}    docker
    Verify docker service proxy setup    ${node01}
    OnPrem Verify node docker images    ${node01}
    OnPrem Verify node docker containers    ${node01}
    ${env_commit_id}=    Get branch commit id set in env file    ${node01}    /opt/edgenode
    ${remote_commit_id}=    Get branch HEAD commit id from remote host
    ...    ${node01}    /opt/edgenode
    Should Be Equal    ${env_commit_id}    ${remote_commit_id}
    Verify Edge Node enrollment    ${node01}


*** Keywords ***
Setup And Deploy
    ${controller_names}=    Create List    controller
    ${node_names}=    Create List    node01
    CommonSetupTeardown.Set Machine Name Vars    ${controller_names}    ${node_names}

    CommonSetupTeardown.Add Setup Stage    Setup Machines    recoverable=${False}
    CommonSetupTeardown.Add Setup Stage    Configure OEK    recoverable=${False}
    CommonSetupTeardown.Add Setup Stage    Build VM Proxy    recoverable=${True}
    CommonSetupTeardown.Add Setup Stage    Deploy    recoverable=${True}
    CommonSetupTeardown.Add Setup Stage    Create Snapshots    recoverable=${True}

    CommonSetupTeardown.Suite Setup


Onprem Test Setup
    ${controller_content}=    Catenate    ${machines_info['${controller}']['is_physical']}
    ...    or ${machines_info['${node01}']['is_physical']}
    Run Keyword Unless    ${controller_content}    Virtualization.Revert to Snapshot
    ...    ${controller}    ${machines_info['${controller}']['ip']}    deploy
    ${node_content}=    Catenate    ${machines_info['${controller}']['is_physical']}
    ...    or ${machines_info['${node01}']['is_physical']}
    Run Keyword Unless    ${node_content}    Virtualization.Revert to Snapshot
    ...    ${node01}    ${machines_info['${node01}']['ip']}    deploy


Onprem Test Teardown
    Open Connection    ${machines_info['build_vm']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['build_vm']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    Execute Command    rm -rf ~/edgeapps

    Close All Connections
    CommonSetupTeardown.Test Teardown


Setup Machines
    ${machines_info}    Create Dictionary

    ${vm_args}=    Create Dictionary    vm_clone_name=controller
    ${pm_args}=    Create Dictionary    machine_name=${EMPTY}
    ${machine_type}=    Set Variable    controller

    ${controller}    ${node_info}=    Clone VM Or Reserve Physical Machine
    ...    ${machine_type}    ${vm_args}    ${pm_args}
    Set to Dictionary    ${machines_info}    ${controller}    ${node_info}

    ${vm_args}=    Create Dictionary    vm_clone_name=node01
    ...    domain_xml_path=${ROBOT_BASE_DIR}/resources/xml/default_node_domain.xml
    ${pm_args}=    Create Dictionary    machine_name=${EMPTY}
    ${machine_type}=    Set Variable    edgenode

    ${node01}    ${node_info}=    Clone VM Or Reserve Physical Machine
    ...    ${machine_type}    ${vm_args}    ${pm_args}
    Set to Dictionary    ${machines_info}    ${node01}    ${node_info}

    ${build_vm}    ${node_info}=    Virtualization.Clone VM    build_vm
    Set to Dictionary    ${machines_info}    ${build_vm}    ${node_info}

    Log Dictionary    ${machines_info}
    Set Suite Variable    &{machines_info}
    Set Suite Variable    ${controller}
    Set Suite Variable    ${node01}

    Run Keyword Unless    ${machines_info['${controller}']['is_physical']}    Set hostname
    ...    ${controller}
    Run Keyword Unless    ${machines_info['${node01}']['is_physical']}    Set hostname
    ...    ${node01}


Configure OEK
    Mark oek node as controller    ${controller}
    Mark oek node as edgenode    ${node01}
    Mark oek node as other    build_vm
    Copy native repo
    Update Oek Config Files
    Oek.Update Inventory File

Build VM Proxy
    Set os proxy on remote    build_vm
    Set yum proxy on remote    build_vm


Deploy
    # Normal Controller and Node deploy, equal to Ansible manual method.
    ${rc}=    Utils.Run And Log Output    ./deploy_onprem.sh    directory=${deployment_dir}/native-on-prem/oek
    ...    console=True
    Should Be Equal    ${rc}    ${0}


Create Snapshots
    ${controller_content}=    Catenate    ${machines_info['${controller}']['is_physical']}
    ...    or ${machines_info['${node01}']['is_physical']}
    Run Keyword Unless    ${controller_content}    Virtualization.Create snapshot
    ...    ${controller}    deploy    is_custom=False
    ${node_content}=    Catenate    ${machines_info['${controller}']['is_physical']}
    ...    or ${machines_info['${node01}']['is_physical']}
    Run Keyword Unless    ${node_content}    Virtualization.Create snapshot
    ...    ${node01}    deploy    is_custom=False

    Append To List    ${machines_info['${controller}']['snapshots']}    deploy
    Append To List    ${machines_info['${node01}']['snapshots']}    deploy


Build Sample Apps
    Open Connection    ${machines_info['build_vm']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['build_vm']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True

    Log    Check if apps were already built    console=True
    ${content}=    Catenate    ls -1 ~/ | grep -E "producer.tar|consumer.tar"
    ...    | wc -l
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Return From Keyword If    ${stdout} == ${2}

    # Set up build environment and build sample Docker apps - Producer and Consumer.
    # Applications are stored in /root on build_vm folder as producer.tar and consumer.tar
    Log    Download epel repo    console=True
    ${out}=    Execute Command    yum -y install epel-release
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Download base packages    console=True
    ${content}=    Catenate    yum -y install git mc nano dstat python3-pip yum-utils
    ...    device-mapper-persistent-data lvm2
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Download docker-compose    console=True
    ${out}=    Execute Command   pip3 install docker-compose==1.24.1
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Download Docker repo   console=True
    ${content}=    Catenate    yum-config-manager --add-repo
    ...    https://download.docker.com/linux/centos/docker-ce.repo
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Download Docker    console=True
    ${content}=    Catenate    yum -y install docker-ce-19.03.2 docker-ce-cli-19.03.2
    ...    containerd.io
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Enable Docker service    console=True
    ${out}=    Execute Command   systemctl enable docker
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Add proxy to docker service and env file    console=True
    # 1/2 Generate multiline user config file and save it
    ${proxy_settings}=    Oek.Get Proxy Settings
    ${config_dir}=    Set Variable    /etc/systemd/system/docker.service.d
    ${config_file}=    Set Variable    ${config_dir}/http-proxy.conf
    ${rc}=    Execute Command    mkdir -p ${config_dir}
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal    ${rc}    ${0}
    ${content}=    Catenate    SEPARATOR=\n    "[Service]
    ...    Environment=\\"HTTP_PROXY=${proxy_settings['http_proxy']}\\"
    ...    Environment=\\"HTTPS_PROXY=${proxy_settings['https_proxy']}\\"
    ...    Environment=\\"NO_PROXY=${proxy_settings['no_proxy']}\\""
    ${rc}=    Execute Command    echo -e ${content} > ${config_file}
    ...    return_stdout=False    return_stderr=False    return_rc=True

    # 2/2 Generate multiline use config file and save it
    ${config_dir}=    Set Variable    /root/.docker
    ${config_file}=    Set Variable    ${config_dir}/config.json
    ${rc}=    Execute Command    mkdir -p ${config_dir}
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal    ${rc}    ${0}
    ${content}=    CATENATE    SEPARATOR=    "
    ...    {
    ...      \\"proxies\\": {
    ...        \\"default\\": {
    ...          \\"httpProxy\\": \\"${proxy_settings['http_proxy']}\\",
    ...          \\"httpsProxy\\": \\"${proxy_settings['https_proxy']}\\"
    ...        }
    ...      }
    ...    }
    ...    "
    ${out}=    Execute Command    echo -E ${content} > ${config_file}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Reload systemd    console=True
    ${out}=    Execute Command   systemctl daemon-reload
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Restart Docker service    console=True
    ${out}=    Execute Command   systemctl restart docker
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Create folder structure    console=True
    ${out}=    Execute Command    mkdir -p ~/edgeapps ~/go ~/images
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Get and extract golang package    console=True
    ${content}=    Catenate    git config --global
    ...    url."https://${env_config["github_token"]}@github.com/".insteadOf "https://github.com/"
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Get get edgeapps repo    console=True
    ${out}=    Execute Command    git clone ${env_config["edgeapps"]["url"]} ~/edgeapps
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Switch to required edgeapps branch or tag    console=True
    ${out}=    Execute Command    cd ~/edgeapps && git checkout ${env_config["edgeapps"]["branch"]}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Get golang package    console=True
    ${content}=    Catenate    curl https://dl.google.com/go/go1.12.13.linux-amd64.tar.gz
    ...    --output /tmp/go.tar.gz
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Extract golang package    console=True
    ${out}=    Execute Command    tar xf /tmp/go.tar.gz -C ~/go
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Append path to go binary to PATH variable    console=True
    ${out}=    Execute Command    echo "export PATH=$PATH:~/go/go/bin/" >> /root/.bashrc
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Make sure golang binary is reachable via ssh    console=True
    ${out}=    Execute Command    echo $PATH; go version
    ...     return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Add bind-utils yum package to producer and consumer containers    console=True
    ${content}=    Catenate    sed '/^FROM .*/a RUN yum install -y
    ...    bind-utils' -i ~/edgeapps/applications/sample-app/simpleEaaProducer/Dockerfile
    ${out}=    Execute Command    ${content}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}
    ${content}=    Catenate    sed '/^FROM .*/a RUN yum install -y
    ...    bind-utils' -i ~/edgeapps/applications/sample-app/simpleEaaConsumer/Dockerfile
    ${out}=    Execute Command    ${content}    return_stdout=True
    ...    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Build sample apps    console=True
    ${out}=    Execute Command    cd ~/edgeapps/applications/sample-app && make build-docker
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Export sample apps to disk    console=True
    ${out}=    Execute Command    docker save producer:1.0 > ~/producer.tar
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Log    Export sample apps to disk    console=True
    ${out}=    Execute Command    docker save consumer:1.0 > ~/consumer.tar
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${out[2]}    ${0}

    Close Connection


Download Producer and Consumer Sample App Files from build_vm
    ${producer_exists}=    Run Keyword And Ignore Error
    ...    OperatingSystem.File Should Exist    ${deployment_dir}/producer.tar
    ${consumer_exists}=    Run Keyword And Ignore Error
    ...    OperatingSystem.File Should Exist    ${deployment_dir}/consumer.tar
    ${content}=    Catenate    ("${producer_exists[0]}" == "PASS")
    ...    and ("${consumer_exists[0]}" == "PASS")
    Return From Keyword If    ${content}
    Log    Download sample apps from build_vm   console=True
    Open Connection    ${machines_info['build_vm']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['build_vm']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    SSHLibrary.Get File    /root/producer.tar    ${deployment_dir}/
    SSHLibrary.Get File    /root/consumer.tar    ${deployment_dir}/
    Close Connection


Upload Producer and Consumer Sample App Files to Controler WWW Folder
    Log    Upload sample apps to controller    console=True
    Open Connection    ${machines_info['${controller}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${controller}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    SSHLibrary.Put File    ${deployment_dir}/producer.tar    /var/www/html/
    SSHLibrary.Put File    ${deployment_dir}/consumer.tar    /var/www/html/
    Close Connection


Upload test_vm app to Controler WWW Folder
    Log    Upload test_vm_app to build_vm    console=True
    Open Connection    ${machines_info['${controller}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${controller}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    SSHLibrary.Put File    ${ROBOT_BASE_DIR}/resources/vm/${vm_app_filename}    /var/www/html/
    Close Connection

Check Producer Logs
    [Arguments]    ${producer_app_id}

    ${stdout}=    Execute Command    docker logs ${producer_app_id} 2>&1
    Should Contain    ${stdout}
    ...    ExampleNotification 1.0.0 Description for Event #1 by Example Producer
    ${stdout}=    Execute Command    docker logs edgenode_eaa_1
    Should Not Contain    ${stdout}    Cannot get App ID from EVA
    ${stdout}=    Execute Command    docker logs edgenode_appliance_1
    Should Not Contain    ${stdout}    error    case_insensitive=True

Check Consumer Logs
    [Arguments]    ${consumer_app_id}

    ${stdout}=    Execute Command    docker logs ${consumer_app_id} 2>&1
    Should Contain    ${stdout}    Received notification
    ${stdout}=    Execute Command    docker logs edgenode_eaa_1
    Should Not Contain    ${stdout}    Cannot get App ID from EVA
    ${stdout}=    Execute Command    docker logs edgenode_appliance_1
    Should Not Contain    ${stdout}    error    case_insensitive=True
