
In this guide, map real operational data to ISA-95 models of performance and definition.
The dataset is from Kaggle, [Parts manufacturing industry](https://www.kaggle.com/datasets/gabrielsantello/parts-manufacturing-industry-dataset).

> This dataset contains details of 500 parts produced by each one of the 20 operators of a industry in one period of time.
> The perfect measures were not included in the context.
> Each operator has a different training background.

## Inspect the data

```sql
SELECT * FROM 'Piece_Dimension.csv'
LIMIT 1;
```
Yields the following data:

```
┌─────────┬────────┬────────┬────────┬──────────┐
│ Item_No │ Length │ Width  │ Height │ Operator │
│  int64  │ double │ double │ double │ varchar  │
├─────────┼────────┼────────┼────────┼──────────┤
│       1 │ 102.67 │  49.53 │  19.69 │ Op-1     │
└─────────┴────────┴────────┴────────┴──────────┘
```

## Map to ISA-95 entities

Normally, ask the data owner directly whenever you have any questions about the source of the data.
This is a public data set, so we can't ask the owner, but we can make some guesses.
**In real life, don't guess**.

Each row has an item number, measurements, and an operator.
The Item number is unique for each row, and the Operator column has values for one of 5 different operator IDs.
From this we reasonably say that a row of data describes an identifiable material that was produced by an identifiable personnel. In the production process, each part acquires properties whose values are in the measurements.

We also can infer that a process took place.
So, to describe this data in ISA-95 terms, we can contain each row in a _job response_, the smallest unit of work performance in the ISA standard.
The material is uniquely identifiable, so it is a _lot_. The introduction describes the lot as a "part," which means that it is likely a _sublot_ for some parent lot.

From these assumptions, we can create an ISA-95 model.

- The Item No represents a material sublot
- Since it was produced, the material also has a material actual, with material actual properties. These properties might reference a standard set of sublot properties.
- Since there is a material actual, there must be a job response (that is, a unit of work was performed).
- The job response also has a _personnel actual_, the operator who performed the job. Multiple jobs are performed by the same operator, so multiple _personnel actuals_ may reference the same personnel id.

![Example mapping](https://docs.rhize.com/images/s95/diagram-rhize-map-parts-operator.png)

### Transform expression

Input:

```json
  {
    "Item_No": 1,
    "Length": 102.67,
    "Width": 49.53,
    "Height": 19.69,
    "Operator": "Op-1"
  }
```

Transform expression. Optionally, add a `$prefix` string to make the operation identifiable.

```jsonata
(
$prefix := "20241101.c.";


$.{
    "id": $prefix & Item_No,
    "personnelActual":{
        "id": Item_No & "." & Operator,
        "person":{
            "id": $prefix & Operator,
            "label": $prefix & Operator
        }
    },
    "materialActual":[
        {
            "id": $prefix & Item_No & ".Prod",
            "materialUse": "Produced",
            "materialSubLot": {
                "id": $prefix & Item_No,
                "properties":[
                     {
                     "id": $prefix & Item_No & ".length",
                     "label": "Length",
                     "value": $string(Length)
                     },
                     {
                     "id": $prefix & Item_No & ".height",
                     "label": "Height",
                     "value": $string(Height)
                     },
                     {
                     "id": $prefix & Item_No & ".width",
                     "label": "Width",
                     "value": $string(Width)
                     }
            ]
            }
        }
    ]
}
)
```

Output:


```json
{
  "id": "20241101.c.1",
  "personnelActual": {
    "id": "1.Op-1",
    "person": {
      "id": "20241101.c.Op-1",
      "label": "20241101.c.Op-1"
    }
  },
  "materialActual": [
    {
      "id": "20241101.c.1.Prod",
      "materialUse": "Produced",
      "materialSubLot": {
        "id": "20241101.c.1",
        "properties": [
          {
            "id": "20241101.c.1.length",
            "label": "Length",
            "value": "102.67"
          },
          {
            "id": "20241101.c.1.height",
            "label": "Height",
            "value": "19.69"
          },
          {
            "id": "20241101.c.1.width",
            "label": "Width",
            "value": "49.53"
          }
        ]
      }
    }
  ]
}
```

## Integrate data through BPMN workflow

You could use this JSONata expression with a mutation in a BPMN workflow.
This way, the data gets standardized as it arrives.

In a real operation, these values might come in one at a time.
Data sources could include:
Operator input from a frontend
Tag values from an OPC UA server
MQTT messages sent to a topic on the Rhize broker

For details, read [Trigger BPMN workflows](https://docs.rhize.com/how-to/bpmn/trigger-workflows/).

## Query the data

Once the data is stored, you can use Graphql to make flexible queries.
For example, here is a query to get the job responses.

```gql
query{
  queryJobResponse(filter: {id:{regexp: "/^<YOUR_PREFIX>/"}}) {
    id
    materialActual {
      id
    }
    personnelActual {
      id
    }
  }
}
```

You can also query associated properties.
For example, you can query the Person to find all associated job responses, produced material, and measurements:

```gql
query personJobs{
  getPerson(id: "Op-5"){
    Op_5_actuals: personnelActual {
      id
      jobResponse {
        id
        materialActual {
          id
          properties {
            id
            quantity
            materialLotProperty {
              id
            }
          }
        }
      }
    }
  }
}
```

This returns an array of objects. One such item looks like this:

```
{
  "data": {
    "getPerson": {
      "Op_5_actuals": [
        {
          "id": "130.Op-5",
          "jobResponse": {
            "id": "20241029.130",
            "materialActual": [
              {
                "id": "20241029.130.Prod",
                "properties": [
                  {
                    "id": "20241029.130.length",
                    "quantity": 113.11,
                    "materialLotProperty": {
                      "id": "length"
                    }
                  },
                  {
                    "id": "20241029.130.height",
                    "quantity": 20.41,
                    "materialLotProperty": {
                      "id": "height"
                    }
                  },
                  {
                    "id": "20241029.130.width",
                    "quantity": 51.75,
                    "materialLotProperty": {
                      "id": "width"
                    }
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  }
}
```




In this guide, map real operational data to ISA-95 models of performance and definition.
The dataset in question is from kaggle, [Parts manufacturing industry dataset](https://www.kaggle.com/datasets/gabrielsantello/parts-manufacturing-industry-dataset).

> This dataset contains details of 500 parts produced by each one of the 20 operators of a industry in one period of time.
> The perfect measures were not included in the context.
> Each operator has a different training background.

## Inspect the data

```sql
SELECT * FROM 'Piece_Dimension.csv'
LIMIT 1;
```
Yields the following data:

```
┌─────────┬────────┬────────┬────────┬──────────┐
│ Item_No │ Length │ Width  │ Height │ Operator │
│  int64  │ double │ double │ double │ varchar  │
├─────────┼────────┼────────┼────────┼──────────┤
│       1 │ 102.67 │  49.53 │  19.69 │ Op-1     │
└─────────┴────────┴────────┴────────┴──────────┘
```

## Map to ISA-95 entities

Normally, you should ask the data owner any questions you have about the source of the data.
This is a public data set, so we can't ask the owner, but we can make some guesses.
**In real life, don't guess**.

Each row has item number, measurements, and an operator.
The Item number is unique for each row, and the Operator column has values for one of 5 different operator IDs.
From this we reasonably say that a row of data describes an identifiable material that produced by an identifiable personnel. In the process each part gets real properties, whose values are in the measurements.
We also can infer that a process took place.

So, to describe this data in ISA-95 terms, we can contain each row in a _job response_, the smallest unit of work performance in the ISA standard.
The material is uniquely identifiable, so it is a _lot_. The introduction describes the lot as a "part", which means that it is likely a _sublot_ for some parent lot.

From these assumptions, we can create an ISA-95 model.

- The Item No represents a material sublot
- Since it was produced, the material also has a material actual, with material actual properties. These properties might reference a standard set of sublot properties.
- Since there is a material actual, there must be a job response (that is, a unit of work was performed).
- The job response also has a _personnel actual_, the operator who performed the job. Multiple jobs are performed by the same operator, so multiple _personnel actuals_ may reference the same personnel id.

![Example mapping](https://docs.rhize.com/images/s95/diagram-rhize-map-parts-operator.png)

### Transform expression

Input:
```json
[
  {
    "Item_No": 1,
    "Length": 102.67,
    "Width": 49.53,
    "Height": 19.69,
    "Operator": "Op-1"
  },
  {
    "Item_No": 2,
    "Length": 102.5,
    "Width": 51.42,
    "Height": 19.63,
    "Operator": "Op-1"
  }
]
```

Transform expression. Optionally, add a `$prefix` string to make the operation identifiable.

```jsonata
(
$prefix := "";


$.{
    "id": $prefix & Item_No,
    "personnelActual":{
        "id": Item_No & "." & Operator,
        "person":{
            "id": Operator,
            "label": Operator
        }
    },
    "materialActual":[
        {
            "id": $prefix & Item_No & ".Prod",
            "materialUse": "Produced",
            "materialSubLot": {
                "id": $prefix & Item_No
            },
            "properties":[
                {
                "materialLotProperty":{
                    "id": "length"
                },
                "id": $prefix & Item_No & ".length",
                "label": "Length",
                "quantity": Length
                },
                {
                "materialLotProperty":{
                    "id": "height"
                },
                "id": $prefix & Item_No & ".height",
                "label": "Height",
                "quantity": Height
                },
                {
                "materialLotProperty":{
                    "id": "width"
                },
                "id": $prefix & Item_No & ".width",
                "label": "Width",
                "quantity": Width
                }
            ]
        }
    ]
}
)
```

Output:


```json
[
  {
    "id": "1",
    "personnelActual": {
      "id": "1.Op-1",
      "person": {
        "id": "Op-1",
        "label": "Op-1"
      }
    },
    "materialActual": [
      {
        "id": "1.Prod",
        "materialUse": "Produced",
        "materialSubLot": {
          "id": "1"
        },
        "properties": [
          {
            "materialLotProperty": {
              "id": "length"
            },
            "id": "1.length",
            "label": "Length",
            "quantity": 102.67
          },
          {
            "materialLotProperty": {
              "id": "height"
            },
            "id": "1.height",
            "label": "Height",
            "quantity": 19.69
          },
          {
            "materialLotProperty": {
              "id": "width"
            },
            "id": "1.width",
            "label": "Width",
            "quantity": 49.53
          }
        ]
      }
    ]
  },
  {
    "id": "2",
    "personnelActual": {
      "id": "2.Op-1",
      "person": {
        "id": "Op-1",
        "label": "Op-1"
      }
    },
    "materialActual": [
      {
        "id": "2.Prod",
        "materialUse": "Produced",
        "materialSubLot": {
          "id": "2"
        },
        "properties": [
          {
            "materialLotProperty": {
              "id": "length"
            },
            "id": "2.length",
            "label": "Length",
            "quantity": 102.5
          },
          {
            "materialLotProperty": {
              "id": "height"
            },
            "id": "2.height",
            "label": "Height",
            "quantity": 19.63
          },
          {
            "materialLotProperty": {
              "id": "width"
            },
            "id": "2.width",
            "label": "Width",
            "quantity": 51.42
          }
        ]
      }
    ]
  }
]
```

## Integrate data through BPMN workflow

You could use the preceding JSONata expression with a mutation in a BPMN workflow,
then set up a [Trigger](https://docs.rhize.com/how-to/bpmn/trigger-workflows/) so that the data gets standardized automatically as it arrives.

The trigger might be input data from the operator, OPC-UA tag values, or an MQTT message to a topic on a data source or the Rhize broker.

## Query the data

Once the data is stored, you can use Graphql for flexible queries.
For example, here is a query to get the job responses.

You can also query associated properties.
For example, you can query the Person to find all associated job responses, produced material, and measurements:

```gql
query personJobs{
  getPerson(id: "Op-5"){
    Op_5_actuals: personnelActual {
      id
      jobResponse {
        id
        materialActual {
          id
          properties {
            id
            quantity
            materialLotProperty {
              id
            }
          }
        }
      }
    }
  }
}
```

This returns an array of objects. One such item looks like this:

```
{
  "data": {
    "getPerson": {
      "Op_5_actuals": [
        {
          "id": "130.Op-5",
          "jobResponse": {
            "id": "20241029.130",
            "materialActual": [
              {
                "id": "20241029.130.Prod",
                "properties": [
                  {
                    "id": "20241029.130.length",
                    "quantity": 113.11,
                    "materialLotProperty": {
                      "id": "length"
                    }
                  },
                  {
                    "id": "20241029.130.height",
                    "quantity": 20.41,
                    "materialLotProperty": {
                      "id": "height"
                    }
                  },
                  {
                    "id": "20241029.130.width",
                    "quantity": 51.75,
                    "materialLotProperty": {
                      "id": "width"
                    }
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  }
}
```

