*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Hybrid tests: data created through one layer is validated through the other.
...              API → UI: the front-end shows exactly what the API stored.
...              UI → API: what the user does in the front-end is persisted correctly.
...              Logins are made through the API and injected as a token (no login form),
...              which is how fast end-to-end suites skip repetitive UI steps.

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Setup       Start Desktop Test
Test Teardown    End Web Test

Test Tags        hybrid


*** Test Cases ***
Product registered through the API is shown in the store
    [Tags]    smoke
    Given a product registered through the API
    And a customer session started with an API token
    When the customer searches for the product
    Then the store should show the product with the price from the API

Product deleted through the API disappears from the store
    Given a product registered through the API
    And a customer session started with an API token
    When the product is deleted through the API
    And the customer searches for the product
    Then the store should not show the product

Customer signed up in the UI is persisted by the API
    [Tags]    smoke
    Given new customer data
    And the sign-up page is open
    When the visitor signs up in the UI
    Then the API should return the user with the same data

Product registered by an administrator in the UI is persisted by the API
    Given an administrator session started with an API token
    And the data of a product to register
    When the administrator registers the product in the UI
    Then the API should return the product with the same data


*** Keywords ***
A product registered through the API
    ${administrator}=    Register And Login New User    admin=${True}
    ${product}=    Register New Product    ${administrator}[token]
    VAR    ${ADMIN}    ${administrator}    scope=TEST
    VAR    ${PRODUCT}    ${product}    scope=TEST

A customer session started with an API token
    ${customer}=    Register And Login New User
    Start Session With Token    ${customer}

An administrator session started with an API token
    ${administrator}=    Register And Login New User    admin=${True}
    VAR    ${ADMIN}    ${administrator}    scope=TEST
    Start Session With Token    ${administrator}
    Get Text    ${ADMIN_WELCOME}    contains    ${administrator}[nome]

New customer data
    ${user}=    New User Data
    VAR    ${USER}    ${user}    scope=TEST

The data of a product to register
    ${product}=    New Product Data
    VAR    ${PRODUCT}    ${product}    scope=TEST

The sign-up page is open
    Open Sign Up Page

The customer searches for the product
    Search Product    ${PRODUCT}[nome]

The product is deleted through the API
    ${response}=    Delete Product    ${PRODUCT}[_id]    ${ADMIN}[token]
    Should Be Equal As Integers    ${response.status_code}    200

The visitor signs up in the UI
    Sign Up    ${USER}
    Get Url    contains    /home
    Track User Created In UI    ${USER}[email]

The administrator registers the product in the UI
    Go To Product Registration
    Register Product    ${PRODUCT}
    Get Url    contains    /admin/listarprodutos
    Track Product Created In UI    ${PRODUCT}[nome]    ${ADMIN}[token]

The store should show the product with the price from the API
    ${card}=    Product Card    ${PRODUCT}[nome]
    Get Text    ${card} >> css=h6 >> nth=1    ==    $ ${PRODUCT}[preco]

The store should not show the product
    ${card}=    Product Card    ${PRODUCT}[nome]
    Get Element Count    ${card}    ==    0

The API should return the user with the same data
    ${response}=    Search Users    email=${USER}[email]
    Json Should Match Schema    ${response.json()}    user_list.json
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    VAR    ${stored}    ${response.json()}[usuarios][0]
    Should Be Equal    ${stored}[nome]    ${USER}[nome]
    Should Be Equal    ${stored}[administrador]    false

The API should return the product with the same data
    VAR    &{params}    nome=${PRODUCT}[nome]
    ${response}=    GET On Session    ${SESSION}    /produtos    params=${params}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    VAR    ${stored}    ${response.json()}[produtos][0]
    Json Should Match Schema    ${stored}    product.json
    FOR    ${field}    IN    nome    preco    descricao    quantidade
        Should Be Equal    ${stored}[${field}]    ${PRODUCT}[${field}]    msg=Field '${field}' differs
    END
