*** Settings ***
Documentation    Shared HTTP session and response assertions for the ServeRest API.
...              Endpoint keywords return the response; Gherkin steps store it in the
...              test variable ${RESPONSE} so the assertion steps below can read it.

Library          Collections
Library          RequestsLibrary
Library          JsonSchemaLibrary


*** Variables ***
${SESSION}    serverest


*** Keywords ***
Create ServeRest API Session
    [Documentation]    One session per suite (and per Pabot process). Accept is a single exact value:
    ...    some APIs reject the multi-value Accept that HTTP clients send by default.
    ...    The public ServeRest occasionally resets connections: retry with backoff on network
    ...    errors and gateway statuses (502/503/504) instead of failing the test.
    ...    POST is left out on purpose: it is not idempotent, and resending a request the server
    ...    already processed creates duplicates ("Este email já está sendo usado"). Connection
    ...    errors raised before the request is sent are still retried for every method.
    VAR    &{headers}    Accept=application/json    Content-Type=application/json
    VAR    @{retry_statuses}    ${502}    ${503}    ${504}
    VAR    @{retry_methods}    GET    PUT    DELETE
    Create Session    ${SESSION}    ${API_BASE_URL}    headers=${headers}    disable_warnings=${True}
    ...    max_retries=3    backoff_factor=0.5    retry_status_list=${retry_statuses}
    ...    retry_method_list=${retry_methods}

Auth Header
    [Documentation]    Header dictionary with the ``Bearer`` token returned by POST /login.
    [Arguments]    ${token}
    VAR    &{headers}    Authorization=${token}
    RETURN    ${headers}

Keep Response
    [Documentation]    Stores the response for the assertion steps of the current test.
    [Arguments]    ${response}
    VAR    ${RESPONSE}    ${response}    scope=TEST

The Response Status Should Be
    [Documentation]    Asserts the HTTP status of the last kept response, showing the body on failure.
    [Arguments]    ${expected_status}
    Should Be Equal As Integers    ${RESPONSE.status_code}    ${expected_status}
    ...    msg=Expected HTTP ${expected_status} but got ${RESPONSE.status_code}. Body: ${RESPONSE.text}

The Response Message Should Be
    [Documentation]    Asserts the ``message`` field of the last kept response.
    [Arguments]    ${expected_message}
    The Response Field Should Be    message    ${expected_message}

The Response Field Should Be
    [Documentation]    Asserts one top-level field of the last kept response (validation errors are keyed by field).
    [Arguments]    ${field}    ${expected_value}
    VAR    ${body}    ${RESPONSE.json()}
    Dictionary Should Contain Key    ${body}    ${field}    msg=Field '${field}' not found in ${body}
    Should Be Equal    ${body}[${field}]    ${expected_value}

The Response Should Match Schema
    [Documentation]    Validates the last kept response against a file in ``resources/schemas``.
    [Arguments]    ${schema_file}
    Json Should Match Schema    ${RESPONSE.json()}    ${schema_file}
