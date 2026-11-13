*** Settings ***
Documentation    Customer shopping list (/minhaListaDeProdutos).

Resource         ../browser.resource


*** Variables ***
${LIST_TITLE}    css=.jumbotron h1
${LIST_CLEAR}    css=[data-testid="limparLista"]
${LIST_ITEMS}    css=[data-testid="shopping-cart-product-name"]


*** Keywords ***
Shopping List Item
    [Documentation]    Selector of the card of product ``name``.
    [Arguments]    ${name}
    RETURN    css=.card:has([data-testid="shopping-cart-product-name"]:text-is("Produto:${name}"))

Quantity Of Item
    [Documentation]    Selector of the "Total: n" text of product ``name``.
    [Arguments]    ${name}
    ${item}=    Shopping List Item    ${name}
    RETURN    ${item} >> css=[data-testid="shopping-cart-product-quantity"]

Increase Quantity Of Item
    [Documentation]    Clicks "+" on the card of product ``name``.
    [Arguments]    ${name}
    ${item}=    Shopping List Item    ${name}
    Click    ${item} >> css=[data-testid="product-increase-quantity"]

Clear Shopping List
    [Documentation]    Clicks "Limpar Lista".
    Click    ${LIST_CLEAR}
