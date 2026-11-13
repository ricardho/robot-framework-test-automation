*** Comments ***
Gherkin steps and test names are self-describing; documentation is required in resources only.
# robocop: off=missing-doc-keyword,missing-doc-test-case


*** Settings ***
Documentation    Customer journey on mobile browsers (Playwright device emulation:
...              viewport, user agent, touch and pixel ratio of real devices).

Resource         ../../resources/web/web_common.resource

Suite Setup      Start Web Suite
Test Teardown    End Web Test

Test Tags        web-mobile


*** Test Cases ***
Customer logs in on iPhone
    [Tags]    smoke    ios
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_IOS}
    Given a registered customer
    When the customer logs in
    Then the store should be displayed

Customer logs in on Android
    [Tags]    smoke    android
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_ANDROID}
    Given a registered customer
    When the customer logs in
    Then the store should be displayed

Customer adds a product to the shopping list on iPhone
    [Tags]    ios
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_IOS}
    Given a product available in the store
    And a logged in customer
    When the customer adds the product to the shopping list
    Then the shopping list should contain the product

Customer adds a product to the shopping list on Android
    [Tags]    android
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_ANDROID}
    Given a product available in the store
    And a logged in customer
    When the customer adds the product to the shopping list
    Then the shopping list should contain the product

Store fits the screen width on a small screen
    [Documentation]    KNOWN DEFECT of the ServeRest front-end: the store is wider than a phone
    ...    screen (horizontal overflow), so mobile browsers zoom the page out. This is also why
    ...    the shopping-list tests activate the "Adicionar a lista" button via JavaScript.
    ...    Reported as SKIP while the defect exists (``robot:skip-on-failure``).
    [Tags]    known-defect    robot:skip-on-failure    ios
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_IOS}
    Given a logged in customer
    Then the page should fit the screen width

Customer opens the navigation menu on a small screen
    [Documentation]    KNOWN DEFECT of the ServeRest front-end: the "hamburger" toggler does not
    ...    expand the collapsed menu, so mobile users cannot reach "Logout". The test documents
    ...    the expected behaviour; ``robot:skip-on-failure`` reports it as SKIP while the defect
    ...    exists and it turns green by itself when the front-end is fixed.
    [Tags]    known-defect    robot:skip-on-failure    ios
    [Setup]    Start Mobile Test    ${MOBILE_DEVICE_IOS}
    Given a logged in customer
    When the customer opens the navigation menu
    Then the logout button should be visible


*** Keywords ***
A registered customer
    ${customer}=    Register New User
    VAR    ${CUSTOMER}    ${customer}    scope=TEST

The customer logs in
    Log In As    ${CUSTOMER}[email]    ${CUSTOMER}[password]

A logged in customer
    A registered customer
    The customer logs in
    The store should be displayed

A product available in the store
    ${admin}=    Register And Login New User    admin=${True}
    ${product}=    Register New Product    ${admin}[token]
    VAR    ${PRODUCT}    ${product}    scope=TEST

The customer adds the product to the shopping list
    Search Product    ${PRODUCT}[nome]
    # Workaround for the horizontal overflow defect (see "Store fits the screen width")
    Add Product To Shopping List    ${PRODUCT}[nome]    via_javascript=${True}

The page should fit the screen width
    ${screen_width}    ${document_width}=    Page Overflow
    Should Be True    ${document_width} <= ${screen_width}
    ...    msg=Horizontal overflow: document is ${document_width}px wide on a ${screen_width}px screen

The customer opens the navigation menu
    Open Navigation Menu

The store should be displayed
    Get Url    contains    /home
    Get Text    ${STORE_TITLE}    contains    Serverest Store

The shopping list should contain the product
    ${quantity}=    Quantity Of Item    ${PRODUCT}[nome]
    Get Text    ${quantity}    ==    Total: 1

The logout button should be visible
    Wait For Elements State    ${NAV_LOGOUT}    visible    timeout=3s
