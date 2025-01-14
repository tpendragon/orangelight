# PUL Requests

Requests was once a separate gem housed [in a separate repository](https://github.com/pulibrary/requests).  To review code history and issues visit that repository.
The gem was integrated into orangelight in April of 2022 by moving the code from one repository to the other and making minimal changes.  Files in orangelight should be in the same folders in the Request repository.  As this code gets more fully integrated and changes there may not be a corresponding file in the old repository.

## External Interfaces

```mermaid
  graph TD;
  accTitle: External interfaces used to make requests in orangelight.
  accDescr: These interfaces are Alma EDD and Print, Recap/SCSB EDD and Print, Ciasoft Print, Illiad EDD and Print, AEON Print, Borrow Direct Print, Email Print.
      A[Requests]-->B[Alma EDD and Print];
      A[Requests]-->C[Recap/SCSB EDD and Print];
      A[Requests]-->D[Ciasoft Print];
      A[Requests]-->E[Illiad EDD and Print];
      A[Requests]-->F[AEON Print];
      A[Requests]-->G[Borrow Direct Print];
      A[Requests]-->H[Email Print];
```

* [Borrow Direct](https://catalog.princeton.edu/borrow-direct)
  * Used to find items from partners. Has switched to the [ReShare platform](https://projectreshare.org/), and requests are made via Illiad (see below)
* Illiad
  Can cancel request from [orangelight](https://catalog.princeton.edu/account/digitization_requests)
  * Used to request unavailable items that are deemed eligible for a resource sharing request
  * Used to request Digitizations
* [Alma](https://princeton.alma.exlibrisgroup.com/discovery/account?vid=01PRI_INST:Services&lang=EN&section=overview)
  can cancel request by connecting to the URL above
  * Used to request pick-up of available items on the shelf
  * Holds are created for ReCAP Items when physical delivery is requested
  * Holds are requested for Marquand Offsite (clancy) items when physical or digital item is requested
* Clancy (ciasoft)
  All requests on qa and staging go to a test system, so they do not need to be canceled
  * Used to request items from Marquand
    1. Check if items are present in Clancy (all Marquand items not stored in ReCAP)
    1. If present both digital and pick-up request require the physical item to be sent to Princeton campus
* ReCAP    
    Important: **cannot cancel requests sent to ReCAP**
  * Used to request physical pickup of off site materials.    
    Important: **a hold in Alma is also created for a physical request.  This can and should be canceled during testing.**
  * Used to request a digital copy of off site materials.    
    Important: **test should be put in as many fields as possible in a test request.  Usually they note the test and do not do the digitization**

## Basic Usage

### Routes
A request form can be generated by passing a record identifier within the following route:

```/requests/{mms_id}?mfhd={holding_id}``` Example: https://catalog.princeton.edu/requests/9997021693506421?aeon=false&mfhd=22597335790006421    

## Getting a Count of Requested Clancy Items

1. Start the Rails console in one of the catalog web servers
```
bundle exec rails c
```

2. Example Commands
```
Command 1: item = Requests::ClancyItem.new()
Command 2: item.send(:get_clancy, url: "retrievedlist/v1/20220101/20220401/MQ")
```
3. Canceling a Request
```
Command 1: body = { "requests": [{ "request_type": "CANCEL", "barcode": "12345678901234", "stop": 'MQ', request_id: "32101103768097-22101008595068-1649085248
"}]}
Command 2: response = item.send(:post_clancy, url: "circrequests/v1", body: body.to_json)
```

## Architecture

### Rendering the request form

```mermaid
sequenceDiagram
    title Rendering the request form
    actor patron as Patron
    patron->>FormController: Go to form
    FormController->>Request: Create new Request object
    Request->>Requestable: Create new Requestable objects
    FormController->>FormDecorator: Create new FormDecorator based on the Request
    FormDecorator->>RequestableDecorator: Create new RequestableDecorators based on the list of Requestable objects in the Request
    FormController->>patron: Render the form for the user
```

### Placing the request


```mermaid
sequenceDiagram
    title Placing the request
    actor patron as Patron
    patron->>FormController: Select options and press submit
    FormController->>Submission: Create a new Submission
    Submission->>SelectedItemsValidator: Validate using a SelectedItemsValidator object
    Submission->>Service: Create an instance of a Service subclass (e.g. Requests::Submissions::DigitizeItem)
    Service->>RequestMailer: Send emails on success
    FormController->>RequestMailer: Send emails on failure
    FormController->>patron: Inform patron how the request went
```
