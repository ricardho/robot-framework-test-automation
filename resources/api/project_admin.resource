*** Settings ***
Documentation    Project-owned administrator account (SERVEREST_ADMIN_EMAIL + secret
...              SERVEREST_ADMIN_PASSWORD). The public ServeRest is shared and reset from
...              time to time, so the account is (re)created on demand.

Library          ConfigLibrary
Resource         api_common.resource
Resource         login.resource


*** Keywords ***
Get Project Admin Token
    [Documentation]    Logs in as the project administrator, creating the account first if needed.
    ${password}=    Get Required Config    SERVEREST_ADMIN_PASSWORD
    ${response}=    Login Via API    ${SERVEREST_ADMIN_EMAIL}    ${password}
    IF    ${response.status_code} == 401
        Create Project Admin Account    ${password}
        ${response}=    Login Via API    ${SERVEREST_ADMIN_EMAIL}    ${password}
    END
    VAR    ${hint}
    ...    Project admin '${SERVEREST_ADMIN_EMAIL}' cannot log in. If someone else registered this e-mail
    ...    on the public ServeRest, set another SERVEREST_ADMIN_EMAIL.
    ...    separator=${SPACE}
    Should Be Equal As Integers    ${response.status_code}    200    msg=${hint}
    RETURN    ${response.json()}[authorization]

Create Project Admin Account
    [Documentation]    Not tracked for cleanup on purpose: the account is reused by every run.
    ...    A parallel run may create it first; that is fine, the caller logs in again anyway.
    [Arguments]    ${password}
    ${previous_level}=    Set Log Level    WARN
    TRY
        VAR    &{account}
        ...    nome=RF Automation Admin
        ...    email=${SERVEREST_ADMIN_EMAIL}
        ...    password=${password.value}
        ...    administrador=true
        ${response}=    POST On Session    ${SESSION}    /usuarios    json=${account}    expected_status=anything
    FINALLY
        Set Log Level    ${previous_level}
    END
    Log    Project admin account creation returned HTTP ${response.status_code}
