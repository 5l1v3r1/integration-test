*** Settings ***
Documentation     Test suite for SFC Function Schedule Algorithm Types, Operates types from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_SCHED_TYPES_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Add Service Function Schedule Algorithm Types
    [Documentation]    Add Service Function Schedule Algorithm Types from JSON file
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_SCHED_TYPES_FILE}
    ${jsonbody}    To Json    ${body}
    ${types}    Get From Dictionary    ${jsonbody}    service-function-scheduler-types
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_SCHED_TYPES_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${type}    Get From Dictionary    ${result}    service-function-scheduler-types
    Lists Should be Equal    ${type}    ${types}

Delete All Service Function Schedule Algorithm Types
    [Documentation]    Delete Service Function Schedule Algorithm Types
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_SCHED_TYPES_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_SCHED_TYPES_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get Ramdom Schedule Algorithm Type
    [Documentation]    Get Ramdom Schedule Algorithm Type
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${elements}=    Create List    random    "enabled":false    service-function-scheduler-type:random
    Check For Elements At URI    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_RANDOM_SCHED_TYPE_URI}

Get A Non-existing Service Function Schedule Algorithm Type
    [Documentation]    Get A Non-existing Service Function Schedule Algorithm Type
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_SCHED_TYPE_URI_BASE}user-defined
    Should Be Equal As Strings    ${resp.status_code}    404

Delete Ramdom Schedule Algorithm Type
    [Documentation]    Delete Ramdom Schedule Algorithm Type
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    Remove All Elements At URI    ${SERVICE_RANDOM_SCHED_TYPE_URI}
    ${elements}=    Create List    random    service-function-scheduler-type:random
    Check For Elements Not At URI    ${SERVICE_SCHED_TYPES_URI}    ${elements}

Delete A Non-existing Service Function Schedule Algorithm Type
    [Documentation]    Delete A Non existing Service Function Schedule Algorithm Type
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_SCHED_TYPES_FILE}
    ${jsonbody}    To Json    ${body}
    ${types}    Get From Dictionary    ${jsonbody}    service-function-scheduler-types
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_SCHED_TYPE_URI_BASE}user-defined
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_SCHED_TYPES_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${type}    Get From Dictionary    ${result}    service-function-scheduler-types
    Lists Should be Equal    ${type}    ${types}

Put one Service Function Schedule Algorithm Type
    [Documentation]    Put one Service Function Schedule Algorithm Type
    Add Elements To URI From File    ${SERVICE_WSP_SCHED_TYPE_URI}    ${SERVICE_WSP_SCHED_TYPE_FILE}
    ${elements}=    Create List    weighted-shortest-path    service-function-scheduler-type:weighted-shortest-path
    Check For Elements At URI    ${SERVICE_WSP_SCHED_TYPE_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_SCHED_TYPES_URI}    ${elements}

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${TEST_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
    Set Suite Variable    ${SERVICE_SCHED_TYPES_FILE}    ${TEST_DIR}/service-schedule-types.json
    Set Suite Variable    ${SERVICE_WSP_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}weighted-shortest-path
    Set Suite Variable    ${SERVICE_WSP_SCHED_TYPE_FILE}    ${TEST_DIR}/service-wsp-schedule-type.json
