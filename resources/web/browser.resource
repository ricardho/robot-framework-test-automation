*** Settings ***
Documentation    Browser lifecycle (Browser Library / Playwright).
...              One browser per suite (per Pabot process) and one isolated context per test:
...              contexts are cheap and share no cookies or storage, so tests stay independent.
...              Waits are implicit in every Browser keyword (auto-waiting up to ${TIMEOUT}).

Library          Browser
...                  timeout=${TIMEOUT}
...                  retry_assertions_for=${TIMEOUT}
...                  run_on_failure=None
...                  enable_presenter_mode=False


*** Variables ***
&{DESKTOP_VIEWPORT}    width=1920    height=1080
# Navigation waits only for the DOM: the "load" event also waits for third-party assets and
# timed out on a cold Firefox in CI. Page objects then wait for the elements they need.
${PAGE_LOAD_STATE}     domcontentloaded


*** Keywords ***
Open Browser For Suite
    [Documentation]    Suite Setup of every UI suite. ``BROWSER``/``HEADLESS`` come from the config resolver.
    New Browser    ${BROWSER}    headless=${HEADLESS}

Open Desktop Page
    [Documentation]    Test Setup for desktop tests: fixed 1920x1080 viewport keeps screenshots stable.
    [Arguments]    ${path}=/login
    New Context    viewport=${DESKTOP_VIEWPORT}    locale=pt-BR
    New Page    ${BASE_URL}${path}    wait_until=${PAGE_LOAD_STATE}

Open Mobile Page
    [Documentation]    Test Setup for web mobile tests, emulating a Playwright device
    ...    (viewport, user agent, touch, device scale factor), e.g. ``iPhone 14`` or ``Pixel 7``.
    [Arguments]    ${device_name}    ${path}=/login
    ${device}=    Get Device    ${device_name}
    New Context    &{device}    locale=pt-BR
    New Page    ${BASE_URL}${path}    wait_until=${PAGE_LOAD_STATE}

Close Test Context
    [Documentation]    Closes the context of the current test (its pages included).
    Close Context    CURRENT
