*** Settings ***
Documentation    Per-test registry of data created through the API, removed in Test Teardown.
...              Tests run in parallel against a shared public server, so each test deletes
...              exactly what it created and nothing else.
...              Order matters: carts block deleting their users and products.

Library          Collections
Resource         api_common.resource


*** Keywords ***
Start Test Data Tracking
    [Documentation]    Use as Test Setup in every suite that creates data.
    VAR    @{CLEANUP_CART_TOKENS}    @{EMPTY}    scope=TEST
    VAR    @{CLEANUP_PRODUCTS}    @{EMPTY}    scope=TEST
    VAR    @{CLEANUP_USERS}    @{EMPTY}    scope=TEST

Track User For Cleanup
    [Documentation]    Registers a user id to be deleted in Test Teardown.
    [Arguments]    ${user_id}
    ${users}=    Get Variable Value    ${CLEANUP_USERS}    ${None}
    IF    $users is not None    Append To List    ${users}    ${user_id}

Track Product For Cleanup
    [Documentation]    Deleting a product needs an administrator token.
    [Arguments]    ${product_id}    ${admin_token}
    ${products}=    Get Variable Value    ${CLEANUP_PRODUCTS}    ${None}
    VAR    &{product}    id=${product_id}    token=${admin_token}
    IF    $products is not None    Append To List    ${products}    ${product}

Track Cart For Cleanup
    [Documentation]    A cart is cancelled with its owner's token (one cart per user).
    [Arguments]    ${owner_token}
    ${tokens}=    Get Variable Value    ${CLEANUP_CART_TOKENS}    ${None}
    IF    $tokens is not None    Append To List    ${tokens}    ${owner_token}

Clean Up Test Data
    [Documentation]    Use as Test Teardown. Never fails the test: errors are only logged.
    ${tokens}=    Get Variable Value    ${CLEANUP_CART_TOKENS}    @{EMPTY}
    FOR    ${token}    IN    @{tokens}
        ${headers}=    Auth Header    ${token}
        Run Keyword And Ignore Error
        ...    DELETE On Session    ${SESSION}    /carrinhos/cancelar-compra    headers=${headers}
        ...    expected_status=anything
    END
    ${products}=    Get Variable Value    ${CLEANUP_PRODUCTS}    @{EMPTY}
    FOR    ${product}    IN    @{products}
        ${headers}=    Auth Header    ${product}[token]
        Run Keyword And Ignore Error
        ...    DELETE On Session    ${SESSION}    /produtos/${product}[id]    headers=${headers}
        ...    expected_status=anything
    END
    ${users}=    Get Variable Value    ${CLEANUP_USERS}    @{EMPTY}
    FOR    ${user_id}    IN    @{users}
        Run Keyword And Ignore Error
        ...    DELETE On Session    ${SESSION}    /usuarios/${user_id}    expected_status=anything
    END
