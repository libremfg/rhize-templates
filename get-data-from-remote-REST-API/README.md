# Get Data from REST API

This workflow uses the public [NASA Earth Event API](https://eonet.gsfc.nasa.gov/) to periodically query about recent earth events.

It works as follows:
1. Starts from a call to the API.
1. Recieves the payload and transforms some properties to a new JSON representation.
1. Returns the mapped JSON to report the last ten days of Earth events in the [`customResponse`](https://docs.rhize.com/how-to/bpmn/trigger-workflows/#customresponse).


## JSONata filter

The REST service task makes a GET request to the endpoint
`https://eonet.gsfc.nasa.gov/api/v2.1/events?days=10`

This returns a data set like this:

```json
{
	"title": "EONET Events",
	"description": "Natural events from EONET.",
	"link": "https://eonet.gsfc.nasa.gov/api/v2.1/events",
	"events": [
		{
			"id": "EONET_6511",
			"title": "Bagana Volcano, Papua New Guinea",
            "description": "",
			"link": "https://eonet.gsfc.nasa.gov/api/v2.1/events/EONET_6511",
			"categories": [
				{
					"id": 12,
					"title": "Volcanoes"
				}
			],
			"sources": [
				{
					"id": "SIVolcano",
					"url": "http://volcano.si.edu/volcano.cfm?vn=255020"
				}
			
			],
			"geometries": [
				{
					"date": "2024-04-22T00:00:00Z",
					"type": "Point", 
					"coordinates": [ 155.196, -6.137 ]
				}
			
			]
		}
	]
}

```

The service task filters this data with the JSONata input expression:

```javascript
$exists(events[0])
    ? events.{
    "id":id,
    "link":link,
    "category":categories.title,
    "time":geometries.date
    }

   : "No earth events lately" 
```

If Earth events have happened in the specified number of days,
the expression maps the data to custom response as follows:

```JSONata
"customResponse": {
   "category": "Volcanoes",
   "id": "EONET_6511",
   "link": "https://eonet.gsfc.nasa.gov/api/v2.1/events/EONET_6511",
   "time": "2024-04-22T00:00:00Z"
}
```
