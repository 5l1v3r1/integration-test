*** Settings ***
Documentation     Keywords used to create/modify flow objects. The object is defined in the
...               corresponding FlowLib.py library and contains pertinent fields and methods (e.g.,
...               cookie and barrier fields, string formatted xml that can be used to push to
...               controller). TODO: Remove hard dependency on controller HTTP "session".
Library           XML
Library           String
Library           RequestsLibrary
Library           ScaleClient.py
Library           FlowLib.py
Library           XmlComparator.py
Library           Common.py
Variables         ../variables/Variables.py

*** Keywords ***
Check No Switches In Inventory
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in inventory
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.text}
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        Should Not Contain    ${resp.text}    "openflow:${switch}"
    END

Check No Switches In Topology
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in topology
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        Should Not Contain    ${resp.text}    openflow:${switch}
    END

Check Switches In Inventory
    [Arguments]    ${switches}
    [Documentation]    Check all switches and stats in operational inventory
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}/node/openflow:${switch}
        Log    ${resp.text}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain    ${resp.text}    flow-capable-node-connector-statistics
        Should Contain    ${resp.text}    flow-table-statistics
    END

Check Switches In Topology
    [Arguments]    ${switches}
    [Documentation]    Check switches are in the topology.
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.text}    "node-id":"openflow:
    BuiltIn.Should Be Equal As Numbers    ${count}    ${switches}

Check Number Of Links
    [Arguments]    ${links}
    [Documentation]    Check number of links in the topolgy.
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.text}    "link-id":"openflow:
    Should Be Equal As Integers    ${count}    ${links}

Check Linear Topology
    [Arguments]    ${switches}
    [Documentation]    Check Linear topology.
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        Should Contain    ${resp.text}    "node-id":"openflow:${switch}"
        Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:1"
        Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:2"
        Should Contain    ${resp.text}    "source-tp":"openflow:${switch}:2"
        Should Contain    ${resp.text}    "dest-tp":"openflow:${switch}:2"
        ${edge}    Evaluate    ${switch}==1 or ${switch}==${switches}
        Run Keyword Unless    ${edge}    Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:3"
        Run Keyword Unless    ${edge}    Should Contain    ${resp.text}    "source-tp":"openflow:${switch}:3"
        Run Keyword Unless    ${edge}    Should Contain    ${resp.text}    "dest-tp":"openflow:${switch}:3"
    END

Check Flows Operational Datastore
    [Arguments]    ${flow_count}    ${controller_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Check if number of Operational Flows on member of given index is equal to ${flow_count}.
    ${sw}    ${reported_flow}    ${found_flow}=    ScaleClient.Flow Stats Collected    controller=${controller_ip}
    Should_Be_Equal_As_Numbers    ${flow_count}    ${found_flow}

Check Number Of Flows
    [Arguments]    ${flows}
    [Documentation]    Check number of flows in the inventory.
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.text}    "priority"
    Should Be Equal As Integers    ${count}    ${flows}

Check Number Of Groups
    [Arguments]    ${groups}
    [Documentation]    Check number of groups in the inventory.
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${group_count}=    Get Count    ${resp.text}    "group-type"
    Should Be Equal As Integers    ${group_count}    ${groups}

Check Flow Stats Are Available
    [Arguments]    ${node_id}    ${flows}
    [Documentation]    A GET on the /node/${node_id} inventory API is made and flow stats string is checked for existence.
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}/node/${node_id}/table/2
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain X Times    ${resp.text}    priority    ${flows}

Check Number Of Hosts
    [Arguments]    ${hosts}
    [Documentation]    Check number of hosts in topology
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.text}    "node-id":"host:
    Should Be Equal As Integers    ${count}    ${hosts}

Check No Hosts
    [Documentation]    Check if all hosts are deleted from inventory
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.text}    "node-id":"host:

Add Table Miss Flows
    [Arguments]    ${switches}
    [Documentation]    Add table miss flows to switches.
    ${switches}=    Convert To Integer    ${switches}
    ${data}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/table_miss_flow.json
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        TemplatedRequests.Put As Json To Uri    ${CONFIG_NODES_API}/node/openflow:${switch}/table/0/flow/default    ${data}    session
    END

