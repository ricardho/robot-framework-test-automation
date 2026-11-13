*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    /carrinhos: carts reserve stock, purchases are concluded or cancelled.

Resource         ../../resources/api/users.resource
Resource         ../../resources/api/products.resource
Resource         ../../resources/api/carts.resource

Suite Setup      Create ServeRest API Session
Test Setup       Start Test Data Tracking
Test Teardown    Clean Up Test Data

Test Tags        api    carts


*** Test Cases ***
Adding products to a cart reserves stock
    [Tags]    smoke
    Given a product with 10 units in stock
    And a logged in customer
    When the customer adds 3 units to a cart
    Then the response status should be    201
    And the response should match schema    created.json
    And the product stock should be 7
    And the customer's cart should total 3 units

Cancelling a purchase restores the stock
    Given a product with 10 units in stock
    And a customer with 4 units in the cart
    When the customer cancels the purchase
    Then the response status should be    200
    And the response message should be    Registro excluído com sucesso. Estoque dos produtos reabastecido
    And the product stock should be 10

Concluding a purchase keeps the stock reduced
    Given a product with 10 units in stock
    And a customer with 4 units in the cart
    When the customer concludes the purchase
    Then the response status should be    200
    And the response message should be    Registro excluído com sucesso
    And the product stock should be 6
    And the customer should have no carts

A customer can have only one cart
    Given a product with 10 units in stock
    And a customer with 1 units in the cart
    When the customer adds 1 units to a cart
    Then the response status should be    400
    And the response message should be    Não é permitido ter mais de 1 carrinho

Reject a cart with more units than the stock
    Given a product with 10 units in stock
    And a logged in customer
    When the customer adds 11 units to a cart
    Then the response status should be    400
    And the response message should be    Produto não possui quantidade suficiente

A user with a cart cannot be deleted
    Given a product with 10 units in stock
    And a customer with 1 units in the cart
    When the customer account is deleted
    Then the response status should be    400
    And the response message should be    Não é permitido excluir usuário com carrinho cadastrado

A product in a cart cannot be deleted
    Given a product with 10 units in stock
    And a customer with 1 units in the cart
    When the administrator deletes the product
    Then the response status should be    400
    And the response message should be    Não é permitido excluir produto que faz parte de carrinho


*** Keywords ***
A product with ${stock} units in stock
    ${administrator}=    Register And Login New User    admin=${True}
    ${product}=    Register New Product    ${administrator}[token]    quantity=${stock}
    VAR    ${ADMIN}    ${administrator}    scope=TEST
    VAR    ${PRODUCT}    ${product}    scope=TEST

A logged in customer
    ${customer}=    Register And Login New User    admin=${False}
    VAR    ${CUSTOMER}    ${customer}    scope=TEST

A customer with ${units} units in the cart
    A logged in customer
    The customer adds ${units} units to a cart
    The Response Status Should Be    201

The customer adds ${units} units to a cart
    ${item}=    Cart Item    ${PRODUCT}[_id]    ${units}
    VAR    @{items}    ${item}
    ${response}=    Create Cart    ${items}    ${CUSTOMER}[token]
    Keep Response    ${response}

The customer cancels the purchase
    ${response}=    Cancel Purchase    ${CUSTOMER}[token]
    Keep Response    ${response}

The customer concludes the purchase
    ${response}=    Conclude Purchase    ${CUSTOMER}[token]
    Keep Response    ${response}

The customer account is deleted
    ${response}=    Delete User    ${CUSTOMER}[_id]
    Keep Response    ${response}

The administrator deletes the product
    ${response}=    Delete Product    ${PRODUCT}[_id]    ${ADMIN}[token]
    Keep Response    ${response}

The product stock should be ${expected}
    ${response}=    Get Product    ${PRODUCT}[_id]
    Should Be Equal As Integers    ${response.json()}[quantidade]    ${expected}

The customer's cart should total ${units} units
    ${response}=    Get Carts Of User    ${CUSTOMER}[_id]
    Json Should Match Schema    ${response.json()}    cart_list.json
    VAR    ${cart}    ${response.json()}[carrinhos][0]
    Should Be Equal As Integers    ${cart}[quantidadeTotal]    ${units}
    Should Be Equal As Integers    ${cart}[precoTotal]    ${{ $PRODUCT['preco'] * int($units) }}

The customer should have no carts
    ${response}=    Get Carts Of User    ${CUSTOMER}[_id]
    Should Be Equal As Integers    ${response.json()}[quantidade]    0
