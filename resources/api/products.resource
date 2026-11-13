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
    [Arguments]    ${admin_token}    ${quantity}=${None}
    ${product}=    New Product Data    quantity=${quantity}
    ${response}=    Create Product    ${product}    ${admin_token}
    Should Be Equal As Integers    ${response.status_code}    201
    ...    msg=Could not register test product: ${response.text}
    Set To Dictionary    ${product}    _id=${response.json()}[_id]
    RETURN    ${product}

Optional Auth Header
    [Documentation]    Empty headers when no token is given (to test unauthenticated calls).
    [Arguments]    ${token}
    IF    $token is None    RETURN    ${{ {} }}
    ${headers}=    Auth Header    ${token}
    RETURN    ${headers}
