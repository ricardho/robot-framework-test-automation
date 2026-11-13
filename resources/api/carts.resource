*** Settings ***
Documentation    /carrinhos endpoint client. A cart belongs to the user of the token.
...              Creating a cart reserves stock; cancelling restores it; concluding keeps it.

Library          Collections
Resource         api_common.resource
Resource         cleanup.resource


*** Keywords ***
Create Cart
    [Documentation]    ``items`` is a list of ``{idProduto, quantidade}`` dictionaries.
    [Arguments]    ${items}    ${token}
    ${headers}=    Auth Header    ${token}
    VAR    &{payload}    produtos=${items}
    ${response}=    POST On Session    ${SESSION}    /carrinhos    json=${payload}    headers=${headers}
    ...    expected_status=anything
    IF    ${response.status_code} == 201    Track Cart For Cleanup    ${token}
    RETURN    ${response}

Cart Item
    [Documentation]    One ``{idProduto, quantidade}`` entry for ``Create Cart``.
    [Arguments]    ${product_id}    ${quantity}
    VAR    &{item}    idProduto=${product_id}    quantidade=${{ int($quantity) }}
    RETURN    ${item}

Get Carts Of User
    [Documentation]    GET /carrinhos filtered by ``idUsuario``.
    [Arguments]    ${user_id}
    VAR    &{params}    idUsuario=${user_id}
    ${response}=    GET On Session    ${SESSION}    /carrinhos    params=${params}    expected_status=anything
    RETURN    ${response}

Cancel Purchase
    [Documentation]    Deletes the token owner's cart and restores the stock.
    [Arguments]    ${token}
    ${headers}=    Auth Header    ${token}
    ${response}=    DELETE On Session    ${SESSION}    /carrinhos/cancelar-compra    headers=${headers}
    ...    expected_status=anything
    RETURN    ${response}

Conclude Purchase
    [Documentation]    Deletes the token owner's cart keeping the stock reduced (purchase done).
    [Arguments]    ${token}
    ${headers}=    Auth Header    ${token}
    ${response}=    DELETE On Session    ${SESSION}    /carrinhos/concluir-compra    headers=${headers}
    ...    expected_status=anything
    RETURN    ${response}
