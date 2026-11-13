*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    User sign-up through the UI (desktop).

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Setup       Start Desktop Test    /cadastrarusuarios
Test Teardown    End Web Test

Test Tags        web    signup


*** Test Cases ***
Customer signs up
    [Tags]    smoke
    Given new customer data
    When the visitor signs up
    Then the store should be displayed

Administrator signs up
    Given new administrator data
    When the visitor signs up
    Then the administrator home should be displayed

Reject an e-mail that is already registered
    Given an e-mail that is already registered
    When the visitor signs up
    Then the sign-up page should show "Este email já está sendo usado"

Require name, e-mail and password
    Given empty sign-up data
    When the visitor signs up
    Then the sign-up page should list the alerts
    ...    Nome é obrigatório
    ...    Email é obrigatório
    ...    Password é obrigatório


*** Keywords ***
New customer data
    ${user}=    New User Data
    VAR    ${USER}    ${user}    scope=TEST

New administrator data
    ${user}=    New User Data    admin=${True}
    VAR    ${USER}    ${user}    scope=TEST

An e-mail that is already registered
    ${existing}=    Register New User
    ${user}=    New User Data
    Set To Dictionary    ${user}    email=${existing}[email]
    VAR    ${USER}    ${user}    scope=TEST

Empty sign-up data
    VAR    &{user}    nome=${EMPTY}    email=${EMPTY}    password=${EMPTY}    administrador=false
    VAR    ${USER}    ${user}    scope=TEST

The visitor signs up
    Sign Up    ${USER}
    IF    $USER['email']    Track User Created In UI    ${USER}[email]

The store should be displayed
    Get Url    contains    /home
    Get Text    ${STORE_TITLE}    contains    Serverest Store

The administrator home should be displayed
    Get Url    contains    /admin/home
    Get Text    ${ADMIN_WELCOME}    contains    ${USER}[nome]

The sign-up page should show "${message}"
    Get Text    ${SIGNUP_ALERTS}    ==    ${message}

The sign-up page should list the alerts
    [Arguments]    @{expected}
    Get Element Count    ${SIGNUP_ALERTS}    ==    ${{ len($expected) }}
    ${alerts}=    Get Elements    ${SIGNUP_ALERTS}
    FOR    ${alert}    ${message}    IN ZIP    ${alerts}    ${expected}
        Get Text    ${alert}    ==    ${message}
    END
