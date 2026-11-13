*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Administrator manages products through the UI (desktop).

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Setup       Start Desktop Test
Test Teardown    End Web Test

Test Tags        web    admin-products


*** Test Cases ***
Administrator registers a product
    [Tags]    smoke
    Given a logged in administrator
    And the data of a product to register
    When the administrator registers the product
    Then the product list should show the product

Product registration requires every field
    Given a logged in administrator
    When the administrator submits an empty product form
    Then the product form should list the alerts
    ...    Nome é obrigatório
    ...    Preco é obrigatório
    ...    Descricao é obrigatório
    ...    Quantidade é obrigatório


*** Keywords ***
A logged in administrator
    ${administrator}=    Register And Login New User    admin=${True}
    VAR    ${ADMIN}    ${administrator}    scope=TEST
    Log In As    ${administrator}[email]    ${administrator}[password]
    Get Url    contains    /admin/home

The data of a product to register
    ${product}=    New Product Data
    VAR    ${PRODUCT}    ${product}    scope=TEST

The administrator registers the product
    Go To Product Registration
    Register Product    ${PRODUCT}
    Track Product Created In UI    ${PRODUCT}[nome]    ${ADMIN}[token]

The administrator submits an empty product form
    Go To Product Registration
    VAR    &{empty}    nome=${EMPTY}    preco=${EMPTY}    descricao=${EMPTY}    quantidade=${EMPTY}
    Register Product    ${empty}

The product list should show the product
    Get Url    contains    /admin/listarprodutos
    ${row}=    Product Row    ${PRODUCT}[nome]
    # Cells hold text, the product data holds integers
    Get Text    ${row} >> css=td:nth-child(2)    ==    ${{ str($PRODUCT['preco']) }}
    Get Text    ${row} >> css=td:nth-child(3)    ==    ${PRODUCT}[descricao]
    Get Text    ${row} >> css=td:nth-child(4)    ==    ${{ str($PRODUCT['quantidade']) }}

The product form should list the alerts
    [Arguments]    @{expected}
    Get Element Count    ${PRODUCT_ALERTS}    ==    ${{ len($expected) }}
    ${alerts}=    Get Elements    ${PRODUCT_ALERTS}
    FOR    ${alert}    ${message}    IN ZIP    ${alerts}    ${expected}
        Get Text    ${alert}    ==    ${message}
    END
