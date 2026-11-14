*** Settings ***
Documentation    Customer store (/home): product search and "add to shopping list".
...              Products are found by their (unique) name inside a card, never by index.

Resource         ../browser.resource


*** Variables ***
${STORE_TITLE}            css=.jumbotron h1
${STORE_SEARCH}           css=[data-testid="pesquisar"]
${STORE_SEARCH_BUTTON}    css=[data-testid="botaoPesquisar"]
${STORE_CARDS}            css=section .card


*** Keywords ***
Open Store
    [Documentation]    Navigates to /home (needs a logged-in session).
    Go To    ${BASE_URL}/home    wait_until=${PAGE_LOAD_STATE}
    Wait For Elements State    ${STORE_SEARCH}    visible

Search Product
    [Documentation]    Types the name in the search box, submits and waits until the result list
    ...    is filtered (it re-renders about a second later; acting before that hits stale cards).
    [Arguments]    ${name}
    Fill Text    ${STORE_SEARCH}    ${name}
    Click    ${STORE_SEARCH_BUTTON}
    Get Element Count    css=section .card:not(:has(h5.card-title:has-text("${name}")))    ==    0

Product Card
    [Documentation]    Selector of the card whose title is exactly ``name``.
    [Arguments]    ${name}
    RETURN    css=section .card:has(h5.card-title:text-is("${name}"))

Add Product To Shopping List
    [Documentation]    Clicks "Adicionar a lista" on the product card; the app opens the shopping list.
    ...
    ...    ``via_javascript=True`` is a documented workaround for mobile emulation only: the store
    ...    is wider than small screens (known defect, see tests/web-mobile), the browser zooms the
    ...    page out and pointer coordinates no longer match the button. The element is then
    ...    activated with ``element.click()`` so the business flow stays covered on mobile.
    [Arguments]    ${name}    ${via_javascript}=${False}
    ${card}=    Product Card    ${name}
    VAR    ${button}    ${card} >> css=[data-testid="adicionarNaLista"]
    IF    ${via_javascript}
        Wait For Elements State    ${button}    visible
        Evaluate JavaScript    ${button}    (button) => button.click()
    ELSE
        Click    ${button}
    END

Page Overflow
    [Documentation]    Returns ``[viewport width, document width]``; a document wider than the
    ...    viewport means horizontal overflow (content does not fit the screen).
    ${widths}=    Evaluate JavaScript    ${None}
    ...    () => [window.screen.width, document.documentElement.scrollWidth]
    RETURN    ${widths}
