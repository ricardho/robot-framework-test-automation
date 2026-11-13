*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Native Android: catalog and cart of the Sauce Labs My Demo App.
...              Runs in the GitHub Actions emulator job (schedule + manual); locally the
...              suite is validated with ``robot --dryrun`` (no virtualization available).

Resource         ../../resources/mobile/screens/catalog_screen.resource
Resource         ../../resources/mobile/screens/product_screen.resource
Resource         ../../resources/mobile/screens/cart_screen.resource

Test Setup       Open My Demo App
Test Teardown    Close My Demo App

Test Tags        mobile    android-native


*** Variables ***
${BACKPACK}          Sauce Labs Backpack
${BACKPACK_PRICE}    $ 29.99


*** Test Cases ***
Catalog shows the products with prices
    [Tags]    smoke
    Given the catalog is displayed
    Then the catalog should show "${BACKPACK}" for "${BACKPACK_PRICE}"

Adding a product updates the cart badge
    [Tags]    smoke
    Given the catalog is displayed
    When the user adds 1 "${BACKPACK}" to the cart
    Then the cart badge should show 1

Cart totals the quantity and the price
    Given the catalog is displayed
    When the user adds 2 "${BACKPACK}" to the cart
    And the user opens the cart
    Then the cart should total "2 Items" and "$ 59.98"

Removing the only product empties the cart
    Given the catalog is displayed
    And the user adds 1 "${BACKPACK}" to the cart
    And the user opens the cart
    When the user removes the product
    Then the cart should be empty


*** Keywords ***
The catalog is displayed
    Wait For Catalog
    Element Text Should Be    ${CATALOG_TITLE}    Products

The catalog should show "${name}" for "${price}"
    ${price_locator}=    Product Price Locator    ${name}
    Wait Until Element Is Visible    ${price_locator}
    Element Text Should Be    ${price_locator}    ${price}

The user adds ${quantity} "${name}" to the cart
    Open Product    ${name}
    Wait For Product Detail
    Element Text Should Be    ${PRODUCT_TITLE}    ${name}
    Increase Quantity    ${{ int($quantity) - 1 }}
    Element Text Should Be    ${PRODUCT_QUANTITY}    ${quantity}
    Add To Cart

The user opens the cart
    Open Cart
    Wait For Cart

The user removes the product
    Remove First Item

The cart badge should show ${count}
    Wait Until Element Is Visible    ${HEADER_CART_BADGE}
    Element Text Should Be    ${HEADER_CART_BADGE}    ${count}

The cart should total "${items}" and "${price}"
    Element Text Should Be    ${CART_ITEMS_TOTAL}    ${items}
    Element Text Should Be    ${CART_PRICE_TOTAL}    ${price}

The cart should be empty
    Wait Until Element Is Visible    ${CART_EMPTY_TITLE}
    Element Text Should Be    ${CART_EMPTY_TITLE}    No Items
