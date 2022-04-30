*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library     RPA.Browser.Selenium     auto_close=${FALSE}
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault


*** Variables ***
${ORDERS_CSV_FILE_NAME}=     orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=    Get Secret    credentials
    Open the robot order website    ${secret}[robotspare_robot_order_url]
    ${csv_filename}=     Input order csv filename
    ${orders}=    Get orders    ${csv_filename}  ${secret}[robotspare_robot_base_url]     
    FOR    ${order}    IN    @{orders}
        # Log     ${row}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1s     Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    #Mun oma lisäys, jolla suljetaan selain
    [Teardown]      Close Browser

*** Keywords ***
Input order csv filename
    Add heading     Add order csv filename
    Add text input      csv_filename    label=CSV filename
    ${result}=      Run dialog
    [Return]    ${result.csv_filename}


Open the robot order website
    [Arguments]     ${robotspare_robot_order_url}
    # Open Available Browser     ${robotspare_robot_order_url}  browser_selection=firefox
    Open Available Browser     ${robotspare_robot_order_url}


Get orders
    [Arguments]     ${csv_filename}     ${robotspare_robot_base_url}
    ${secret}=    Get Secret    credentials
    Download    url=${robotspare_robot_base_url}/${csv_filename}  overwrite=True  target_file=${OUTPUT_DIR}
    ${orders_table}=    Read table from CSV      ${OUTPUT_DIR}${/}${csv_filename}  header=True  delimiters=","
    [Return]    ${orders_table}



Close the annoying modal
    ${count}=   Get Element Count   xpath=//div[contains(@class, 'modal') and contains(@style,'display: block')]//div[contains(@class, 'alert-buttons')]
    IF  ${count} > 0
        Log     Clicking OK Button
        Click Button    OK
    END

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    group_name=body    value=${order}[Body]
    Input Text      text=${order}[Legs]   locator=//input[@type="number" and @placeholder="Enter the part number for the legs"]
    Input Text      address     ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    id:receipt
    Wait Until Page Contains Element    id:order-another
    

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${receipt_pdf_file_path}=   Set Variable   ${OUTPUT_DIR}${/}receipts${/}order_receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${receipt_pdf_file_path}
    [Return]    ${receipt_pdf_file_path}



Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${robot_picture_path}=   Set Variable   ${OUTPUT_DIR}${/}receipts${/}images${/}order_robot_${order_number}.png
    Screenshot      locator=//div[@id='robot-preview-image']    filename=${robot_picture_path}
    [Return]    ${robot_picture_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_file_path}  ${pdf_file_path}

    ${files}=    Create List
    ...     ${pdf_file_path}
    ...     ${screenshot_file_path}
    Add Files To PDF    ${files}    ${pdf_file_path}




Go to order another robot
    Wait Until Page Contains Element    id:order-another
    Click Button    order-another


Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}



    