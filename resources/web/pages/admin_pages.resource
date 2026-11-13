*** Settings ***
Documentation    Administrator area: home (/admin/home), product registration
...              (/admin/cadastrarprodutos) and product list (/admin/listarprodutos).

Resource         ../browser.resource


*** Variables ***
${ADMIN_WELCOME}          css=.jumbotron h1
${ADMIN_NAV_REGISTER}     css=[data-testid="cadastrar-produtos"]
${ADMIN_NAV_LIST}         css=[data-testid="listar-produtos"]
${PRODUCT_FORM}           css=.jumbotron form
${PRODUCT_NAME}           css=[data-testid="nome"]
${PRODUCT_PRICE}          css=[data-testid="preco"]
${PRODUCT_DESCRIPTION}    css=[data-testid="descricao"]
${PRODUCT_QUANTITY}       css=[data-testid="quantity"]
# "cadastarProdutos" (sic) is the test id used by the application
${PRODUCT_SUBMIT}         css=[data-testid="cadastarProdutos"]
${PRODUCT_ALERTS}         css=.jumbotron .alert > span
${PRODUCT_TABLE}          css=table.table


*** Keywords ***
Go To Product Registration
    [Documentation]    Opens the product form from the navigation bar.
    Click    ${ADMIN_NAV_REGISTER}
    Wait For Elements State    ${PRODUCT_FORM}    visible

Go To Product List
    [Documentation]    Opens the product table from the navigation bar.
    Click    ${ADMIN_NAV_LIST}
    Wait For Elements State    ${PRODUCT_TABLE}    visible

Register Product
    [Documentation]    Fills and submits the form with a ``New Product Data`` dictionary (no image:
    ...    the field is marked "*" but optional). Blank values are left empty.
    [Arguments]    ${product}
    Wait For Elements State    ${PRODUCT_FORM}    visible
    IF    $product['nome']    Fill Text    ${PRODUCT_NAME}    ${product}[nome]
    IF    $product['preco'] != ''
        Fill Text    ${PRODUCT_PRICE}    ${product}[preco]
    END
    IF    $product['descricao']
        Fill Text    ${PRODUCT_DESCRIPTION}    ${product}[descricao]
    END
    IF    $product['quantidade'] != ''
        Fill Text    ${PRODUCT_QUANTITY}    ${product}[quantidade]
    END
    Click    ${PRODUCT_SUBMIT}

Product Row
    [Documentation]    Selector of the table row whose first cell is exactly ``name``.
    [Arguments]    ${name}
    RETURN    css=table tbody tr:has(td:first-child:text-is("${name}"))