Check Table Miss Flows
    [Arguments]    ${switches}
    [Documentation]    Check table miss flows in switches.
    ${switches}=    Convert To Integer    ${switches}
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        TemplatedRequests.Get As Json From Uri    ${OPERATIONAL_NODES_API}/node/openflow:${switch}/table/0/flow/default    session
    END

Create Inventory Flow
    [Documentation]    Calls FlowLib.Make_Inventory_Flow function and initializes and sanitizes
    ...    the basic flow elements that can be given to flow:inventory
    ${flow}=    Make Inventory Flow
    [Return]    ${flow}

Create Service Flow
    [Documentation]    Used for creating an object that will use an XML format that
    ...    can be given to flow:service.
    ${flow}=    Make Service Flow
    [Return]    ${flow}

Set "${flow}" "${property}" With "${property_val}"
    [Documentation]    Embedded variables to make higher level keywords more readable.
    ...    There are some cases where the python attribute uses an underscore,
    ...    but a hyphen needs to be used. This seems inconsistent, and may need
    ...    to be looked at from the openflow plugin perspective.
    ...
    ...    At this point, this library will remove the element ${property} from the
    ...    xml representation of the flow and reset with the given value. \ It's not
    ...    possible, yet, to have multiple elements with the same name. \ That will
    ...    likely be needed in the future.
    ${property}    Run Keyword If    "table_id" != "${property}" and "cookie_mask" != "${property}"    Replace String    ${property}    _    -
    ...    ELSE    Set Variable    ${property}
    Remove Flow XML Element    ${flow}    ${property}
    Add Flow XML Element    ${flow}    ${property}    ${property_val}
    Set Flow Field    ${flow}    ${property}    ${property_val}
    [Return]    ${flow}

Set Flow Action
    [Arguments]    ${flow}    ${instruction_order}    ${action_order}    ${action}    ${action_val}=${EMPTY}
    [Documentation]    Will remove the instruction element first, then add the proper xml structure
    ...    to implement the action as given in the arguments
    ##For the case that any of the instruction/apply-actions/action elements are not there we need to add them'
    Remove Flow XML Element    ${flow}    instruction
    Add Flow XML Element    ${flow}    instruction    ${EMPTY}    instructions
    Add Flow XML Element    ${flow}    order    ${instruction_order}    instructions/instruction
    Add Flow XML Element    ${flow}    apply-actions    ${EMPTY}    instructions/instruction
    Add Flow XML Element    ${flow}    action    ${EMPTY}    instructions/instruction/apply-actions
    Add Flow XML Element    ${flow}    order    ${action_order}    instructions/instruction/apply-actions/action
    Add Flow XML Element    ${flow}    ${action}    ${action_val}    instructions/instruction/apply-actions/action
    [Return]    ${flow}

Set Flow Output Action
    [Arguments]    ${flow}    ${instruction_order}    ${action_order}    ${output_port}
    Set Flow Action    ${flow}    ${instruction_order}    ${action_order}    output-action
    Add Flow XML Element    ${flow}    output-node-connector    ${output_port}    instructions/instruction/apply-actions/action/output-action
    [Return]    ${flow}

Set Flow Ethernet Match
    [Arguments]    ${flow}    ${match_value_dict}
    [Documentation]    Specific keyword for adding an ethernet match rules where the elements are given
    ...    in key/value pairs inside the ${match_value_dict} argument. This keyword will also remove any
    ...    existing ethernet-match elements from the flow before adding
    Clear Flow Matches    ${flow}    match/ethernet-match
    Add Flow XML Element    ${flow}    ethernet-match    ${EMPTY}    match
    ${type}=    Get From Dictionary    ${match_value_dict}    type
    Add Flow XML Element    ${flow}    ethernet-type    ${EMPTY}    match/ethernet-match
    Add Flow XML Element    ${flow}    type    ${type}    match/ethernet-match/ethernet-type
    ${src}=    Get From Dictionary    ${match_value_dict}    source
    Add Flow XML Element    ${flow}    ethernet-source    ${EMPTY}    match/ethernet-match
    Add Flow XML Element    ${flow}    address    ${src}    match/ethernet-match/ethernet-source
    ${dst}=    Get From Dictionary    ${match_value_dict}    destination
    Add Flow XML Element    ${flow}    ethernet-destination    ${EMPTY}    match/ethernet-match
    Add Flow XML Element    ${flow}    address    ${dst}    match/ethernet-match/ethernet-destination
    [Return]    ${flow}

