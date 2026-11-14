*** Settings ***
Documentation    /produtos endpoint client. Writes require an administrator token.

Library          Collections
Resource         api_common.resource
Resource         cleanup.resource
Resource         ../data/factories.resource


*** Keywords ***
Create Product
    [Documentation]    POST /produtos. Without ``token`` the request is sent unauthenticated.
    [Arguments]    ${payload}    ${token}=${None}
    ${headers}=    Optional Auth Header    ${token}
    ${response}=    POST On Session    ${SESSION}    /produtos    json=${payload}    headers=${headers}
    ...    expected_status=anything
    IF    ${response.status_code} == 201
        Track Product For Cleanup    ${response.json()}[_id]    ${token}
    END
    RETURN    ${response}

Get Product
    [Documentation]    GET /produtos/{id}.
    [Arguments]    ${product_id}
    ${response}=    GET On Session    ${SESSION}    /produtos/${product_id}    expected_status=anything
    RETURN    ${response}

Delete Product
    [Documentation]    DELETE /produtos/{id} with an administrator token.
    [Arguments]    ${product_id}    ${token}
    ${headers}=    Auth Header    ${token}
    ${response}=    DELETE On Session    ${SESSION}    /produtos/${product_id}    headers=${headers}
    ...    expected_status=anything
    RETURN    ${response}

Register New Product
    [Documentation]    Creates a product with fresh data and returns its payload plus ``_id``.
    ...    Same safe retry as ``Register New User``: after a lost connection it looks the product
    ...    up by its unique name before resending the (non-idempotent) POST.
    [Arguments]    ${admin_token}    ${quantity}=${None}
    ${product}=    New Product Data    quantity=${quantity}
    FOR    ${_}    IN RANGE    3
        ${product_id}=    Try To Create Product    ${product}    ${admin_token}
        IF    $product_id is not None
            Set To Dictionary    ${product}    _id=${product_id}
            RETURN    ${product}
        END
    END
    Fail    Could not register test product: the connection was lost on every attempt

Try To Create Product
    [Documentation]    One POST /produtos. Returns the new ``_id``, or ``None`` when the connection
    ...    was lost and the product was not created (safe to resend). Other errors fail the test.
    [Arguments]    ${product}    ${admin_token}
    TRY
        ${response}=    Create Product    ${product}    ${admin_token}
    EXCEPT    ConnectionError: *    type=GLOB    AS    ${error}
        Log    POST /produtos lost the connection: ${error}    WARN
        ${product_id}=    Find Product Id By Name    ${product}[nome]
        IF    $product_id is not None
            Track Product For Cleanup    ${product_id}    ${admin_token}
        END
        RETURN    ${product_id}
    END
    Should Be Equal As Integers    ${response.status_code}    201
    ...    msg=Could not register test product: ${response.text}
    RETURN    ${response.json()}[_id]

Find Product Id By Name
    [Documentation]    ``_id`` of the product with this name, or ``None`` when it does not exist.
    [Arguments]    ${name}
    VAR    &{filters}    nome=${name}
    ${response}=    GET On Session    ${SESSION}    /produtos    params=${filters}    expected_status=200
    VAR    ${products}    ${response.json()}[produtos]
    IF    $products    RETURN    ${products}[0][_id]
    RETURN    ${None}

Optional Auth Header
    [Documentation]    Empty headers when no token is given (to test unauthenticated calls).
    [Arguments]    ${token}
    IF    $token is None    RETURN    ${{ {} }}
    ${headers}=    Auth Header    ${token}
    RETURN    ${headers}
