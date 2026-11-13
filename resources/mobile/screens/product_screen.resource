*** Settings ***
Documentation    Product detail screen.

Resource         ../app.resource


*** Variables ***
${PRODUCT_TITLE}          id=com.saucelabs.mydemoapp.android:id/productTV
${PRODUCT_PRICE}          id=com.saucelabs.mydemoapp.android:id/priceTV
${PRODUCT_QUANTITY}       id=com.saucelabs.mydemoapp.android:id/noTV
${PRODUCT_INCREASE}       accessibility_id=Increase item quantity
${PRODUCT_ADD_TO_CART}    accessibility_id=Tap to add product to cart


*** Keywords ***
Wait For Product Detail
    [Documentation]    Waits until the "Add to cart" button is shown.
    Wait Until Element Is Visible    ${PRODUCT_ADD_TO_CART}

Increase Quantity
    [Documentation]    Taps "+" ``times`` times.
    [Arguments]    ${times}=1
    FOR    ${_}    IN RANGE    ${times}
        Click Element    ${PRODUCT_INCREASE}
    END

Add To Cart
    [Documentation]    Taps "Add to cart".
    Click Element    ${PRODUCT_ADD_TO_CART}
