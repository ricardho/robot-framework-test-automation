*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Native Android: login of the Sauce Labs My Demo App.
...              The demo credentials below are public: the app prints them on the login screen.

Resource         ../../resources/mobile/screens/login_screen.resource

Test Setup       Open My Demo App
Test Teardown    Close My Demo App

Test Tags        mobile    android-native


*** Variables ***
${DEMO_USER}        bod@example.com
${DEMO_PASSWORD}    10203040
${LOCKED_USER}      alice@example.com


*** Test Cases ***
User logs in with valid credentials
    [Tags]    smoke
    Given the login screen is open
    When the user logs in as "${DEMO_USER}" with "${DEMO_PASSWORD}"
    Then the catalog should be displayed

Locked user cannot log in
    Given the login screen is open
    When the user logs in as "${LOCKED_USER}" with "${DEMO_PASSWORD}"
    Then the password error should be "Sorry this user has been locked out."

Login requires the username
    Given the login screen is open
    When the user logs in as "" with "${DEMO_PASSWORD}"
    Then the username error should be "Username is required"

Login requires the password
    Given the login screen is open
    When the user logs in as "${DEMO_USER}" with ""
    Then the password error should be "Enter Password"


*** Keywords ***
The login screen is open
    Wait For Catalog
    Open Login Screen

The user logs in as "${username}" with "${password}"
    Log In With    ${username}    ${password}

The catalog should be displayed
    Wait For Catalog

The username error should be "${message}"
    Wait Until Element Is Visible    ${LOGIN_NAME_ERROR}
    Element Text Should Be    ${LOGIN_NAME_ERROR}    ${message}

The password error should be "${message}"
    Wait Until Element Is Visible    ${LOGIN_PASS_ERROR}
    Element Text Should Be    ${LOGIN_PASS_ERROR}    ${message}
