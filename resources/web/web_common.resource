*** Settings ***
Documentation    Entry point for UI suites: browser lifecycle + page objects + API helpers.
...              UI tests create their data through the API (fast and reliable) and validate
...              behaviour in the UI; everything created is removed in Test Teardown.

Resource         browser.resource
Resource         pages/login_page.resource
Resource         pages/signup_page.resource
Resource         pages/store_page.resource
Resource         pages/shopping_list_page.resource
Resource         pages/admin_pages.resource
Resource         components/navbar.resource
Resource         ../api/users.resource
Resource         ../api/products.resource


*** Keywords ***
Start Web Suite
    [Documentation]    Suite Setup of UI suites.
    Open Browser For Suite
    Create ServeRest API Session

Start Desktop Test
    [Documentation]    Test Setup of desktop UI tests.
    [Arguments]    ${path}=/login
    Start Test Data Tracking
    Open Desktop Page    ${path}

Start Mobile Test
    [Documentation]    Test Setup of web mobile tests (Playwright device emulation).
    [Arguments]    ${device_name}    ${path}=/login
    Start Test Data Tracking
    Open Mobile Page    ${device_name}    ${path}

End Web Test
    [Documentation]    Test Teardown of UI tests: close the context, then delete the test data.
    Run Keyword And Ignore Error    Close Test Context
    Clean Up Test Data

Start Session With Token
    [Documentation]    Logs in through the API and stores the token where the front-end expects it
    ...    (localStorage), skipping the login form. Opens the customer store or the admin home.
    [Arguments]    ${user}
    Go To    ${BASE_URL}/login
    VAR    &{storage}
    ...    serverest/userToken=${user}[token]
    ...    serverest/userEmail=${user}[email]
    ...    serverest/userNome=${user}[nome]
    Evaluate JavaScript    ${None}
    ...    (storage) => Object.entries(storage).forEach(([key, value]) => localStorage.setItem(key, value))
    ...    arg=${storage}
    IF    $user['administrador'] == 'true'
        Go To    ${BASE_URL}/admin/home
    ELSE
        Open Store
    END

Track User Created In UI
    [Documentation]    Users created through the UI are found by e-mail via the API and tracked for cleanup.
    [Arguments]    ${email}
    ${response}=    Search Users    email=${email}
    FOR    ${user}    IN    @{response.json()}[usuarios]
        Track User For Cleanup    ${user}[_id]
    END

Track Product Created In UI
    [Documentation]    Products created through the UI are found by name via the API and tracked for cleanup.
    [Arguments]    ${name}    ${admin_token}
    VAR    &{params}    nome=${name}
    ${response}=    GET On Session    ${SESSION}    /produtos    params=${params}    expected_status=anything
    FOR    ${product}    IN    @{response.json()}[produtos]
        Track Product For Cleanup    ${product}[_id]    ${admin_token}
    END
