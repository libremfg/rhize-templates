# Get Data from REST API

This workflow uses the public [NASA Earth Event API](https://eonet.gsfc.nasa.gov/) to periodically query about recent earth events.

It works as follows:
1. Starts from a call to the API.
1. Receives the payload and transforms some properties to an `operationsEvent` object.
1. Passes this object as the input for a GraphQL mutation on the Rhize DB.
1. Returns the GraphQL response as [`customResponse`](https://docs.rhize.com/how-to/bpmn/trigger-workflows/#customresponse).


## JSONata filter

The REST service task makes a GET request to the endpoint
`https://eonet.gsfc.nasa.gov/api/v2.1/events?days=10`

This returns a data set like this:

```json
```

The service task filters this data with the JSONata input expression:

```javascript

(
$count(events[0]) > 0

    ? events.{
    "id": "" & id,
    "description":title,
    "category":categories.title,
    "recordTimestamp": $sort(geometry.date)[0],
    "effectiveStart": $sort(geometry.date)[0],
    "effectiveEnd": $sort(geometry.date)[$count(geometry.date)-1],
    "source": sources.id & " " & sources.url,
    "operationsEventDefinition": {
        "id": "Earth event",
        "label": "Earth event"
        }
    }

    : {"message":"No earth events lately"}

)

```

If Earth events have happened in the specified number of days,
the expression maps the data to custom response as follows:

```json
[
    {
    "id": "EONET_6519",
    "description": "Tropical Cyclone 25S",
    "category": "Severe Storms",
    "recordTimestamp": "2024-05-19T18:00:00Z",
    "effectiveStart": "2024-05-19T18:00:00Z",
    "effectiveEnd": "2024-05-20T06:00:00Z",
    "source": "JTWC https://www.metoc.navy.mil/jtwc/products/sh2524.tcw",
    "operationsEventDefinition": {
      "id": "Earth event",
      "label": "Earth event"
      }
    }
]
```
