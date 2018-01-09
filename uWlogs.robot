*** Settings ***
Library    Collections
Library    RequestsLibrary

Suite Setup    Create http session
Suite Teardown     Delete all sessions

*** Variables ***
${host}    http://localhost:8000
${wlogs session}    wLogs
${user}   janedoe
${topic}    have-a-good-day
${content}    hello world!!!

*** Test Cases ***
Create a new user
    ${response}=    Create user    ${user}
    Should response as Created    ${response}

Create a duplicate user
    Ensure user    ${user}
    ${response}=    Create user    ${user}
    Should response as OK    ${response}

Create a new wlog with an exist user
    Ensure user    ${user}
    ${response}=    Create wlog    ${user}    ${topic}    ${content}
    Should response as Created    ${response}

Create a new wlog unknown user
    ${response}=    Create wlog      unknown-user    a-new-topic    ${content}
    Should response as Bad Request    ${response}

Create a new wlog with existing user and topic
    Ensure wlog    ${user}    ${topic}    ${content}
    ${response}=    Create wlog    ${user}    ${topic}    ${content}
    Should response as Bad Request    ${response}

Get a wlog with exist user and topic
    Ensure wlog    ${user}    ${topic}    ${content}
    ${response}=    Get wlog    ${user}    ${topic}
    Should response as OK    ${response}
    Should return wlog as    ${response}    ${content}

Get a wlog with not exist user
    ${response}=    Get wlog    unknown-user    ${topic}
    Should response as Bad Request    ${response}

Get a wlog with exist user but not-exist topic
    Ensure user    ${user}
    ${response}=    Get wlog    ${user}    unknown-topic
    Should response as Not Found    ${response}

List wlog of specific user
    Ensure wlog    ${user}    topic1    ${content}
    Ensure wlog    ${user}    topic2    ${content}
    Ensure wlog    another-user     topic3     ${content}
    ${response}=    List wlogs of    ${user}
    Should response as OK    ${response}
    Should response list containing    ${response}    topic1
    Should response list containing    ${response}    topic2


*** Keywords ***
Create http session
    Create session    ${wlogs session}    ${host}

Create user
    [Arguments]    ${user}
    ${response}=    Post Request    ${wlogs session}    wlog/${user}
    [Return]    ${response}

Ensure user
    [Arguments]    ${user}
    Create user    ${user}

Create wlog
    [Arguments]    ${user}    ${topic}    ${content}
    ${body}=    Catenate    SEPARATOR=    {"text":"    ${content}    "}
    Log    ${body}
    ${response}=    Post Request    ${wlogs session}    wlog/${user}/${topic}    ${body}
    [Return]    ${response}

Ensure wlog
    [Arguments]    ${user}    ${topic}    ${content}
    Ensure user    ${user}
    Create wlog    ${user}    ${topic}    ${content}

Get wlog
    [Arguments]    ${user}    ${topic}
    ${response}    Get Request    ${wlogs session}    wlog/${user}/${topic}
    [Return]   ${response}

List wlogs of
    [Arguments]    ${user}
    ${response}    Get Request    ${wlogs session}    wlog/${user}
    [Return]   ${response}

Should return wlog as
    [Arguments]     ${response}    ${content}
    Log Dictionary    ${response.json()}    level=DEBUG
    Dictionary should contain item    ${response.json()}    text    ${content}

Should response list containing
    [Arguments]    ${response}    ${topic}
    ${response_json}=    Call method    ${response}    json
    Dictionary should contain key    ${response_json}    topics
    ${response_topics}=    Get From Dictionary    ${response_json}    topics
    List should contain value   ${response_topics}    ${topic}
    
Assert HTTP response status code
    [Arguments]    ${response}    ${expected code}
    Should be equal as strings     ${response.status_code}    ${expected code}

Should response as Created
    [Arguments]    ${response}
    Assert HTTP response status code    ${response}    201

Should response as OK
    [Arguments]    ${response}
    Assert HTTP response status code    ${response}    200

Should response as Bad Request
    [Arguments]    ${response}
    Assert HTTP response status code    ${response}    400

Should response as Not Found
    [Arguments]    ${response}
    Assert HTTP response status code    ${response}    404

