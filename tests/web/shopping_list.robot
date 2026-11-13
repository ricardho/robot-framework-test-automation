*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Customer searches products and manages the shopping list (desktop).
...              The product and the customer are created through the API; the customer
...              logs in through the UI.

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Setup       Start Desktop Test
Test Teardown    End Web Test

Test Tags        web    shopping-list


*** Test Cases ***
Customer finds a product and adds it to the shopping list
    [Tags]    smoke
    Given a product available in the store
    And a logged in customer
    When the customer searches for the product
    And the customer adds the product to the shopping list
    Then the shopping list should contain the product with quantity 1

Customer increases the quantity in the shopping list
    Given a product available in the store
    And a logged in customer
    And the product is in the shopping list
    When the customer increases the quantity
    Then the shopping list should contain the product with quantity 2

Customer clears the shopping list
    Given a product available in the store
    And a logged in customer
    And the product is in the shopping list
    When the customer clears the shopping list
    Then the shopping list should be empty


*** Keywords ***
A product available in the store
    ${admin}=    Register And Login New User    admin=${True}
    ${product}=    Register New Product    ${admin}[token]
    VAR    ${PRODUCT}    ${product}    scope=TEST

A logged in customer
    ${customer}=    Register New User
    Log In As    ${customer}[email]    ${customer}[password]
    Wait For Elements State    ${STORE_SEARCH}    visible

The customer searches for the product
    Search Product    ${PRODUCT}[nome]
    ${card}=    Product Card    ${PRODUCT}[nome]
    Wait For Elements State    ${card}    visible

The customer adds the product to the shopping list
    Add Product To Shopping List    ${PRODUCT}[nome]

The product is in the shopping list
    The customer searches for the product
    The customer adds the product to the shopping list
    The shopping list should contain the product with quantity 1

The customer increases the quantity
    Increase Quantity Of Item    ${PRODUCT}[nome]

The customer clears the shopping list
    Clear Shopping List

The shopping list should contain the product with quantity ${quantity}
    Get Text    ${LIST_TITLE}    ==    Lista de Compras
    ${quantity_selector}=    Quantity Of Item    ${PRODUCT}[nome]
    Get Text    ${quantity_selector}    ==    Total: ${quantity}

The shopping list should be empty
    Get Element Count    ${LIST_ITEMS}    ==    0
