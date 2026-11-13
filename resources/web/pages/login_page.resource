*** Settings ***
Documentation    Login page (/login). Page objects describe the UI; assertions live in the tests.

Resource         ../browser.resource


*** Variables ***
${LOGIN_FORM}           css=.login-page form
${LOGIN_EMAIL}          css=[data-testid="email"]
${LOGIN_PASSWORD}       css=[data-testid="senha"]
${LOGIN_SUBMIT}         css=[data-testid="entrar"]
${LOGIN_SIGNUP_LINK}    css=[data-testid="cadastrar"]
${LOGIN_ALERTS}         css=.login-page .alert > span


*** Keywords ***
Open Login Page
    [Documentation]    Navigates to /login and waits for the form.
    Go To    ${BASE_URL}/login
    Wait For Elements State    ${LOGIN_FORM}    visible

Log In As
    [Documentation]    Fills the form and submits. ``Fill Secret`` keeps the password out of the logs.
    [Arguments]    ${email}    ${password}
    Wait For Elements State    ${LOGIN_FORM}    visible
    Fill Text    ${LOGIN_EMAIL}    ${email}
    IF    $password    Fill Secret    ${LOGIN_PASSWORD}    $password
    Click    ${LOGIN_SUBMIT}

Go To Sign Up
    [Documentation]    Follows the "Cadastre-se" link.
    Click    ${LOGIN_SIGNUP_LINK}
