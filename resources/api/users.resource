*** Settings ***
Documentation    /usuarios endpoint client.
...              ServeRest quirks: "not found" answers 400 (not 404); PUT on an unknown id
...              creates the user (201); DELETE of an unknown id answers 200
...              "Nenhum registro excluído".

Library          Collections
Resource         api_common.resource
Resource         cleanup.resource
Resource         login.resource
Resource         ../data/factories.resource


*** Keywords ***
Create User
    [Documentation]    POST /usuarios. Created users are tracked for cleanup.
    [Arguments]    ${payload}
    ${response}=    POST On Session    ${SESSION}    /usuarios    json=${payload}    expected_status=anything
    IF    ${response.status_code} == 201
        Track User For Cleanup    ${response.json()}[_id]
    END
    RETURN    ${response}

Get User
    [Documentation]    GET /usuarios/{id}.
    [Arguments]    ${user_id}
    ${response}=    GET On Session    ${SESSION}    /usuarios/${user_id}    expected_status=anything
    RETURN    ${response}

Search Users
    [Documentation]    GET /usuarios with query filters, e.g. ``email=a@b.com``.
    [Arguments]    &{filters}
    ${response}=    GET On Session    ${SESSION}    /usuarios    params=${filters}    expected_status=anything
    RETURN    ${response}

Update User
    [Documentation]    PUT /usuarios/{id}. Creates the user when the id does not exist (tracked for cleanup).
    [Arguments]    ${user_id}    ${payload}
    ${response}=    PUT On Session    ${SESSION}    /usuarios/${user_id}    json=${payload}    expected_status=anything
    IF    ${response.status_code} == 201
        Track User For Cleanup    ${response.json()}[_id]
    END
    RETURN    ${response}

Delete User
    [Documentation]    DELETE /usuarios/{id}.
    [Arguments]    ${user_id}
    ${response}=    DELETE On Session    ${SESSION}    /usuarios/${user_id}    expected_status=anything
    RETURN    ${response}

Register New User
    [Documentation]    Creates a user with fresh data and returns its payload plus ``_id``.
    [Arguments]    ${admin}=${False}
    ${user}=    New User Data    admin=${admin}
    ${response}=    Create User    ${user}
    Should Be Equal As Integers    ${response.status_code}    201
    ...    msg=Could not register test user: ${response.text}
    Set To Dictionary    ${user}    _id=${response.json()}[_id]
    RETURN    ${user}

Register And Login New User
    [Documentation]    Like ``Register New User`` and also adds the ``token`` key.
    [Arguments]    ${admin}=${False}
    ${user}=    Register New User    admin=${admin}
    ${token}=    Get Auth Token    ${user}[email]    ${user}[password]
    Set To Dictionary    ${user}    token=${token}
    RETURN    ${user}
