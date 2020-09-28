# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
*** Settings ***
Library    Oek
Library    Utils

*** Keywords ***
OnPrem Verify controller docker images
    [Documentation]    Verify if docker images are set up
    ...                * controller_name specifies name of the deployment's controller
    [Arguments]    ${controller_name}
    Should not be empty    ${controller_name}
    ${ip}=    Set Variable    ${machines_info['${controller_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}=    Execute Command    docker images
    Should Contain    ${stdout}    cce
    Should Contain    ${stdout}    landing
    Should Contain    ${stdout}    ui
    Should Contain    ${stdout}    mysql
    Should Contain    ${stdout}    node

    Close Connection


OnPrem Verify controller docker containers
    [Documentation]    Verify if docker containers are set up
    ...                * controller_name specifies name of the deployment's controller
    [Arguments]    ${controller_name}
    Should not be empty    ${controller_name}
    ${ip}=    Set Variable    ${machines_info['${controller_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}=    Execute Command    docker ps --filter status="running"
    Should Match Regexp    ${stdout}    edgecontroller_ui_1
    Should Match Regexp    ${stdout}    edgecontroller_landing-ui_1
    Should Match Regexp    ${stdout}    edgecontroller_cce_1
    Should Match Regexp    ${stdout}    edgecontroller_mysql_1

    Close Connection


OnPrem Verify node docker images
    [Documentation]    Verify if node docker images are set up
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should not be empty    ${node_name}
    ${ip}=    Set Variable    ${machines_info['${node_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}=    Execute Command    docker images
    Should Contain    ${stdout}    appliance
    Should Contain    ${stdout}    nts
    Should Contain    ${stdout}    edgednssvr
    Should Contain    ${stdout}    eaa
    Should Contain    ${stdout}    balabit/syslog-ng

    Close Connection


OnPrem Verify node docker containers
    [Documentation]    Verify if node docker containers are set up
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should not be empty    ${node_name}
    ${ip}=    Set Variable    ${machines_info['${node_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}=    Execute Command    docker ps --filter status="running"
    Should Match Regexp    ${stdout}    edgenode_syslog-ng_1
    Should Match Regexp    ${stdout}    edgenode_appliance_1
    Should Match Regexp    ${stdout}    edgenode_eaa_1

    Close Connection


Verify Docker Container Is Running By Name
    [Documentation]    Verify if Docker Container running by names
    ...                * vm_name specifies name of the virtual machine
    ...                * image_name specifies name of the OS image
    [Arguments]    ${vm_name}    ${image_name}
    Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${stdout}=    Execute Command    docker inspect -f '{{.State.Running}}' ${image_name}
    Should Contain    ${stdout}    true
    Close Connection

Set Application Status on Node
    [Documentation]    Set status on an EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * app_name is an application name whose status will be changed
    ...                * state is a variable that specifies state of an Application
    [Arguments]    ${controller_name}    ${node_name}    ${app_name}    ${state}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${app_name}
    Should Not Be Empty    ${app_name}
    ${node_id}=    Get Node ID from Controller  ${controller_name}    ${node_name}
    ${app_id}=    Get Application ID from Controller  ${controller_name}    ${app_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${json}=    Set Variable    { "command": "${state}" }

    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '${json}' --request PATCH
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/apps/${app_id}
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}


Get Application Status on Node
    [Documentation]    Get status on an EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * app_name is an application name whose status will be changed
    [Arguments]    ${controller_name}    ${node_name}    ${app_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${app_name}
    ${node_id}=    Get Node ID from Controller    ${controller_name}    ${node_name}
    ${app_id}=    Get Application ID from Controller    ${controller_name}    ${app_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '{}' --request GET
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/apps/${app_id}
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${app_status}=    Set Variable    ${output['status']}
    [Return]    ${app_status}


Send Interfaces Patch Request to Node
    [Documentation]    Send Interfaces Patch Request to an EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${controller_name}    ${node_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    ${node_id}=    Get Node ID from Controller  ${controller_name}    ${node_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${TOKEN}" --data '{}' --request PATCH
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/interfaces
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}


Deploy Sample App on Node
    [Documentation]    Deploy Sample App on a EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * app_name is an application name whose status will be changed
    [Arguments]    ${controller_name}    ${node_name}    ${app_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${app_name}
    ${node_id}=    Get Node ID from Controller    ${controller_name}    ${node_name}
    ${app_id}=    Get Application ID from Controller    ${controller_name}    ${app_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${json}=    Set Variable    { "id": "${app_id}" }
    ${cmd}=    Catenate    http_proxy= curl -v -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" -X POST --data
    ...    '${json}' http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/apps
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}


Get Node ID from Controller
    [Documentation]    Get Node ID from deployment's controller
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${controller_name}    ${node_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    ${nodes}=    Get List Of Nodes from Controller    ${controller_name}
    ${node_id}=    Set Variable    ${nodes['${node_name}']}
    [Return]    ${node_id}


Get Application ID from Controller
    [Documentation]    Get Application ID from deployment's controller
    ...                * controller_name specifies name of the deployment's controller
    ...                * app_name is an application name whose status will be changed
    [Arguments]    ${controller_name}    ${app_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${app_name}
    ${apps}=    Get List Of Applications from Controller    ${controller_name}
    ${app_id}=    Set Variable    ${apps['${app_name}']}
    [Return]    ${app_id}


Get List Of Nodes from Controller
    [Documentation]    Get List of EdgeNodes and
    ...                return dictionary containg node_name<>node_id pairs
    ...                * controller_name specifies name of the deployment's controller
    # Returns dictionary containing node_name<>node_id pairs
    [Arguments]    ${controller_name}
    Should Not Be Empty    ${controller_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '{}' --request GET
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${nodes_dict}=    Create Dictionary
    FOR    ${node}     IN      @{output['nodes']}
        Set to Dictionary    ${nodes_dict}    ${node['name']}    ${node['id']}
    END
    [Return]    ${nodes_dict}


Get List Of Applications from Controller
    [Documentation]    Get List of Applications and
    ...                return dictionary containing application_name<>application_id pairs
    ...                * controller_name specifies name of the deployment's controller
    # Returns dictionary containing application_name<>application_id pairs
    [Arguments]    ${controller_name}
    Should Not Be Empty    ${controller_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '{}' --request GET
    ...    http://${machines_info['${controller_name}']['ip']}:8080/apps
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${apps_dict}=    Create Dictionary
    FOR    ${app}     IN      @{output['apps']}
        Set to Dictionary    ${apps_dict}    ${app['name']}    ${app['id']}
    END
    [Return]    ${apps_dict}


Add Sample Docker App to Controller
    [Documentation]    Add a Sample Docker App to Controller
    ...                * controller_name specifies name of the deployment's controller
    ...                * app_name is an application name whose status will be changed
    ...                * image_url is an URL with OS image
    [Arguments]    ${controller_name}    ${app_name}    ${image_url}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${app_name}
    Should Not Be Empty    ${image_url}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${json}=    Catenate    { "type": "container", "name": "${app_name}",
    ...    "version": "1", "vendor": "v", "description": "d", "cores": 2, "memory": 2048,
    ...    "ports": [], "source": "${image_url}" }
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '${json}'
    ...    http://${machines_info['${controller_name}']['ip']}:8080/apps
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${app_id}=    Set Variable    ${output['id']}
    [Return]    ${app_id}


Get Access Token For Controller UI
    [Documentation]    Get Access Token for User Interface of Controller
    ...                * controller_name specifies name of the deployment's controller
    [Arguments]    ${controller_name}
    Should Not Be Empty    ${controller_name}
    ${all_group_vars_path}=    Oek.Get Group Vars File Path
    ${ui_password}=    Utils.Get Variable From File    ${all_group_vars_path}    cce_admin_password
    ${ip}=    Set Variable    ${machines_info['${controller_name}']['ip']}
    ${cmd}=    Catenate    http_proxy\= curl -f -H "Content-Type: application/json"
    ...    -d '{"username":"admin","password":"${ui_password}"}'
    ...    http://${machines_info['${controller_name}']['ip']}:8080/auth 2>/dev/null
    ${stdout}=    Run    ${cmd}
    ${token}=    Evaluate    json.loads($stdout)    json

    [Return]    ${token['token']}


Get List Of Network Interfaces IDs from Controller
    [Documentation]    Get IDs of Network Interfaces from Controller and
    ...                return a list containing given Node network interfaces IDs
    ...                * controller_name specifies name of the deployment's controller\
    ...                * node_name is a list of EdgeNodes
    # Return a list containing given Node network interfaces IDs, like 0000:00:03.0
    # Requests sent to controller are done through REST API
    [Arguments]    ${controller_name}    ${node_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    ${node_id}=    Get Node ID from Controller  ${controller_name}    ${node_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=   Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '{}' --request GET
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/interfaces
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${interfaces}=    Set Variable    ${output['interfaces']}
    ${ids_list}=    Create List
    FOR    ${iface}     IN      @{interfaces}
        Append To List    ${ids_list}    ${iface['id']}
    END
    [Return]    ${ids_list}


Get List Of Network Interfaces IDs from Node
    [Documentation]    Get IDs of Network Interfaces from EdgeNode and
    ...                returns a list containing given Node network interfaces ids
    ...                * node_name is a list of EdgeNodes
    # Returns a list containing given Node network interfaces ids, like 00:03.0
    # SSH connection is used to obtain required IDs
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}
    Open Connection    ${machines_info['${node_name}']['ip']}
    Login With Public Key    ${machines_info['${node_name}']['username']}
    ...    /root/.ssh/id_rsa    look_for_keys=True
    ${stdout}=    Execute Command
    ...    lspci | egrep -i --color 'network|ethernet' | awk '{ print $1 }'
    ${ids}=    Split to Lines    ${stdout}
    [Return]    ${ids}


Add Sample VM App to Controller
    [Documentation]    Add a Sample Virtual Machine to Controller
    ...                * controller_name specifies name of the deployment's controller
    ...                * app_name is an application name whose status will be changed
    ...                * image_url is an URL with OS image
    ...                * cores are available CPU cores to be saved to configure of Controller
    ...                * memory is available RAM to be saved to configure of Controller
    [Arguments]    ${controller_name}    ${app_name}    ${image_url}    ${cores}    ${memory}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${app_name}
    Should Not Be Empty    ${image_url}
    Should Not Be Empty    ${cores}
    Should Not Be Empty    ${memory}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${json}=    Catenate    { "type": "vm", "name": "${app_name}", "version": "1",
    ...    "vendor": "v", "description": "d", "cores": ${cores}, "memory": ${memory},
    ...    "ports": [], "source": "${image_url}" }
    ${cmd}=    Set Variable    http_proxy= curl -sS -f -H "Authorization: Bearer ${token}"
    ...    --data '${json}' http://${machines_info['${controller_name}']['ip']}:8080/apps
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    ${app_id}=    Set Variable    ${output['id']}
    [Return]    ${app_id}


Deploy Sample VM on Node
    [Documentation]    Deploy a Sample Virtual Machine od EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${controller_name}    ${node_name}    ${vm_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${vm_name}
    ${node_id}=    Get Node ID from Controller    ${controller_name}    ${node_name}
    ${app_id}=    Get Application ID from Controller    ${controller_name}    ${vm_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${json}=    Set Variable    { "id": "${app_id}" }
    ${cmd}=    Catenate    http_proxy= curl -v -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" -X POST --data '${json}'
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/apps
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}


Verify Docker Container Is Present By Name
    [Documentation]    Check if Docker is present by Names of Virtual Machine and OS image
    ...                * vm_name specifies name of the virtual machine
    ...                * image_name specifies name of the OS image
    [Arguments]    ${vm_name}    ${image_name}
    Should Not Be Empty    ${vm_name}
    Should Not Be Empty    ${image_name}
    Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${stdout}    ${stderr}    ${rc}=    Execute Command
    ...    docker container inspect ${image_name} >/dev/null 2>&1
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal    ${rc}    ${0}
    Close Connection


Send Service Command To Docker Container By Name
    [Documentation]    Send Service Command to Docker Container by Names of Virtual Machine
    ...                and OS image
    ...                * vm_name specifies name of the virtual machine
    ...                * image_name specifies name of the OS image
    ...                * cmd represents Service Command
    [Arguments]    ${vm_name}    ${image_name}    ${cmd}    ${fail_on_error}=${False}
    Should Not Be Empty    ${vm_name}
    Should Not Be Empty    ${image_name}
    Should Not Be Empty    ${cmd}
    Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${stdout}    ${stderr}    ${rc}=    Execute Command    docker ${cmd} ${image_name}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Run Keyword If    "${fail_on_error}" == "${True}"    Should be Equal As Integers    ${rc}    0
    Close Connection


Run Command in Docker Container By Name
    [Documentation]    Run Command in Docker Container by Names of Virtual Machine
    ...                and OS image
    ...                * vm_name specifies name of the virtual machine
    ...                * image_name specifies name of the OS image
    ...                * cmd represents Service Command
    [Arguments]    ${vm_name}    ${image_name}    ${cmd}    ${fail_on_error}=${False}
    Should Not Be Empty    ${vm_name}
    Should Not Be Empty    ${image_name}
    Should Not Be Empty    ${cmd}
    Open Connection    ${machines_info['${vm_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${vm_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True
    ${out}=    Execute Command    docker exec ${image_name} ${cmd}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Run Keyword If    "${fail_on_error}" == "${True}"    Should be Equal As Integers    ${rc}    0
    Close Connection
    [Return]    ${out}


Get App State on Node from Controller
    [Documentation]    Get from controller State of App on an EdgeNode
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * app_name is an application name whose status will be changed
    [Arguments]    ${controller_name}    ${node_name}    ${app_name}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${app_name}
    ${app_id}=    Get Application ID from Controller    ${controller_name}    ${app_name}
    ${node_id}=    Get Node ID From Controller    ${controller_name}    ${node_name}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '{}' --request GET
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/apps/${app_id}
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
    ${output}=    Evaluate    json.loads($stdout)    json
    [Return]    ${output['status']}


Verify App State on Node is in Required State
    [Documentation]    Check if App State on EdgeNode is in right State
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * app_name is an application name whose status will be changed
    ...                * app_state is a variable that specifies state of an Application
    [Arguments]    ${controller_name}    ${node_name}    ${app_name}    ${app_state}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${app_name}
    Should Not Be Empty    ${app_state}
    ${current_app_state}=    Get App State on Node from Controller
    ...    ${controller_name}    ${node_name}    ${app_name}
    Should Be Equal    ${app_state}    ${current_app_state}


Add Node DNS Entry on Controller
    [Documentation]    Add EdgeNode DNS Entry on Controller
    ...                * controller_name specifies name of the deployment's controller
    ...                * node_name is a list of EdgeNodes
    ...                * dns_entry...
    [Arguments]    ${controller_name}    ${node_name}    ${dns_entry}
    Should Not Be Empty    ${controller_name}
    Should Not Be Empty    ${node_name}
    Should Not Be Empty    ${dns_entry}
    ${token}=    Get Access Token For Controller UI    ${controller_name}
    ${node_id}=    Get Node ID From Controller    ${controller_name}    ${node_name}
    ${cmd}=    Catenate    http_proxy= curl -sS -f -H "Content-Type: application/json"
    ...    -H "Authorization: Bearer ${token}" --data '${dns_entry}' --request PATCH
    ...    http://${machines_info['${controller_name}']['ip']}:8080/nodes/${node_id}/dns
    ${rc}    ${stdout}=    Run And Return Rc And Output    ${cmd}
    Should Be Equal    ${rc}    ${0}