Set Flow IPv4 Match
    [Arguments]    ${flow}    ${match_value_dict}
    [Documentation]    Specific keyword for adding an ipv4 match rules where the elements are given
    ...    in key/value pairs inside the ${match_value_dict} argument. This keyword will also remove any
    ...    existing ipv4 match elements from the flow before adding
    Clear Flow Matches    ${flow}    match/ipv4-source
    Clear Flow Matches    ${flow}    match/ipv4-destination
    ${src}=    Get From Dictionary    ${match_value_dict}    source
    Add Flow XML Element    ${flow}    ipv4-source    ${src}    match
    ${dst}=    Get From Dictionary    ${match_value_dict}    destination
    Add Flow XML Element    ${flow}    ipv4-destination    ${dst}    match
    [Return]    ${flow}

Clear Flow Actions
    [Arguments]    ${flow}
    [Documentation]    Will clean out any existing flow actions in the given ${flow} object
    Remove Flow XML Element    ${flow}    instructions/instruction
    [Return]    ${flow}

Clear Flow Matches
    [Arguments]    ${flow}    ${match_element}
    [Documentation]    Will clean out any existing flow matches in the given ${flow} object
    Remove Flow XML Element    ${flow}    match/${match_element}
    [Return]    ${flow}

Set Flow XML Element Attribute
    [Arguments]    ${flow}    ${element}    ${id}    ${value}
    [Documentation]    Will set the given id/value pair to the given to the element provided
    ...    and make the proper changes to the ${flow} object also provided.
    ${flow_xml}=    Parse XML    ${flow.xml}
    Set Element Attribute    ${flow_xml}    ${id}    ${value}    xpath=${element}
    ${xml_string}=    Element To String    ${flow_xml}
    Set Flow Field    ${flow}    xml    ${xml_string}
    Log    ${flow.xml}
    [Return]    ${flow}

Add Flow XML Element
    [Arguments]    ${flow}    ${element}    ${element_val}=${EMPTY}    ${xpath}=.
    [Documentation]    Will modify the current xml representation of the ${flow} object to contain
    ...    the given ${element} at the given ${xpath}. If the ${element} uses a value, that can be
    ...    passed eith the ${element_val} which defaults to ${EMPTY} if not used. NOTE: since there
    ...    are two default parameters to this keyword, if you have an ${xpath} to use, but no ${element_val}
    ...    you will still need to pass ${EMPTY} when invoking so that ${xpath} will end up at the right
    ...    location in the parameter list
    ${flow_xml}=    Parse XML    ${flow.xml}
    Add Element    ${flow_xml}    <${element}>${element_val}</${element}>    xpath=${xpath}
    ${xml_string}=    Element To String    ${flow_xml}
    Set Flow Field    ${flow}    xml    ${xml_string}
    Log    ${flow.xml}
    [Return]    ${flow}

Remove Flow XML Element
    [Arguments]    ${flow}    ${element_xpath}
    [Documentation]    Removes the element at the given ${element_xpath} within the given ${flow}
    ...    object. The ${flow} object's xml representation will be updated to reflect this removal.
    ${flow_xml}=    Parse XML    ${flow.xml}
    Run Keyword And Ignore Error    Remove Elements    ${flow_xml}    xpath=${element_xpath}
    ${xml_string}=    Element To String    ${flow_xml}
    Set Flow Field    ${flow}    xml    ${xml_string}
    [Return]    ${flow}

Add Group To Controller And Verify
    [Arguments]    ${group_body}    ${node_id}    ${group_id}
    [Documentation]    Push group through REST-API and verify in data-store
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/${node_id}/group/${group_id}    headers=${HEADERS_XML}    data=${group_body}
    Log    ${resp.text}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/${node_id}/group/${group_id}    headers=${ACCEPT_XML}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    Compare Xml    ${group_body}    ${resp.text}

Add Flow To Controller And Verify
    [Arguments]    ${flow_body}    ${node_id}    ${table_id}    ${flow_id}
    [Documentation]    Push flow through REST-API and verify in data-store
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/${node_id}/table/${table_id}/flow/${flow_id}    headers=${HEADERS_XML}    data=${flow_body}
    Log    ${resp.text}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/${node_id}/table/${table_id}/flow/${flow_id}    headers=${ACCEPT_XML}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    Compare Xml    ${flow_body}    ${resp.text}

