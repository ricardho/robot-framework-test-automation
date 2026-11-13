*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    /produtos: product registration is restricted to administrators.

Resource         ../../resources/api/users.resource
Resource         ../../resources/api/products.resource

Suite Setup      Create ServeRest API Session
Test Setup       Start Test Data Tracking
Test Teardown    Clean Up Test Data

Test Tags        api    products


*** Variables ***
${TOKEN_MESSAGE}    Token de acesso ausente, inválido, expirado ou usuário do token não existe mais


*** Test Cases ***
Administrator registers a product
    [Tags]    smoke
    Given a logged in administrator
    And a new product payload
    When the product is registered
    Then the response status should be    201
    And the response should match schema    created.json
    And the registered product should be returned with the same data

Customer cannot register products
    Given a logged in customer
    And a new product payload
    When the product is registered
    Then the response status should be    403
    And the response message should be    Rota exclusiva para administradores

Reject product registration without a token
    Given a new product payload
    When the product is registered without a token
    Then the response status should be    401
    And the response message should be    ${TOKEN_MESSAGE}

Reject product registration with an invalid token
    Given a new product payload
    When the product is registered with the token "Bearer invalid.token.value"
    Then the response status should be    401
    And the response message should be    ${TOKEN_MESSAGE}

Reject a duplicated product name
    Given a logged in administrator
    And an already registered product
    When another product is registered with the same name
    Then the response status should be    400
    And the response message should be    Já existe produto com esse nome

Reject invalid product fields
    [Template]    Registering a product with "${field}" set to "${value}" should fail with "${message}"
    nome    ${EMPTY}    nome não pode ficar em branco
    preco    ${-1}    preco deve ser um número positivo
    descricao    ${EMPTY}    descricao não pode ficar em branco
    quantidade    ${-1}    quantidade deve ser maior ou igual a 0

Administrator deletes a product
    Given a logged in administrator
    And an already registered product
    When the product is deleted
    Then the response status should be    200
    And the response message should be    Registro excluído com sucesso
    And the product should no longer exist


*** Keywords ***
A logged in administrator
    ${admin}=    Register And Login New User    admin=${True}
    VAR    ${ACTOR}    ${admin}    scope=TEST

A logged in customer
    ${customer}=    Register And Login New User    admin=${False}
    VAR    ${ACTOR}    ${customer}    scope=TEST

A new product payload
    ${payload}=    New Product Data
    VAR    ${PRODUCT}    ${payload}    scope=TEST

An already registered product
    ${product}=    Register New Product    ${ACTOR}[token]
    VAR    ${PRODUCT}    ${product}    scope=TEST

The product is registered
    ${response}=    Create Product    ${PRODUCT}    ${ACTOR}[token]
    Keep Response    ${response}

The product is registered without a token
    ${response}=    Create Product    ${PRODUCT}
    Keep Response    ${response}

The product is registered with the token "${token}"
    ${response}=    Create Product    ${PRODUCT}    ${token}
    Keep Response    ${response}

Another product is registered with the same name
    ${payload}=    New Product Data
    Set To Dictionary    ${payload}    nome=${PRODUCT}[nome]
    ${response}=    Create Product    ${payload}    ${ACTOR}[token]
    Keep Response    ${response}

Registering a product with "${field}" set to "${value}" should fail with "${message}"
    ${admin}=    Register And Login New User    admin=${True}
    ${payload}=    New Product Data
    Set To Dictionary    ${payload}    ${field}=${value}
    ${response}=    Create Product    ${payload}    ${admin}[token]
    Keep Response    ${response}
    The Response Status Should Be    400
    The Response Field Should Be    ${field}    ${message}

The registered product should be returned with the same data
    ${response}=    Get Product    ${RESPONSE.json()}[_id]
    Should Be Equal As Integers    ${response.status_code}    200
    Json Should Match Schema    ${response.json()}    product.json
    VAR    ${stored}    ${response.json()}
    FOR    ${field}    IN    nome    preco    descricao    quantidade
        Should Be Equal    ${stored}[${field}]    ${PRODUCT}[${field}]    msg=Field '${field}' differs
    END

The product is deleted
    ${response}=    Delete Product    ${PRODUCT}[_id]    ${ACTOR}[token]
    Keep Response    ${response}

The product should no longer exist
    ${response}=    Get Product    ${PRODUCT}[_id]
    Should Be Equal As Integers    ${response.status_code}    400
    Should Be Equal    ${response.json()}[message]    Produto não encontrado
