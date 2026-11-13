*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    /usuarios: register, read, search, update and delete users.

Resource         ../../resources/api/users.resource

Suite Setup      Create ServeRest API Session
Test Setup       Start Test Data Tracking
Test Teardown    Clean Up Test Data

Test Tags        api    users


*** Variables ***
# 16 alphanumeric characters (valid format) that ServeRest never generates
${UNKNOWN_ID}    0000000000000000


*** Test Cases ***
Register a new user
    [Tags]    smoke
    Given a new user payload
    When the user is registered
    Then the response status should be    201
    And the response should match schema    created.json
    And the registered user should be returned with the same data

Reject a duplicated e-mail
    Given an already registered user
    When another user is registered with the same e-mail
    Then the response status should be    400
    And the response message should be    Este email já está sendo usado

Reject invalid user fields
    [Template]    Registering a user with "${field}" set to "${value}" should fail with "${message}"
    nome    ${EMPTY}    nome não pode ficar em branco
    email    ${EMPTY}    email não pode ficar em branco
    email    not-an-email    email deve ser um email válido
    password    ${EMPTY}    password não pode ficar em branco
    administrador    maybe    administrador deve ser 'true' ou 'false'

Get a user by id
    Given an already registered user
    When the user is requested by id
    Then the response status should be    200
    And the response should match schema    user.json
    And the response field should be    email    ${USER}[email]

Search users by e-mail
    Given an already registered user
    When users are searched by the user's e-mail
    Then the response status should be    200
    And the response should match schema    user_list.json
    And the response field should be    quantidade    ${1}

Answer 400 for an unknown user id
    [Documentation]    ServeRest quirk: "not found" is 400, not 404.
    When the user "${UNKNOWN_ID}" is requested
    Then the response status should be    400
    And the response message should be    Usuário não encontrado

Update a user
    Given an already registered user
    When the user's name is changed to "Nome Atualizado Pelo Robot"
    Then the response status should be    200
    And the response message should be    Registro alterado com sucesso
    And the user's name should be "Nome Atualizado Pelo Robot"

Create a user with PUT on an unknown id
    [Documentation]    ServeRest quirk: PUT on an id that does not exist creates a new user.
    Given a new user payload
    When the payload is sent with PUT to an unknown id
    Then the response status should be    201
    And the response should match schema    created.json

Delete a user
    Given an already registered user
    When the user is deleted
    Then the response status should be    200
    And the response message should be    Registro excluído com sucesso
    And the user should no longer exist

Deleting an unknown user changes nothing
    [Documentation]    ServeRest quirk: DELETE of an unknown id answers 200 with a message.
    When the user "${UNKNOWN_ID}" is deleted
    Then the response status should be    200
    And the response message should be    Nenhum registro excluído


*** Keywords ***
A new user payload
    ${payload}=    New User Data
    VAR    ${USER}    ${payload}    scope=TEST

An already registered user
    ${user}=    Register New User
    VAR    ${USER}    ${user}    scope=TEST

The user is registered
    ${response}=    Create User    ${USER}
    Keep Response    ${response}

Another user is registered with the same e-mail
    ${payload}=    New User Data
    Set To Dictionary    ${payload}    email=${USER}[email]
    ${response}=    Create User    ${payload}
    Keep Response    ${response}

Registering a user with "${field}" set to "${value}" should fail with "${message}"
    ${payload}=    New User Data
    Set To Dictionary    ${payload}    ${field}=${value}
    ${response}=    Create User    ${payload}
    Keep Response    ${response}
    The Response Status Should Be    400
    The Response Field Should Be    ${field}    ${message}

The user is requested by id
    ${response}=    Get User    ${USER}[_id]
    Keep Response    ${response}

The user "${user_id}" is requested
    ${response}=    Get User    ${user_id}
    Keep Response    ${response}

Users are searched by the user's e-mail
    ${response}=    Search Users    email=${USER}[email]
    Keep Response    ${response}

The registered user should be returned with the same data
    ${response}=    Get User    ${RESPONSE.json()}[_id]
    Should Be Equal As Integers    ${response.status_code}    200
    Json Should Match Schema    ${response.json()}    user.json
    VAR    ${stored}    ${response.json()}
    FOR    ${field}    IN    nome    email    password    administrador
        Should Be Equal    ${stored}[${field}]    ${USER}[${field}]    msg=Field '${field}' differs
    END

The user's name is changed to "${new_name}"
    ${payload}=    Copy Dictionary    ${USER}
    Remove From Dictionary    ${payload}    _id
    Set To Dictionary    ${payload}    nome=${new_name}
    ${response}=    Update User    ${USER}[_id]    ${payload}
    Keep Response    ${response}

The user's name should be "${expected_name}"
    ${response}=    Get User    ${USER}[_id]
    Should Be Equal    ${response.json()}[nome]    ${expected_name}

The payload is sent with PUT to an unknown id
    ${response}=    Update User    ${UNKNOWN_ID}    ${USER}
    Keep Response    ${response}

The user is deleted
    ${response}=    Delete User    ${USER}[_id]
    Keep Response    ${response}

The user "${user_id}" is deleted
    ${response}=    Delete User    ${user_id}
    Keep Response    ${response}

The user should no longer exist
    ${response}=    Get User    ${USER}[_id]
    Should Be Equal As Integers    ${response.status_code}    400
    Should Be Equal    ${response.json()}[message]    Usuário não encontrado
