*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    /login: authentication and the token used by protected routes.

Resource         ../../resources/api/users.resource
Resource         ../../resources/api/project_admin.resource

Suite Setup      Create ServeRest API Session
Test Setup       Start Test Data Tracking
Test Teardown    Clean Up Test Data

Test Tags        api    login


*** Test Cases ***
Log in with valid credentials
    [Tags]    smoke
    Given an already registered user
    When the user logs in with valid credentials
    Then the response status should be    200
    And the response should match schema    login_success.json

Reject invalid credentials
    [Template]    Logging in with ${scenario} should be rejected
    a wrong password
    an unregistered e-mail
    the e-mail in upper case

Reject blank credentials
    [Template]    Logging in with blank "${field}" should fail with "${message}"
    email    email não pode ficar em branco
    password    password não pode ficar em branco

Project administrator logs in with the secret password
    [Documentation]    Uses SERVEREST_ADMIN_PASSWORD (.env locally, repository secret in CI).
    ...    The account is created on demand because the public server is reset periodically.
    [Tags]    secret
    When the project administrator logs in
    Then a bearer token should be returned


*** Keywords ***
An already registered user
    ${user}=    Register New User
    VAR    ${USER}    ${user}    scope=TEST

The user logs in with valid credentials
    ${response}=    Login Via API    ${USER}[email]    ${USER}[password]
    Keep Response    ${response}

Logging in with ${scenario} should be rejected
    ${user}=    Register New User
    IF    $scenario == 'a wrong password'
        ${response}=    Login Via API    ${user}[email]    wrong-${user}[password]
    ELSE IF    $scenario == 'an unregistered e-mail'
        ${response}=    Login Via API    unregistered.${user}[email]    ${user}[password]
    ELSE IF    $scenario == 'the e-mail in upper case'
        ${response}=    Login Via API    ${{ $user['email'].upper() }}    ${user}[password]
    ELSE
        Fail    Unknown scenario '${scenario}'
    END
    Keep Response    ${response}
    The Response Status Should Be    401
    The Response Message Should Be    Email e/ou senha inválidos

Logging in with blank "${field}" should fail with "${message}"
    ${user}=    Register New User
    Set To Dictionary    ${user}    ${field}=${EMPTY}
    ${response}=    Login Via API    ${user}[email]    ${user}[password]
    Keep Response    ${response}
    The Response Status Should Be    400
    The Response Field Should Be    ${field}    ${message}

The project administrator logs in
    ${token}=    Get Project Admin Token
    VAR    ${TOKEN}    ${token}    scope=TEST

A bearer token should be returned
    Should Match Regexp    ${TOKEN}    ^Bearer \\S+$
