*** Settings ***
Documentation    Navigation bar shared by the customer and administrator areas.

Resource         ../browser.resource


*** Variables ***
${NAV_LOGOUT}           css=[data-testid="logout"]
${NAV_TOGGLER}          css=.navbar-toggler
${NAV_SHOPPING_LIST}    css=[data-testid="lista-de-compras"]


*** Keywords ***
Log Out
    [Documentation]    Clicks "Logout". On small screens the menu is collapsed behind the toggler.
    ${states}=    Get Element States    ${NAV_LOGOUT}
    IF    'hidden' in $states    Open Navigation Menu
    Click    ${NAV_LOGOUT}

Open Navigation Menu
    [Documentation]    Taps the "hamburger" toggler shown on small viewports.
    Click    ${NAV_TOGGLER}
