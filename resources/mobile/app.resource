*** Settings ***
Documentation    Native Android app lifecycle: Appium + UiAutomator2 + Sauce Labs My Demo App.
...              One app session per test with ``noReset=false`` (app data cleared), so tests
...              are independent. Run only where an Android device/emulator and an Appium
...              server exist (GitHub Actions emulator job); locally use ``robot --dryrun``.

Library          AppiumLibrary    timeout=${TIMEOUT}


*** Variables ***
${APP_PACKAGE}     com.saucelabs.mydemoapp.android
${APP_ACTIVITY}    com.saucelabs.mydemoapp.android.view.activities.SplashActivity


*** Keywords ***
Open My Demo App
    [Documentation]    Test Setup of native tests. Capabilities use the W3C ``appium:`` prefix.
    Open Application    ${APPIUM_URL}
    ...    platformName=Android
    ...    appium:automationName=UiAutomator2
    ...    appium:app=${ANDROID_APP}
    ...    appium:appPackage=${APP_PACKAGE}
    ...    appium:appActivity=${APP_ACTIVITY}
    ...    appium:appWaitActivity=*
    ...    appium:noReset=${False}
    ...    appium:autoGrantPermissions=${True}
    ...    appium:newCommandTimeout=${120}
    ...    appium:uiautomator2ServerInstallTimeout=${120000}
    ...    appium:adbExecTimeout=${120000}

Close My Demo App
    [Documentation]    Test Teardown of native tests; never fails the test.
    Run Keyword And Ignore Error    Close Application

Resource Id
    [Documentation]    Locator for an Android resource id of the app (``id/<name>``).
    [Arguments]    ${name}
    RETURN    id=${APP_PACKAGE}:id/${name}
