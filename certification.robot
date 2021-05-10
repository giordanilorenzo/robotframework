*** Settings ***
Documentation   Add orders and download receipt
Library         RPA.Browser         
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets


*** Variables ***
${robot_website}=    https://robotsparebinindustries.com/
${csv_file_location}=    https://robotsparebinindustries.com/orders.csv
${csv_directory}=    ${CURDIR}${/}output/csv
${receipts_directory}=    ${CURDIR}${/}output/receipts
${screenshots_directory}=    ${CURDIR}${/}output/screenshots
${archive_directory}=    ${CURDIR}${/}output/archive
${zip_directory}=    ${CURDIR}${/}output

*** Keywords ***
Set up directories
    Create Directory    ${csv_directory}
    Create Directory    ${receipts_directory}
    Create Directory    ${screenshots_directory}
    Create Directory    ${archive_directory}
    Empty Directory    ${csv_directory}
    Empty Directory    ${receipts_directory}
    Empty Directory    ${screenshots_directory}
    Empty Directory    ${archive_directory}

*** Keywords ***
Ask Zipname to User
    Create Form    Choose the archive zip name
    Add Text Input    Zip name    zipname   Archive
    &{response}=    Request Response
    [Return]    ${response["zipname"]}

*** Keywords ***
Read Secret Vault and Open the intranet website
   ${secret}=    Get Secret    website
   Log    ${secret}[url]
   Open Available Browser   ${secret}[url]
   Click Link   link:Order your robot!

*** Keywords ***
Download The Csv File
    Download    ${csv_file_location}   ${csv_directory}${/}orders.csv   overwrite=True

*** Keywords ***
Fill The Form Using The Data From The Csv File
    ${orders}=  Read Table From Csv   ${csv_directory}${/}orders.csv   header=True
    FOR    ${order}    IN    @{orders}
        Fill And Preview The Robot For One Order    ${order}
        Screenshot The Bot Preview   ${order}
        Wait Until Keyword Succeeds    1min    1sec    Export The Receipt As A PDF   ${order}
        Add The Screenshot To The Receipt   ${order}
        Order Another
    END

*** Keywords ***
Fill And Preview The Robot For One Order
    [Arguments]    ${order}
    Click Button   css:button.btn.btn-dark
    ${head_string}=    Convert To String    ${order}[Head]
    Select From List By Value    head    ${head_string}    
    Select Radio Button    body  ${order}[Body]
    Input Text    css:input[type=number]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Wait Until Page Contains Element    id:robot-preview-image

*** Keywords ***
Screenshot The Bot Preview
    [Arguments]    ${order}
    Scroll Element Into View    class:attribution
    Sleep    1 second
    Capture Element Screenshot    id:robot-preview-image    ${screenshots_directory}${/}screenshot_${order}[Order number].png

*** Keywords ***
Export The Receipt As A PDF
    [Arguments]    ${order}
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${receipts_directory}${/}receipt_${order}[Order number].pdf

*** Keywords ***
Add The Screenshot To The Receipt
    [Arguments]    ${order}
    ${files}=   Create List   
    ...   ${receipts_directory}${/}receipt_${order}[Order number].pdf
    ...   ${screenshots_directory}${/}screenshot_${order}[Order number].png:align=center
    Add Files To Pdf   ${files}   ${archive_directory}${/}archived_order_${order}[Order number].pdf

*** Keywords ***
Order Another
    Click Button    id:order-another

*** Keywords ***
Create ZIP package
    [Arguments]    ${zipname}
    Archive Folder With Zip   ${archive_directory}   ${zip_directory}${/}${zipname}.zip

*** Keywords ***
Close The Browser
    Close Browser

*** Tasks ***
Open the website and submit orders
    Set up directories
    ${zipname}=   Ask Zipname to User
    Read Secret Vault and Open the intranet website
    Download The Csv File
    Fill The Form Using The Data From The Csv File
    Create ZIP package   ${zipname}
    [Teardown]    Close The Browser


