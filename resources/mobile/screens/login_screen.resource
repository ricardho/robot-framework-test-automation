*** Settings ***
Documentation    Login screen, reached through the side menu ("Log In").
...              The app accepts any filled credentials except the locked user alice@example.com.

Resource         ../app.resource
Resource         catalog_screen.resource


*** Variables ***
${MENU_LOGIN}          accessibility_id=Login Menu Item
${LOGIN_USERNAME}      id=com.saucelabs.mydemoapp.android:id/nameET
${LOGIN_PASSWORD}      id=com.saucelabs.mydemoapp.android:id/passwordET
${LOGIN_BUTTON}        accessibility_id=Tap to login with given credentials
${LOGIN_NAME_ERROR}    id=com.saucelabs.mydemoapp.android:id/nameErrorTV
${LOGIN_PASS_ERROR}    id=com.saucelabs.mydemoapp.android:id/passwordErrorTV


*** Keywords ***
Open Login Screen
    [Documentation]    Side menu → "Log In".
    Open Menu
    Click Element    ${MENU_LOGIN}
    Wait Until Element Is Visible    ${LOGIN_BUTTON}

Log In With
    [Documentation]    Fills the credentials (blank values are skipped) and taps "Login".
    ...    The password is typed with ``Input Password`` so it is not logged.
    [Arguments]    ${username}    ${password}
    IF    $username    Input Text    ${LOGIN_USERNAME}    ${username}
    IF    $password    Input Password    ${LOGIN_PASSWORD}    ${password}
    Click Element    ${LOGIN_BUTTON}
