*** Settings ***
Documentation    "My Cart" screen.

Resource         ../app.resource


*** Variables ***
${CART_LIST}           accessibility_id=Displays list of selected products
${CART_ITEMS_TOTAL}    id=com.saucelabs.mydemoapp.android:id/itemsTV
${CART_PRICE_TOTAL}    id=com.saucelabs.mydemoapp.android:id/totalPriceTV
${CART_REMOVE_ITEM}    accessibility_id=Removes product from cart
${CART_EMPTY_TITLE}    id=com.saucelabs.mydemoapp.android:id/noItemTitleTV


*** Keywords ***
Wait For Cart
    [Documentation]    Waits until the cart list is shown.
    Wait Until Element Is Visible    ${CART_LIST}

Remove First Item
    [Documentation]    Taps "Remove Item" on the first product of the cart.
    Click Element    ${CART_REMOVE_ITEM}
