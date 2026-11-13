*** Settings ***
Documentation    Test data factories. Every call returns new, unique data (Faker pt_BR), so
...              tests never depend on records that already exist on the shared server.

Library          FakerLibrary    locale=pt_BR


*** Keywords ***
Unique Suffix
    [Documentation]    Short random hex: keeps e-mails and product names unique across parallel runs.
    ${suffix}=    Evaluate    uuid.uuid4().hex[:10]    modules=uuid
    RETURN    ${suffix}

New User Data
    [Documentation]    Payload for POST /usuarios. ``administrador`` is a string in ServeRest.
    [Arguments]    ${admin}=${False}
    ${name}=    FakerLibrary.Name
    ${user_name}=    FakerLibrary.User Name
    ${suffix}=    Unique Suffix
    ${password}=    FakerLibrary.Password    length=12
    VAR    ${administrador}    ${{ 'true' if $admin else 'false' }}
    VAR    &{user}
    ...    nome=${name}
    ...    email=${user_name}.${suffix}@example.com
    ...    password=${password}
    ...    administrador=${administrador}
    RETURN    ${user}

New Product Data
    [Documentation]    Payload for POST /produtos. ServeRest accepts integer prices only.
    [Arguments]    ${quantity}=${None}
    ${phrase}=    FakerLibrary.Catch Phrase
    ${suffix}=    Unique Suffix
    ${price}=    FakerLibrary.Random Int    min=10    max=5000
    IF    $quantity is None
        ${quantity}=    FakerLibrary.Random Int    min=5    max=100
    END
    VAR    &{product}
    ...    nome=${phrase} ${suffix}
    ...    preco=${price}
    ...    descricao=${phrase}
    ...    quantidade=${{ int($quantity) }}
    RETURN    ${product}
