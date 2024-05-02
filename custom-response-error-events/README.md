# Error handling with custom response


![custom response error event](https://raw.githubusercontent.com/libremfg/libremfg.github.io/main/static/images/bpmn/screenshot-rhize-bpmn-error-handling-custom-response.png)

This BPMN workflow uses the [`customResponse`](https://docs.rhize.com/how-to/bpmn/trigger-workflows/#customresponse) in the END events
to report errors in workflows started from the `createAndRunBPMNSync` API call.
If the variable in the API payload matches the evaluation condition, it reports success.
Otherwise, it reports error.

To run, download the BPMN file, import it into your UI environment, and set it to active.
Then, trigger the workflow with this command:

**Query**


```graphql
mutation SynchronousCall($createAndRunBpmnSyncId: String!, $variables: String ) {
  createAndRunBpmnSync(id: $createAndRunBpmnSyncId, variables: $variables) {
    id
    jobState
    customResponse
  }
}
```

**Variables**

```json
{
  "createAndRunBpmnSyncId": "API_demo_errorHandlingCustomResponse",
  "variables": "{\"input\":{\"message\":\"CORRECT\"}}"
}
```


A successful run should return the following response:

```json
{
  "data": {
    "createAndRunBpmnSync": {
      "id": "920c4baedd5717ddd7bced7cf8ea1a47",
      "jobState": "COMPLETED",
      "customResponse": "Workflow ran correctly"
    }
  }
}

```

Now change the `variables.input.message` to a different string and run it again.
What does the `customResponse` say?