Verify Flow On Mininet Switch
    [Arguments]    ${flow_elements}
    [Documentation]    Checking flow on switch
    Sleep    1
    Write    dpctl dump-flows -O OpenFlow13
    ${switchoutput}    Read Until    >
    FOR    ${flowElement}    IN    @{flow_elements}
        Should Contain    ${switchoutput}    ${flowElement}
    END

Remove Group From Controller And Verify
    [Arguments]    ${node_id}    ${group_id}
    [Documentation]    Remove group and verify
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/${node_id}/group/${group_id}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/${node_id}/group/${group_id}
    Builtin.Return_From_Keyword_If    ${resp.status_code} == 404 or ${resp.status_code} == 409
    Builtin.Log    ${resp.text}
    Builtin.Fail    The request failed with code ${resp.status_code}

Remove Flow From Controller And Verify
    [Arguments]    ${node_id}    ${table_id}    ${flow_id}
    [Documentation]    Remove flow and verify
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/${node_id}/table/${table_id}/flow/${flow_id}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/${node_id}/table/${table_id}/flow/${flow_id}
    Builtin.Return_From_Keyword_If    ${resp.status_code} == 404 or ${resp.status_code} == 409
    Builtin.Log    ${resp.text}
    Builtin.Fail    The request failed with code ${resp.status_code}

Verify Flow Does Not Exist On Mininet Switch
    [Arguments]    ${flow_elements}
    [Documentation]    Checking flow on switch is removed
    Sleep    1
    Write    dpctl dump-flows -O OpenFlow13
    ${switchoutput}    Read Until    >
    FOR    ${flowElement}    IN    @{flow_elements}
        Should Not Contain    ${switchoutput}    ${flowElement}
    END

Remove Default Flows
    [Arguments]    ${node_id}
    [Documentation]    Removes any flows considered "default". one such flow is
    ...    to forward all traffic to the CONTROLLER with priority 0 at flow-table 0
    ...    If/When others are implemented this keyword can be updated to include those.
    ${flow}=    Make Service Flow
    Set "${flow}" "priority" With "0"
    Set "${flow}" "flow-table" With "0"
    Add Flow XML Element    ${flow}    node    /inv:nodes/inv:node[inv:id="${node_id}"]
    Set Flow XML Element Attribute    ${flow}    node    xmlns:inv    urn:opendaylight:inventory
    Log    Flow XML is ${flow.xml}
    write    dpctl dump-flows -O OpenFlow13
    ${switchoutput}    Read Until    >
    ${headers}=    Create Dictionary    Content-Type=application/yang.data+xml
    ${resp}    RequestsLibrary.Post Request    session    restconf/operations/sal-flow:remove-flow    data=${flow.xml}    headers=${headers}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.text}
    Should Not Contain    ${resp.text}    "output-node-connector": "CONTROLLER",
    ${strings_to_check_for}=    Create List    CONTROLLER
    Verify Flow Does Not Exist On Mininet Switch    ${strings_to_check_for}

Create Flow Variables For Suite From XML File
    [Arguments]    ${file}
    [Documentation]    Given the flow XML ${file}, it will create several suite wide variables
    ${data}=    OperatingSystem.Get File    ${file}
    ${xmlroot}=    Parse Xml    ${file}
    ${table_id}=    Get Element Text    ${xmlroot}    table_id
    ${flow_id}=    Get Element Text    ${xmlroot}    id
    ${flow_priority}=    Get Element Text    ${xmlroot}    priority
    ${upddata}=    Get Data For Flow Put Update    ${data}
    Set Suite Variable    ${table_id}
    Set Suite Variable    ${flow_id}
    Set Suite Variable    ${flow_priority}
    Set Suite Variable    ${data}
    Set Suite Variable    ${upddata}
    Set Suite Variable    ${xmlroot}

Check Datastore Presence
    [Arguments]    ${fname}    ${reqconfpres}    ${reqoperpres}    ${upd}    ${check_id}=${False}
    [Documentation]    Checks if flow is properly existing or not existing in the config and operational
    ...    datastores, based on the variables ${reqconfpres} and ${reqoperpres}
    Create Flow Variables For Suite From XML File    ${XmlsDir}/${fname}
    # Note:    ${upddata} and ${data} are suite variables set by the keyword above.
    ${det}=    Set Variable If    ${upd}==${True}    ${upddata}    ${data}
    Log    ${det}
    Check Config Flow    ${reqconfpres}    ${det}
    Check Operational Flow    ${reqoperpres}    ${det}    ${check_id}

