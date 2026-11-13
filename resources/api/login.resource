*** Settings ***
Documentation    POST /login. Credentials never reach log.html, report.html or Allure:
...              the request runs with the log level raised to WARN.

Resource         api_common.resource


*** Keywords ***
Login Via API
    [Documentation]    Returns the response. ``password`` may be a plain string or a ``Secret``.
    [Arguments]    ${email}    ${password}
    ${previous_level}=    Set Log Level    WARN
    TRY
        ${plain_password}=    Evaluate    getattr($password, 'value', $password)
        VAR    &{credentials}    email=${email}    password=${plain_password}
        ${response}=    POST On Session    ${SESSION}    /login    json=${credentials}    expected_status=anything
    FINALLY
        Set Log Level    ${previous_level}
    END
    Log    POST /login as ${email} returned HTTP ${response.status_code}
    RETURN    ${response}

Get Auth Token
    [Documentation]    Logs in and returns the ``Bearer ...`` token, failing with the API message otherwise.
    [Arguments]    ${email}    ${password}
    ${response}=    Login Via API    ${email}    ${password}
    Should Be Equal As Integers    ${response.status_code}    200
    ...    msg=Login as ${email} failed (HTTP ${response.status_code}): ${response.text}
    RETURN    ${response.json()}[authorization]
