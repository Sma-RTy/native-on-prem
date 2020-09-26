# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
*** Settings ***
Library    OperatingSystem
Library    String
Library    json
Library    yaml
Library    SSHLibrary
Library    ../libraries/Virtualization.py
Library    ../libraries/Oek.py

*** Keywords ***
Set os proxy on remote
    [Documentation]    Set and execute the proxy on a remote
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${enable_proxy} =    Convert To Boolean    ${env_config["proxy"]["enable"]}
    Return from keyword if    ${enable_proxy} == ${False}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}
    ${yml_path}=    Oek.Get Group Vars File Path
    ${yml_content}=    OperatingSystem.Get File    ${yml_path}
    ${yml_data}=    yaml.Safe Load    ${yml_content}

    Log    Setting up os proxy on remote
    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa
    Execute Command    echo http_proxy=${env_config["proxy"]["http"]} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo HTTP_PROXY=${env_config["proxy"]["http"]} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo https_proxy=${env_config["proxy"]["https"]} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo HTTPS_PROXY=${env_config["proxy"]["https"]} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo ftp_proxy=${env_config["proxy"]["ftp"]} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo FTP_PROXY=${env_config["proxy"]["ftp"]} >> /etc/environment0
    ...    return_stdout=False    return_rc=True
    Execute Command    echo no_proxy=${yml_data['proxy_noproxy']} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Execute Command    echo NO_PROXY=${yml_data['proxy_noproxy']} >> /etc/environment
    ...    return_stdout=False    return_rc=True
    Close Connection


Set yum proxy on remote
    [Documentation]    Set the yum proxy on a remote host
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${enable_proxy} =    Convert To Boolean    ${env_config["proxy"]["enable"]}
    Return from keyword if    ${enable_proxy} == ${False}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}
    Log    Setting up yum proxy on remote
    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa
    ${rc}=    Execute Command    echo proxy=${env_config["proxy"]["yum"]} >> /etc/yum.conf
    ...    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Close Connection


Load global vm env settings
    [Documentation]    Load global settings for Virtual Machine Environment
    ${data_as_string} =    OperatingSystem.Get File    ${ENV_CONFIG_FILE}
    ${data_as_json} =    json.loads    ${data_as_string}
    Set Global Variable    ${env_config}    ${data_as_json}
    Log to console    \nEnv file used: ${ENV_CONFIG_FILE}
    Log to console    ${data_as_json}


Set node name on remote
    [Documentation]    Set VM name on a remote host
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}
    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa
    ${rc}=     Execute Command    hostnamectl set-hostname ${vm_name}
    ...    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Close Connection


Append hostname to hosts file on remote
    [Documentation]    Edit file named hosts on remote host and Append hostname to it
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${cmd}=    Set Variable    sed 's/^\\(127.0.0.1.*\\).*$/\\1\\ ${vm_name}/' -i /etc/hosts
    ${rc}=     Execute Command    ${cmd}    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    ${cmd}=    Set Variable   sed 's/^\\(\\:\\:1.*\\).*$/\\1\\ ${vm_name}/' -i /etc/hosts
    ${rc}=     Execute Command    ${cmd}    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    Close Connection


Set hostname
    [Documentation]    Set hostname in hosts file on remote host
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}

    Should not be empty    ${vm_name}

    Set node name on remote    ${vm_name}
    Append hostname to hosts file on remote    ${vm_name}

    ${hostname}=    Convert To Lower Case    ${vm_name}
    Set To Dictionary    ${machines_info}[${vm_name}]    hostname=${hostname}


