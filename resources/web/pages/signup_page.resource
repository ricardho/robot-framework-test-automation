*** Settings ***
Documentation    Sign-up page (/cadastrarusuarios).

Resource         ../browser.resource


*** Variables ***
${SIGNUP_FORM}        css=.register-page form
${SIGNUP_NAME}        css=[data-testid="nome"]
${SIGNUP_EMAIL}       css=[data-testid="email"]
${SIGNUP_PASSWORD}    css=[data-testid="password"]
${SIGNUP_ADMIN}       css=[data-testid="checkbox"]
${SIGNUP_SUBMIT}      css=[data-testid="cadastrar"]
${SIGNUP_ALERTS}      css=.register-page .alert > span


*** Keywords ***
Open Sign Up Page
    [Documentation]    Navigates directly to the sign-up form.
    Go To    ${BASE_URL}/cadastrarusuarios
    Wait For Elements State    ${SIGNUP_FORM}    visible

Sign Up
    [Documentation]    Fills and submits the form with a ``New User Data`` dictionary.
    ...    Blank fields are left empty, so the same keyword covers validation scenarios.
    [Arguments]    ${user}
    Wait For Elements State    ${SIGNUP_FORM}    visible
    IF    $user['nome']    Fill Text    ${SIGNUP_NAME}    ${user}[nome]
    IF    $user['email']    Fill Text    ${SIGNUP_EMAIL}    ${user}[email]
    VAR    ${password}    ${user}[password]
    IF    $password    Fill Secret    ${SIGNUP_PASSWORD}    $password
    IF    $user['administrador'] == 'true'    Check Checkbox    ${SIGNUP_ADMIN}
    Click    ${SIGNUP_SUBMIT}
