*** Settings ***
Library    OperatingSystem
Library    Collections
Library    String
Library    Process
Library    yaml
Library    json
Library    ../libraries/Utils.py
Library    ../libraries/Oek.py

*** Keywords ***
Mark oek node as controller
    [Documentation]    Score OEK EdgeNode as an type: controller
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}
    Set To Dictionary    ${machines_info}[${node_name}]    type=controller

Mark oek node as other
    [Documentation]    Score OEK EdgeNode as an type: other
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}
    Set To Dictionary    ${machines_info}[${node_name}]    type=other

Mark oek node as edgenode
    [Documentation]    Score OEK EdgeNode as an type: edgenode
    ...                * node_name is a list of EdgeNodes
    [Arguments]    ${node_name}
    Should Not Be Empty    ${node_name}
    Set To Dictionary    ${machines_info}[${node_name}]    type=edgenode
    
Setup OEK
    Copy native repo
    Update Oek Config Files
    Oek.Update Inventory File

Copy native repo
    [Documentation]    Copy native-on-prem repositories for further use

    Create Directory    ${deployment_dir}/native-on-prem/oek
    Create Directory    ${deployment_dir}/native-on-prem/edgecontroller
    Create Directory    ${deployment_dir}/native-on-prem/edgenode

    # Copy native-on-prem repositories for further use by Robot keywords and tests.
    ${handle} =    Run Process    rsync -r ../../../../../oek/ ./native-on-prem/oek
    ...    shell=True    cwd=${deployment_dir}
    Log    STDOUT: ${handle.stdout}
    Log    STDERR: ${handle.stderr}
    Log    RC: ${handle.rc}
    Should Be Equal    ${handle.rc}    ${0}

    ${handle} =    Run Process    rsync -r ../../../../../edgecontroller/ ./native-on-prem/edgecontroller
    ...    shell=True    cwd=${deployment_dir}
    Log    STDOUT: ${handle.stdout}
    Log    STDERR: ${handle.stderr}
    Log    RC: ${handle.rc}
    Should Be Equal    ${handle.rc}    ${0}

    ${handle} =    Run Process    rsync -r ../../../../../edgenode/ ./native-on-prem/edgenode
    ...    shell=True    cwd=${deployment_dir}
    Log    STDOUT: ${handle.stdout}
    Log    STDERR: ${handle.stderr}
    Log    RC: ${handle.rc}
    Should Be Equal    ${handle.rc}    ${0}

Update Oek Config Files
    [Documentation]    Update global OEK configuration for all files
    # Update global oek all group vars
    ${yml_path}=    Oek.Get Group Vars File Path
    ${yml_content}=    OperatingSystem.Get File    ${yml_path}
    ${yml_data}=    yaml.Safe Load    ${yml_content}
    # - github_token
    Set to Dictionary    ${yml_data}    git_repo_token=${env_config["github_token"]}
    # - proxy (yum)
    Set to Dictionary    ${yml_data}    proxy_yum_url=${env_config["proxy"]["yum"]}
    # - proxy (os)
    ${no_proxy}=    Set Variable    ${env_config["proxy"]["noproxy"]}

    # Add machines hostnames to no_proxy
    FOR    ${machine_name}    IN    @{machines_info}
        ${no_proxy}=    Set Variable    ${no_proxy},${machines_info['${machine_name}']['ip']}
    END

    Set to Dictionary    ${yml_data}    proxy_yum_url=${env_config["proxy"]["yum"]}
    Set to Dictionary    ${yml_data}    proxy_enable=${env_config["proxy"]["enable"]}
    Set to Dictionary    ${yml_data}    proxy_remove_old=${env_config["proxy"]["remove_old"]}
    Set to Dictionary    ${yml_data}    proxy_http=${env_config["proxy"]["http"]}
    Set to Dictionary    ${yml_data}    proxy_https=${env_config["proxy"]["https"]}
    Set to Dictionary    ${yml_data}    proxy_ftp=${env_config["proxy"]["ftp"]}
    Set to Dictionary    ${yml_data}    proxy_noproxy=${no_proxy}
    ${yml_output}=    yaml.Safe Dump    ${yml_data}
    ...    allow_unicode=${False}    sort_keys=${False}
    Remove file    ${yml_path}
    Create File    ${yml_path}    ${yml_output}

    Use Command Line Settings

Use Command Line Settings
    [Documentation]    Use Command Line settings
    Run Keyword If    ${NON_RT_KERNEL}    Disable RT Kernel