Flow Presence In Config Store
    [Arguments]    ${expvalue}
    [Documentation]    Checks the config store for given flow. Returns True if present, otherwise returns False
    ...    This keyword assumes that the global/suite variables are available (${table_id}, ${flow_id} and ${switch_idx}
    ${headers}=    Create Dictionary    Accept=application/xml
    ${resp}=    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    headers=${headers}
    Log    ${resp}
    Log    ${resp.text}
    Return From Keyword If    ${resp.status_code}!=200    ${False}    ${EMPTY}
    ${pres}    ${msg}=    Is Flow Configured    ${expvalue}    ${resp.text}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Return From Keyword    ${pres}    ${msg}

Flow Presence In Operational Store
    [Arguments]    ${expvalue}    ${check_id}=${False}
    [Documentation]    Checks the operational store for given flow. Returns True if present, otherwise returns False
    ...    This keyword assumes that the global/suite variables are available (${table_id}, ${flow_id} and ${switch_idx}
    ${headers}=    Create Dictionary    Accept=application/xml
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}/node/openflow:${switch_idx}/table/${table_id}    headers=${headers}
    Log    ${resp}
    Log    ${resp.text}
    Return From Keyword If    ${resp.status_code}!=200    ${False}    ${EMPTY}
    ${pres}    ${msg}=    Is Flow Operational2    ${expvalue}    ${resp.text}    ${check_id}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Return From Keyword    ${pres}    ${msg}

Get Presence Failure Message
    [Arguments]    ${ds}    ${expected}    ${presence}    ${diffmsg}
    [Documentation]    Utility keyword to help manipulate mesage strings that may be used later to PASS or FAIL with
    Return From Keyword If    '''${diffmsg}'''!='${EMPTY}'    Flow found in ${ds} data store but: ${diffmsg}
    ${msgf}=    Set Variable If    ${expected}==${True}    The flow is expected in ${ds} data store, but    The flow is not expected in ${ds} data store, but
    ${msgp}=    Set Variable If    ${presence}==${True}    it is present.    it is not present.
    Return From Keyword    ${msgf} ${msgp}

Check Config Flow
    [Arguments]    ${expected}    ${expvalue}
    [Documentation]    Wrapper keyword that calls "Flow Presence In Config Store" and "Get Presence Failure Message" from this library
    ...    to verify that the ${expvalue} flow is or is not found in the config store, depending on whether or not it was ${expected}
    ${presence_flow}    ${msg}=    Flow Presence In Config Store    ${expvalue}
    ${msgf}=    Get Presence Failure Message    config    ${expected}    ${presence_flow}    ${msg}
    Should Be Equal    ${expected}    ${presence_flow}    msg=${msgf}

Check Operational Flow
    [Arguments]    ${expected}    ${expvalue}    ${check_id}=${False}
    [Documentation]    Wrapper keyword that calls "Flow Presence In Operational Store" and "Get Presence Failure Message" from this library
    ...    to verify that the ${expvalue} flow is or is not found in the operational store, depending on whether or not it was ${expected}
    ${presence_table}    ${msg}=    Flow Presence In Operational Store    ${expvalue}    ${check_id}
    ${msgf}=    Get Presence Failure Message    operational    ${expected}    ${presence_table}    ${msg}
    Should Be Equal    ${expected}    ${presence_table}    msg=${msgf}

Add Flow Via RPC
    [Arguments]    ${node_id}    ${xmlroot}
    [Documentation]    Deploys a flow specified by given flow details (${node_id}, ${xmlroot}) using add-flow operation.
    ...    ${xmlroot} is an xml object of parser xml flow details, usually created by Create Flow Variables For Suite From XML File
    ...    keyword from this library.
    ${req}=    Copy Element    ${xmlroot}
    Remove Element    ${req}    id    clear_tail=True
    Set Element Tag    ${req}    input
    Set Element Attribute    ${req}    xmlns    urn:opendaylight:flow:service
    Add Element    ${req}    <node>/inv:nodes/inv:node[inv:id="openflow:${node_id}"]</node>
    ${nodeelm}=    Get Element    ${req}    node
    Set Element Attribute    ${nodeelm}    xmlns:inv    urn:opendaylight:inventory
    Log Element    ${req}
    ${strxml}=    Element To String    ${req}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/sal-flow:add-flow    data=${strxml}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Flow Via Restconf
    [Arguments]    ${node_id}    ${table_id}    ${flow_body}
    [Documentation]    Configures a flow specified by given flow details (${node_id}, ${table_id}, ${flow_body}) using POST method
    Log    ${flow_body}
    ${resp}=    RequestsLibrary.Post Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id}    data=${flow_body}
    Log    ${resp.text}
    ${msg}=    Set Variable    Adding flow for ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    204    msg=${msg}

