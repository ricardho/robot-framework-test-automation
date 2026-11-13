*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Login and logout through the UI (desktop, 1920x1080).

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Setup       Start Desktop Test
Test Teardown    End Web Test

Test Tags        web    login


*** Test Cases ***
Customer logs in
    [Tags]    smoke
    Given a registered customer
    When the user logs in with valid credentials
    Then the store should be displayed

Administrator logs in
    Given a registered administrator
    When the user logs in with valid credentials
    Then the administrator home should welcome the user

Reject invalid credentials
    Given a registered customer
    When the user logs in with the password "wrong-password"
    Then the login page should show "Email e/ou senha inválidos"

Require e-mail and password
    [Template]    Logging in with blank "${field}" should show "${message}"
    email    Email é obrigatório
    password    Password é obrigatório

User logs out
    Given a registered customer
    And the user is logged in
    When the user logs out
    Then the login form should be displayed


*** Keywords ***
A registered customer
    ${user}=    Register New User
    VAR    ${USER}    ${user}    scope=TEST

A registered administrator
    ${user}=    Register New User    admin=${True}
    VAR    ${USER}    ${user}    scope=TEST

The user logs in with valid credentials
    Log In As    ${USER}[email]    ${USER}[password]

The user is logged in
    The user logs in with valid credentials
    The store should be displayed

The user logs in with the password "${password}"
    Log In As    ${USER}[email]    ${password}

The user logs out
    Log Out

The store should be displayed
    Get Url    contains    /home
    Get Text    ${STORE_TITLE}    contains    Serverest Store

The administrator home should welcome the user
    Get Url    contains    /admin/home
    Get Text    ${ADMIN_WELCOME}    contains    Bem Vindo
    Get Text    ${ADMIN_WELCOME}    contains    ${USER}[nome]

The login page should show "${message}"
    Get Text    ${LOGIN_ALERTS}    ==    ${message}

The login form should be displayed
    Get Url    contains    /login
    Wait For Elements State    ${LOGIN_FORM}    visible

Logging in with blank "${field}" should show "${message}"
    Open Login Page
    ${user}=    New User Data
    IF    $field == 'email'
        Log In As    ${EMPTY}    ${user}[password]
    ELSE
        Log In As    ${user}[email]    ${EMPTY}
    END
    Get Text    ${LOGIN_ALERTS}    ==    ${message}