Verify os proxy setup
    [Documentation]     Check if proxy setup on OS is correct in proxy settings
    ...                 * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${proxy_settings}=    Oek.Get Proxy Settings

    ${stdout}=    Execute Command    cat /etc/environment
    Should Contain    ${stdout}    http_proxy=${proxy_settings['http_proxy']}
    Should Contain    ${stdout}    https_proxy=${proxy_settings['https_proxy']}
    Should Contain    ${stdout}    ftp_proxy=${proxy_settings['ftp_proxy']}
    Should Contain    ${stdout}    no_proxy=${proxy_settings['no_proxy']}
    Should Contain    ${stdout}    HTTP_PROXY=${proxy_settings['http_proxy']}
    Should Contain    ${stdout}    HTTPS_PROXY=${proxy_settings['https_proxy']}
    Should Contain    ${stdout}    FTP_PROXY=${proxy_settings['ftp_proxy']}
    Should Contain    ${stdout}    NO_PROXY=${proxy_settings['no_proxy']}

    Close Connection


Verify os proxy is disabled
    [Documentation]    Check if proxy on OS is successfully disabled in proxy settings
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}=    Execute Command    cat /etc/environment
    Should Not Contain    ${stdout}    http_proxy=
    Should Not Contain    ${stdout}    https_proxy=
    Should Not Contain    ${stdout}    ftp_proxy=
    Should Not Contain    ${stdout}    no_proxy=
    Should Not Contain    ${stdout}    HTTP_PROXY=
    Should Not Contain    ${stdout}    HTTPS_PROXY=
    Should Not Contain    ${stdout}    FTP_PROXY=
    Should Not Contain    ${stdout}    NO_PROXY=

    ${stdout}=    Execute Command    cat /etc/yum.conf
    Should Not Contain    ${stdout}    proxy=

    Close Connection