Update Flow Via RPC
    [Arguments]    ${node_id}    ${configured_flow_body}    ${updating_flow_body}
    [Documentation]    Updates a flow by using update-flow operation. ${xmlroot} is usually a variable created by
    ...    Create Flow Variables For Suite From XML File keyword from this library.
    Log    ${configured_flow_body}
    Log    ${updating_flow_body}
    ${xml}    Parse Xml    <input xmlns="urn:opendaylight:flow:service"></input>
    Log Element    ${xml}
    ${origflow}=    Parse Xml    ${configured_flow_body}
    ${updflow}=    Parse Xml    ${updating_flow_body}
    Remove Element    ${origflow}    id    clear_tail=True
    Remove Element    ${updflow}    id    clear_tail=True
    Remove Element Attribute    ${origflow}    xmlns
    Remove Element Attribute    ${updflow}    xmlns
    Set Element Tag    ${origflow}    original-flow
    Set Element Tag    ${updflow}    updated-flow
    Add Element    ${xml}    ${origflow}
    Add Element    ${xml}    ${updflow}
    Add Element    ${xml}    <node>/inv:nodes/inv:node[inv:id="openflow:${node_id}"]</node>
    ${nodeelm}=    Get Element    ${xml}    node
    Set Element Attribute    ${nodeelm}    xmlns:inv    urn:opendaylight:inventory
    Log Element    ${xml}
    ${strxml}=    Element To String    ${xml}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/sal-flow:update-flow    data=${strxml}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200

Update Flow Via Restconf
    [Arguments]    ${node_id}    ${table_id}    ${flow_id}    ${flow_body}
    [Documentation]    Updates a flow configuration by given flow details (${node_id}, ${table_id}, ${flow_body}) using PUT method
    Log    ${flow_body}
    ${resp}=    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id}/flow/${flow_id}    data=${flow_body}
    Log    ${resp.text}
    ${msg}=    Set Variable    Updating flow for ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Delete Flow Via RPC
    [Arguments]    ${node_id}    ${xmlroot}
    [Documentation]    Deletes a flow by using remove-flow opearation. ${xmlroot} is usually a variable created by
    ...    Create Flow Variables For Suite From XML File keyword from this library.
    ${req}=    Copy Element    ${xmlroot}
    Remove Element    ${req}    id    clear_tail=True
    Set Element Tag    ${req}    input
    Set Element Attribute    ${req}    xmlns    urn:opendaylight:flow:service
    Add Element    ${req}    <node>/inv:nodes/inv:node[inv:id="openflow:${node_id}"]</node>
    ${nodeelm}=    Get Element    ${req}    node
    Set Element Attribute    ${nodeelm}    xmlns:inv    urn:opendaylight:inventory
    Log Element    ${req}
    ${strxml}=    Element To String    ${req}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/sal-flow:remove-flow    data=${strxml}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Flow Via Restconf
    [Arguments]    ${node_id}    ${table_id}    ${flow_id}
    [Documentation]    Deletes a flow from configuration datastore specified by given flow details (${node_id}, ${table_id}, ${flow_body}) using DELETE method
    ${resp}=    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id}/flow/${flow_id}
    Log    ${resp.text}
    ${msg}=    Set Variable    Delete flow for ${CONFIG_NODES_API}/node/openflow:${node_id}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Get Flow Id
    [Arguments]    ${dpnid}    ${table_id}    ${flow_element}
    [Documentation]    This verifies specific flow-id for particular table-id matching from the flow element
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:${dpnid}/table/${table_id}
    BuiltIn.Log    ${resp.text}
    @{flow_id} =    String.Get Regexp Matches    ${resp.text}    id\":\"(\\d+${flow_element})    1
    [Return]    @{flow_id}[0]
