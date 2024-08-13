This minimal task workflow is started from the API and sends a custom response back to system that made the call.

To run:
1. Upload it to your environment:
2. Start it with `createAndRunBPMNSync`

    ```gql
    mutation CreateAndRunBpmnSync(
      $createAndRunBpmnId: String!
      $createAndRunBpmnVariables: String
      $createAndRunBpmnDebug: Boolean
    ) {
      createAndRunBpmnSync(
        id: $createAndRunBpmnId
        variables: $createAndRunBpmnVariables
        debug: $createAndRunBpmnDebug
      ) {
        id
        jobState
        traceID
        customResponse
      }
    }
    ```
    
    ```json
    {
      "createAndRunBpmnId": "API_demo_custom_response",
      "createAndRunBpmnVariables":"{\"input\":{\"message\": \"this workflow ran correctly\"}}",
    }
    ```

On success, Rhize returns a response that prefaces the value of `input.message` with "`Good news:`.
