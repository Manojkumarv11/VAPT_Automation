*** Settings ***
Documentation       VAPT Automation

Library             RPA.Desktop.Windows
Library             RPA.HTTP
Library             RPA.Browser
Library             String
Library             RPA.Excel.Files
Library             OperatingSystem
Library             RPA.Robocorp.WorkItems
Library             Collections
Library             Screenshot


*** Variables ***
${inputFileName}                /home/kali/Documents/VAPT_Automation/Input/VAPT_InputFile.csv
${testCasesPrimaryConfig}       /home/kali/Documents/VAPT_Automation/Input/VAPT_Test_Config_Primary.csv
${testCasesSecondaryConfig}     /home/kali/Documents/VAPT_Automation/Input/VAPT_Test_Config_Secondary.csv
${logFilePath}                  /home/kali/Documents/VAPT_Automation/Logs/Log
${screenShotFilePath}           /home/kali/Documents/VAPT_Automation/Screenshots
${cmsDetectUrl}                 https://cmsdetect.com/
${pulginDetectionUrl}           https://scanwp.net/
${subStringError}               We Did Not Recognize the CMS Used By


*** Tasks ***
VAPT Automation
    ${logFilePath}    Create TimeStamp and LogFile
    @{targetUrlList}    Open Input File and Get Target Urls    ${logFilePath}
    Open Test Config File and Get Test cases    ${logFilePath}    ${targetUrlList}


*** Keywords ***
testing
    ${testresult}    Get Regexp Matches
    ...    ${cmsDetectUrl}
    ...    ^((https?\:\/\/)?([\w\d\-]+\.){2,}([\w\d]{2,})((\/[\w\d\-\.]+)*(\/[\w\d\-]+\.[\w\d]{3,4}(\?.*)?)?)?)$

    Log To Console    result:${testresult}

Create TimeStamp and LogFile
    ${timeStamp}    Get Time    format=ddMMYYYY    time_=NOW
    ${timeStamp}    Replace String    ${timeStamp}    ${SPACE}    _
    ${timeStamp}    Replace String    ${timeStamp}    -    ${EMPTY}
    ${timeStamp}    Replace String    ${timeStamp}    :    ${EMPTY}
    ${logFilePath}    Catenate    ${logFilePath}    _    ${timeStamp}    .txt
    Create File    ${logFilePath}
    Append To File    ${logFilePath}    ${timeStamp} : VAPT Process Started${\n}
    RETURN    ${logFilePath}

Open Input File and Get Target Urls
    [Arguments]    ${logFilePath}
    Append To File    ${logFilePath}    Reading input file${\n}
    ${input}    Get File    ${inputFileName}    encoding=utf-8-sig
    @{inputList}    Create List    ${input}
    @{targetUrlList}    Split To Lines    @{inputList}
    Append To File    ${logFilePath}    Target urls are @{targetUrlList}${\n}
    RETURN    @{targetUrlList}

Open Test Config File and Get Test cases
    [Arguments]    ${logFilePath}    ${targetUrlList}
    ${testCaseConfig}    Get File    ${testCasesPrimaryConfig}    encoding=utf-8-sig
    @{testCaseConfigList}    Create List    ${testCaseConfig}
    @{testcaseList}    Split To Lines    @{testCaseConfigList}
    FOR    ${testcase}    IN    @{testcaseList}
        ${value}    Split String    ${testcase}    ,
        Append To File    ${logFilePath}    Test case status:@{value}${\n}
        ${typeOfTesting}    Get From List    ${value}    0
        Log To Console    ${typeOfTesting}
        ${flagValue}    Get From List    ${value}    1
        Log To Console    ${flagValue}
        IF    "${flagValue}" == "YES"
            IF    '${typeOfTesting}' =='CMS Detection'
                FOR    ${url}    IN    @{targetUrlList}
                    Append To File    ${logFilePath}    Excecuting CMS detection for ${url}${\n}
                    CMS Detection    ${url}    ${logFilePath}
                END
            END
            IF    '${typeOfTesting}' =='Plugin Detection'
                FOR    ${url}    IN    @{targetUrlList}
                    Append To File    ${logFilePath}    Excecuting Plugin detection for ${url}${\n}
                    Plugin Detection    ${Url}    ${logFilePath}
                END
            END
            IF    '${typeOfTesting}' =='WP SCAN'
                FOR    ${url}    IN    @{targetUrlList}
                    Append To File    ${logFilePath}    Excecuting WP scan for ${url}${\n}
                    WP SCAN    ${logFilePath}    ${url}
                END
            END
        ELSE
            Append To File    ${logFilePath}    no need to carry out ${typeOfTesting}${\n}
        END
    END

