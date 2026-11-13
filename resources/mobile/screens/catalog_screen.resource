*** Settings ***
Documentation    Catalog screen (first screen after the splash) and the shared header.
...              Locators: accessibility ids first, resource ids otherwise (taken from the app's
...              layouts in github.com/saucelabs/my-demo-app-android).

Resource         ../app.resource


*** Variables ***
${CATALOG_TITLE}        id=com.saucelabs.mydemoapp.android:id/productTV
${CATALOG_LIST}         accessibility_id=Displays all products of catalog
${HEADER_MENU}          accessibility_id=View menu
${HEADER_CART}          accessibility_id=View cart
${HEADER_CART_BADGE}    id=com.saucelabs.mydemoapp.android:id/cartTV


*** Keywords ***
Wait For Catalog
    [Documentation]    Waits until the product list is shown.
    Wait Until Element Is Visible    ${CATALOG_LIST}

Product Title Locator
    [Documentation]    Locator of the title of product ``name`` in the catalog.
    [Arguments]    ${name}
    RETURN    android=new UiSelector().resourceId("${APP_PACKAGE}:id/titleTV").text("${name}")

Product Title Xpath
    [Documentation]    XPath of the title of product ``name`` (base for its sibling views).
    [Arguments]    ${name}
    RETURN    //*[@resource-id="${APP_PACKAGE}:id/titleTV" and @text="${name}"]

Product Price Locator
    [Documentation]    Locator of the price shown right below the title of product ``name``.
    [Arguments]    ${name}
    ${title}=    Product Title Xpath    ${name}
    RETURN    xpath=${title}/following-sibling::*[@resource-id="${APP_PACKAGE}:id/priceTV"][1]

Open Product
    [Documentation]    Opens the detail screen of product ``name`` (the image is the tap target).
    [Arguments]    ${name}
    ${title}=    Product Title Xpath    ${name}
    Wait Until Element Is Visible    xpath=${title}
    Click Element    xpath=${title}/preceding-sibling::*[@content-desc="Product Image"][1]

Open Cart
    [Documentation]    Taps the cart icon in the header.
    Click Element    ${HEADER_CART}

Open Menu
    [Documentation]    Opens the side menu.
    Click Element    ${HEADER_MENU}