Verify service is running
    [Documentation]    Check if service is running
    ...                * vm_name specifies name of the virtual machine
    ...                * service_name specifies name of service
    [Arguments]    ${vm_name}    ${service_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${rc}=    Execute Command    systemctl is-active ${service_name}
    ...    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${stdout}    active

    Close Connection


Verify service is enabled
    [Documentation]    Check if service is successful enabled
    ...                * vm_name specifies name of the virtual machine
    ...                * service_name specifies name of service
    [Arguments]    ${vm_name}    ${service_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${rc}=    Execute Command    systemctl is-enabled ${service_name}
    ...    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${stdout}    enabled

    Close Connection


Verify docker service proxy setup
    [Documentation]    Check if docker service proxy is set up correctly in proxy settings
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${rc}=    Execute Command    systemctl status docker | grep 'Drop-In' -A1
    ...    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Match Regexp    ${stdout}
    ...    Drop-In: /etc/systemd/system/docker\\.service\\.d\\n.*http-proxy\\.conf

    ${proxy_settings}=    Oek.Get Proxy Settings

    ${stdout}=    Execute Command    cat /etc/systemd/system/docker.service.d/http-proxy.conf
    Should Contain    ${stdout}    Environment="HTTP_PROXY=${proxy_settings['http_proxy']}"
    Should Contain    ${stdout}    Environment="HTTPS_PROXY=${proxy_settings['https_proxy']}"
    Should Contain    ${stdout}    Environment="NO_PROXY=${ip},${proxy_settings['no_proxy']}

    ${stdout}=    Execute Command    cat ~/.docker/config.json
    Should Contain    ${stdout}    "httpProxy": "${proxy_settings['http_proxy']}"
    Should Contain    ${stdout}    "httpsProxy": "${proxy_settings['https_proxy']}"
    Should Contain    ${stdout}    "noProxy": "${ip},${proxy_settings['no_proxy']}

    Close Connection


Verify docker service proxy is disabled
    [Documentation]    Check if docker service proxy is successfully disabled in proxy settings
    ...                * vm_name specifies name of the virtual machine
    [Arguments]    ${vm_name}
    Should not be empty    ${vm_name}
    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    SSHLibrary.File Should Not Exist    /etc/systemd/system/docker.service.d/http-proxy.conf
    SSHLibrary.File Should Not Exist     /.docker/config.json

    Close Connection


Verify OpenNESS UI TCP port is listening
    [Documentation]    Check the TCP port of OpenNESS UI if it's listening with 2 minutes timeout
    ...                * controller_name specifies name of the deployment's controller
    [Arguments]    ${controller_name}
    Should not be empty    ${controller_name}
    ${ip}=    Set Variable    ${machines_info['${controller_name}']['ip']}

    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${rc}=    Execute Command    echo > /dev/tcp/${ip}/3000
    ...    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

    Close Connection


Get branch commit id set in env file
    [Documentation]    Return commit id of branch/tag set in environment file
    ...                * node_name is a list of EdgeNodes
    ...                * repo_path is an path to Git repository
    # Return commit id of branch/tag set in env file.
    # This keyword does not have error checking on purpose.
    [Arguments]    ${node_name}    ${repo_path}

    Should not be empty    ${node_name}
    Should not be empty    ${repo_path}

    Run Keyword If     "${node_name}" == ""    Fail    No VM name provided, failing test now
    Run Keyword If     "${repo_path}" == ""    Fail    No path to git repo given, failing test now

    ${type}=    Set Variable    ${machines_info['${node_name}']['type']}
    ${branch_from_env_file}=    Run Keyword If    '${type}' == 'controller'
    ...    Set Variable    ${env_config['edgecontroller']['branch']}
    ...    ELSE IF    '${type}' == 'edgenode'    Set Variable
    ...    ${env_config['edgenode']['branch']}
    ...    ELSE    Fail    Cannot recognize node type

    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${env_commit_id}    ${rc}=    Execute Command
    ...    cd ${repo_path} && git rev-parse origin/${branch_from_env_file}
    ...    return_stdout=True    return_rc=True
    # In case a tag was specified in env file instead of a brach
    # we need to omit 'origin/' in rev-parse
    ${env_commit_id}    ${rc}=    Run Keyword If    ${rc} != 0
    ...    Execute Command    cd ${repo_path} && git rev-parse ${branch_from_env_file}
    ...    return_stdout=True    return_rc=True
    ...    ELSE    Set Variable    ${env_commit_id}    ${rc}


    Should Be Equal    ${rc}    ${0}

    Close Connection

    [Return]    ${env_commit_id}


Get branch HEAD commit id from remote host
    [Documentation]    Return commit id from cloned repo on remote host
    ...                * node_name is a list of EdgeNodes
    ...                * repo_path is an path to Git repository
    [Arguments]    ${node_name}    ${repo_path}
    # This keyword does not have error checking on purpose.

    Run Keyword If     "${node_name}" == ""    Fail    No VM name provided, failing test now
    Run Keyword If     "${repo_path}" == ""    Fail    No path to git repo given, failing test now

    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${node_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True

    ${stdout}    ${stderr}    ${rc}=    Execute Command    cd ${repo_path} && git rev-parse HEAD
    ...    return_stdout=True    return_stderr=True    return_rc=True

    Should Be Equal    ${rc}    ${0}
    Close Connection

    [Return]    ${stdout}


Verify Edge Node enrollment
    [Documentation]    Check if enrollment of EdgeNode was successful
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${rc}=    Execute Command
    ...    docker logs edgenode_appliance_1 2>&1 | grep "Successfully enrolled"
    ...    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${stdout}

    ${stdout}    ${rc}=    Execute Command
    ...    docker logs edgenode_appliance_1 2>&1 | grep "Starting services"
    ...    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${stdout}

    Close Connection


Get Host Internet Access NIC Name
    [Documentation]    Get and return default network interface name
    ...                that is used for accessing the internet
    # Return default network interface name that is used for accessing the internet
    ${iface}=    Run    route | grep '^default' | grep -o '[^ ]*$'
    Should Not Be Empty    ${iface}
    [Return]    ${iface}


Kill All Containers
    [Documentation]    Destroy All existing Containers
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}

    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${node_name}']['username']}    /root/.ssh/id_rsa
    ...    look_for_keys=True

    # Sometimes the container listed in 'docker ps -q' gets destroyed before
    # it is killed so the command fails
    # but eventually all containers are killed. Therefore we don't need to check the return code.
    ${out}=    Execute Command    docker container kill $(docker ps -q)
    ...    return_stderr=True    return_rc=True

    Close Connection


Run Command On Remote Host
    [Documentation]    Run an Command on a Remote Host
    ...                * vm_name specifies name of the virtual machine
    ...                * command represents Service Command
    [Arguments]    ${vm_name}    ${command}    ${ignore_errors}=${False}
    Should Not Be Empty    ${vm_name}
    Should Not Be Empty    ${command}

    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}
    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${command}
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Run Keyword If    "${ignore_errors}" == "${False}"    Should be Equal As Integers    ${rc}    0

    Close Connection
    [Return]    ${stdout}    ${stderr}    ${rc}


Update VM system time
    [Documentation]    Set the system time of Virtual Machine got from hardware clock
    ...                * vm_name specifies name of the virtual machine
    # Set VM system time from hardware clock.
    [Arguments]    ${vm_name}
    Should Not Be Empty    ${vm_name}

    ${ip}=    Set Variable    ${machines_info['${vm_name}']['ip']}
    Open Connection    ${ip}    timeout=2 minutes
    Login With Public Key    root    /root/.ssh/id_rsa

    ${stdout}    ${stderr}    ${rc}=    Execute Command    hwclock --hctosys
    ...    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Log    hw/sw time sync done:${\n}${stdout}
    Close Connection


Make file backup
    [Documentation]    Make file backup by creating new one with .backup suffix
    ...                * path specifies localization of backup file
    # Make file backup by creating new one with .backup suffix
    [Arguments]    ${path}
    OperatingSystem.File Should Exist    ${path}    Source file does not exist
    Remove File    ${path}.backup
    ${rc}=    Run And Return Rc    cp ${path} ${path}.backup
    Should Be Equal As Integers    ${rc}    0


Restore file backup
    [Documentation]    Restore file from given one with .backup suffix
    ...                * path specifies localization of backup file
    # Restore file from given one with .backup suffix
    [Arguments]    ${path}
    OperatingSystem.File Should Exist    ${path}.backup    Backup file does not exist
    Remove File    ${path}
    ${rc}=    Run And Return Rc    cp ${path}.backup ${path}
    Should Be Equal As Integers    ${rc}    0


Filter SRIOV Interfaces
    [Documentation]    Make filter of SRIOV Interfaces
    ...                * node_name is a list of EdgeNodes
    ...                * nics stands for Network Interface Controllers
    [Arguments]    ${node_name}    ${nics}

    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${node_name}']['username']}
    ...    /root/.ssh/id_rsa    look_for_keys=True

    ${sriov_nics}=    Create List

    FOR    ${nic}    IN    @{nics}
        ${sriov_available}=    Run Keyword And Ignore Error
        ...    SSHLibrary.File Should Exist    /sys/bus/pci/devices/${nic}/sriov_numvfs
        Run Keyword If
        ...    ("${sriov_available[0]}" == "PASS" and not ${nics['${nic}']['is_internet_if']})
        ...    Append To List    ${sriov_nics}    ${nics['${nic}']['if']}
    END

    Close Connection
    [Return]    ${sriov_nics}

Get All Non-Internet NICs
    [Documentation]    Gets all non-internet Network Interface Connections
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}
    ${content}=    Catenate    [k for (k, v) in ${machines_info['${node_name}']['nics']}.items()
    ...    if v['is_internet_if'] == False]
    ${nics}    Evaluate    ${content}
    [Return]    ${nics}

Check If File Exists
    [Documentation]    Verify if File Exist
    ...                * node_name is a list of EdgeNodes
    ...                * file_path specifies localization of an file
    [Arguments]    ${node_name}    ${file_path}
    Should not be empty    ${node_name}
    Should not be empty    ${file_path}

    Open Connection    ${machines_info['${node_name}']['ip']}    timeout=2 minutes
    Login With Public Key    ${machines_info['${node_name}']['username']}
    ...    /root/.ssh/id_rsa    look_for_keys=True

    File Should Exist    ${file_path}

    Close Connection