CMS Detection
    [Arguments]    ${url}    ${logFilePath}
    Log To Console    ${logFilePath}
    Append To File    ${logFilePath}    Inside CMS Detection workflow ${url}${\n}
    Open Available Browser    ${cmsDetectUrl}
    Maximize Browser Window
    Append To File    ${logFilePath}    opening ${cmsDetectUrl}${\n}
    Sleep    2s
    Input Text    url    ${url}
    Append To File    ${logFilePath}    entered input url${\n}
    Click Button    //button[contains(text(),'Detect CMS')]
    Sleep    2s
    ${errormsg}    RPA.Browser.Get Text    //body/div[2]/div[1]/div[3]/div[1]
    ${errormsg1}    Get Substring    ${errormsg}    0    36
    IF    "${errormsg1}" == "${subStringError}"
        Append To File    ${logFilePath}    Wordpress website identified${\n}
        ${screenshotFileName}    Catenate    ${screenShotFilePath}/CMS_Detection_Result.png
        Log To Console    ${screenshotFileName}
        Maximize Browser Window
        #Capture Element Screenshot    //body/div[2]    ${screenshotFileName}
        Take Screenshot    ${screenshotFileName}
    ELSE
        Sleep    1s
        ${textfiled}    RPA.Browser.Get Text    //body/div[2]/div[1]/div[3]/div[1]/div[1]/h2[1]/a[1]
        Append To File    ${logFilePath}    Wordpress website identified${\n}
        ${screenshotFileName}    Catenate    ${screenShotFilePath}/CMS_Detection_Result{index}.png
        Log To Console    ${screenshotFileName}
        Maximize Browser Window
        #Take Screenshot    ${screenshotFileName}
        Capture Element Screenshot    //body/div[2]    ${screenshotFileName}
    END
    Close Browser

Plugin Detection
    [Arguments]    ${Url}    ${logFilePath}
    Append To File    ${logFilePath}    Opening plugin detection parameter file${\n}
    ${testCaseConfig}    Get File    ${testCasesSecondaryConfig}
    @{testCaseConfigList}    Create List    ${testCaseConfig}
    @{testcaseList}    Split To Lines    @{testCaseConfigList}
    FOR    ${element}    IN    @{testcaseList}
        ${appendUrl}    Catenate    ${Url}${element}
        Log To Console    ${appendUrl}
        Open Available Browser    ${appendUrl}
        Maximize Browser Window
        ${screenshotFileName}    Catenate    ${screenShotFilePath}/Plugin_Detection_Result{index}.png
        #Capture Page Screenshot    ${screenshotFileName}
        Take Screenshot    ${screenshotFileName}
        Close Browser
    END

WP SCAN
    [Arguments]    ${logFilePath}    ${url}
    #${webName}    Get Substring    ${websitesUrl}    4
    #${webName}    Remove String    ${webName}    .com
    Append To File    ${logFilePath}    Open the Website ${pulginDetectionUrl} ${\n}
    Open Available Browser    ${pulginDetectionUrl}
    Maximize Browser Window
    Wait Until Element Is Visible    url
    Input Text    url    ${url}
    Click Button    //button[contains(text(),'Detect')]
    Sleep    2s
    Append To File    ${logFilePath}    clicked the detect button${\n}
    ${screenshotFileName}    Catenate    ${screenShotFilePath}/WP_Scan1.png
    Capture Element Screenshot    //body/div[4]/div[1]/div[2]/div[2]    ${screenshotFileName}
    Sleep    2s
    ${screenshotFileName}    Catenate    ${screenShotFilePath}/WP_Scan2.png
    Capture Element Screenshot    //div[@class="plugin-results-container"]    ${screenshotFileName}
    Close Browser