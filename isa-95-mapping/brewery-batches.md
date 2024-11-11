# Map Brewery Batch Data to ISA-95

https://www.kaggle.com/datasets/ankurnapa/brewery-operations-and-market-analysis-dataset

Overview:
> This dataset presents an extensive collection of data from a craft beer brewery, spanning from January 2020 to January 2024. It encapsulates a rich blend of brewing parameters, sales data, and quality assessments, providing a holistic view of the brewing process and its market implications.

## Inspect the data


```
SELECT column_name|column_type
FROM (DESCRIBE SELECT * FROM 'brewery_data_complete_extended.csv');
```


```
┌──────────────────────────────┬─────────────┐
│         column_name          │ column_type │
│           varchar            │   varchar   │
├──────────────────────────────┼─────────────┤
│ Batch_ID                     │ VARCHAR     │
│ Brew_Date                    │ TIMESTAMP   │
│ Beer_Style                   │ VARCHAR     │
│ SKU                          │ VARCHAR     │
│ Location                     │ VARCHAR     │
│ Fermentation_Time            │ BIGINT      │
│ Temperature                  │ DOUBLE      │
│ pH_Level                     │ DOUBLE      │
│ Gravity                      │ DOUBLE      │
│ Alcohol_Content              │ DOUBLE      │
│ Bitterness                   │ BIGINT      │
│ Color                        │ BIGINT      │
│ Ingredient_Ratio             │ VARCHAR     │
│ Volume_Produced              │ BIGINT      │
│ Total_Sales                  │ DOUBLE      │
│ Quality_Score                │ DOUBLE      │
│ Brewhouse_Efficiency         │ DOUBLE      │
│ Loss_During_Brewing          │ DOUBLE      │
│ Loss_During_Fermentation     │ DOUBLE      │
│ Loss_During_Bottling_Kegging │ DOUBLE      │
├──────────────────────────────┴─────────────┤
│ 20 rows                          2 columns │
└────────────────────────────────────────────┘
```


Sales data is out of scope for ISA-95, but all these other properties fit into the model.

Two fields have a small set of unique values:

```
 SELECT DISTINCT beer_style from t;
```

```
┌────────────┐
│ Beer_Style │
│  varchar   │
├────────────┤
│ Lager      │
│ Stout      │
│ Sour       │
│ IPA        │
│ Pilsner    │
│ Wheat Beer │
│ Porter     │
│ Ale        │
└────────────┘
```

```SQL
SELECT DISTINCT Location from t;
```

```

┌─────────────────┐
│    Location     │
│     varchar     │
├─────────────────┤
│ Jayanagar       │
│ Rajajinagar     │
│ HSR Layout      │
│ Marathahalli    │
│ Indiranagar     │
│ Koramangala     │
│ Whitefield      │
│ Malleswaram     │
│ Yelahanka       │
│ Electronic City │
├─────────────────┤
│     10 rows     │
└─────────────────┘
```

## Map data to ISA-95


The following transformation expression maps the source dataset to ISA-95.
While the expression adds context and relationships, it also tries to avoid unnecessary inferences.


The only implied fields are:
- The job responses. As the job response is the smallest unit of work in ISA-95, a job response object is necessary to create a container for a batch performance.

  Since brewing, fermentation, and bottling all have their own loss parameters, we are going to separate these processes into child job responses.
- Material definitions and equipment ids. The `Beer_Style` and `Location` fields have the same fields across 10 million rows. This transformation assumes that these refer to shared objects. So each `Beer_Style` gets a material definition and each location maps to an equipment area.

  This transformation assumes that the version of each of these objects is `"1"`.

<details>
  
<summary>Input JSON</summary>

```json
[
  {
    "Batch_ID": "0004038",
    "Brew_Date": "2020-01-01 00:07:27",
    "Beer_Style": "Lager",
    "SKU": "Cans",
    "Location": "Rajajinagar",
    "Fermentation_Time": 17,
    "Temperature": 17.122159957506383,
    "pH_Level": 5.1991104812087,
    "Gravity": 1.0411437419707774,
    "Alcohol_Content": 5.946134604849364,
    "Bitterness": 33,
    "Color": 5,
    "Ingredient_Ratio": "1:0.21:0.18",
    "Volume_Produced": 3320,
    "Total_Sales": 17591.943665500272,
    "Quality_Score": 9.591767047394432,
    "Brewhouse_Efficiency": 82.12133297547287,
    "Loss_During_Brewing": 4.384337331071963,
    "Loss_During_Fermentation": 4.204139512963197,
    "Loss_During_Bottling_Kegging": 3.6211740792630325
  },
  {
    "Batch_ID": "3886278",
    "Brew_Date": "2020-01-01 00:07:35",
    "Beer_Style": "Lager",
    "SKU": "Kegs",
    "Location": "Jayanagar",
    "Fermentation_Time": 15,
    "Temperature": 18.619302931119375,
    "pH_Level": 4.53287889755344,
    "Gravity": 1.03411721040703,
    "Alcohol_Content": 5.863576331843152,
    "Bitterness": 48,
    "Color": 15,
    "Ingredient_Ratio": "1:0.36:0.24",
    "Volume_Produced": 3599,
    "Total_Sales": 16420.496759132024,
    "Quality_Score": 7.87839585495581,
    "Brewhouse_Efficiency": 83.04968700310678,
    "Loss_During_Brewing": 3.553205213034005,
    "Loss_During_Fermentation": 2.7030556858591464,
    "Loss_During_Bottling_Kegging": 1.7366887369684196
  }
]
```
</summary>
</details>



<details>
  
<summary>Transform expression</summary>
  


```jsonata
(
  /* use for identifiable prefix */
  $prefix := "MY_PREFIX.A.1" ;

  $payload := $map(
    $,
    function(
      $v,
      $i
    ) {
      (
        $id := $prefix & "." & $v.Batch_ID;
        $makeProp := function(
          $key,
          $description
        ) {
          { "id": $id & "." & $key, "label": $string($key), "value": $string($lookup($key)[$i]), "description": $description }
        };
        {
          "id": $id,
          "equipmentActual": [
            {
              "id": $id & "." & $v.Location,
              "equipmentVersion": {
                 "id": $v.Location,
                  "version": "1"
          }
            
            }
            ],
          "children": [
            {
              "id": $id & ".brew",
              "description": "brewing",
              "startDateTime": $replace($v.Brew_Date, " ", "T"),
              "data": [
                $makeProp("Loss_During_Brewing", ""),
                $makeProp("Temperature", "The average temperature (in Celsius) maintained during the brewing process.")
              ]
            },
            {
              "id": $id & ".fermentation",
              "description": "fermentation",
              "data": [
                $makeProp("Loss_During_Fermentation", "The percentage of volume loss during the fermentation process."),
                $makeProp("Fermentation_Time", "The average temperature (in Celsius) maintained during the brewing process.")
              ]
            },
            {
              "id": $id & ".bottling",
              "description": "bottling",
              "data": [$makeProp("Loss_During_Bottling_Kegging", "")]
            }
          ],
          "materialActual": {
            "id": $id & ".prod",
            "materialLot": [
              {
                "id": $id,
                "quantity": $v.Volume_Produced,
                "quantityUnitOfMeasure": { "id": "liters" },
                "materialDefinition": { "id": $v.Beer_Style, "label": $v.Beer_Style },
                "materialDefinitionVersion": {
                  "id": $v.Beer_Style,
                  "version": "1",
                  "versionStatus": "ACTIVE",
                  "materialDefinition": { "id": $v.Beer_Style & "whatIfDefNoExist", "label": $v.Beer_Style & "whatIfDefNoExist" }
                },
                "properties": [
                  $makeProp("pH_Level", "The pH level of the beer, indicating its acidity or alkalinity."),
                  $makeProp("Gravity", "A measure of the density of the beer as compared to water, indicating the potential alcohol content."),
                  $makeProp("Alcohol_Content", "The percentage of alcohol by volume in the beer."),
                  $makeProp("Bitterness", "The bitterness of the beer, measured in International Bitterness Units (IBU)."),
                  $makeProp("Color", "The color of the beer measured using the Standard Reference Method (SRM)."),
                  $makeProp("Ingredient_Ratio", "The ratio ingredients as water : grains: hops."),
                  $makeProp("Quality_Score", "An overall quality score assigned to the beer batch, rated out of 10.")
                ]
              }
            ]
          }
        }
      )
    }
  );
  { "upsert": true, "input": $payload }
)
```

</details>

<details>
  
<summary> Transformed output</summary>
  
```json
{
  "upsert": true,
  "input": [
    {
      "id": "MY_PREFIX.A.1.0004038",
      "equipmentActual": [
        {
          "id": "MY_PREFIX.A.1.0004038.Rajajinagar",
          "equipmentVersion": {
            "id": "Rajajinagar",
            "version": "1"
          }
        }
      ],
      "children": [
        {
          "id": "MY_PREFIX.A.1.0004038.brew",
          "description": "brewing",
          "startDateTime": "2020-01-01T00:07:27",
          "data": [
            {
              "id": "MY_PREFIX.A.1.0004038.Loss_During_Brewing",
              "label": "Loss_During_Brewing",
              "value": "4.38433733107196",
              "description": ""
            },
            {
              "id": "MY_PREFIX.A.1.0004038.Temperature",
              "label": "Temperature",
              "value": "17.1221599575064",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "MY_PREFIX.A.1.0004038.fermentation",
          "description": "fermentation",
          "data": [
            {
              "id": "MY_PREFIX.A.1.0004038.Loss_During_Fermentation",
              "label": "Loss_During_Fermentation",
              "value": "4.2041395129632",
              "description": "The percentage of volume loss during the fermentation process."
            },
            {
              "id": "MY_PREFIX.A.1.0004038.Fermentation_Time",
              "label": "Fermentation_Time",
              "value": "17",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "MY_PREFIX.A.1.0004038.bottling",
          "description": "bottling",
          "data": [
            {
              "id": "MY_PREFIX.A.1.0004038.Loss_During_Bottling_Kegging",
              "label": "Loss_During_Bottling_Kegging",
              "value": "3.62117407926303",
              "description": ""
            }
          ]
        }
      ],
      "materialActual": {
        "id": "MY_PREFIX.A.1.0004038.prod",
        "materialLot": [
          {
            "id": "MY_PREFIX.A.1.0004038",
            "quantity": 3320,
            "quantityUnitOfMeasure": {
              "id": "liters"
            },
            "materialDefinition": {
              "id": "Lager",
              "label": "Lager"
            },
            "materialDefinitionVersion": {
              "id": "Lager",
              "version": "1",
              "versionStatus": "ACTIVE",
              "materialDefinition": {
                "id": "LagerwhatIfDefNoExist",
                "label": "LagerwhatIfDefNoExist"
              }
            },
            "properties": [
              {
                "id": "MY_PREFIX.A.1.0004038.pH_Level",
                "label": "pH_Level",
                "value": "5.1991104812087",
                "description": "The pH level of the beer, indicating its acidity or alkalinity."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Gravity",
                "label": "Gravity",
                "value": "1.04114374197078",
                "description": "A measure of the density of the beer as compared to water, indicating the potential alcohol content."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Alcohol_Content",
                "label": "Alcohol_Content",
                "value": "5.94613460484936",
                "description": "The percentage of alcohol by volume in the beer."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Bitterness",
                "label": "Bitterness",
                "value": "33",
                "description": "The bitterness of the beer, measured in International Bitterness Units (IBU)."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Color",
                "label": "Color",
                "value": "5",
                "description": "The color of the beer measured using the Standard Reference Method (SRM)."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Ingredient_Ratio",
                "label": "Ingredient_Ratio",
                "value": "1:0.21:0.18",
                "description": "The ratio ingredients as water : grains: hops."
              },
              {
                "id": "MY_PREFIX.A.1.0004038.Quality_Score",
                "label": "Quality_Score",
                "value": "9.59176704739443",
                "description": "An overall quality score assigned to the beer batch, rated out of 10."
              }
            ]
          }
        ]
      }
    },
    {
      "id": "MY_PREFIX.A.1.3886278",
      "equipmentActual": [
        {
          "id": "MY_PREFIX.A.1.3886278.Jayanagar",
          "equipmentVersion": {
            "id": "Jayanagar",
            "version": "1"
          }
        }
      ],
      "children": [
        {
          "id": "MY_PREFIX.A.1.3886278.brew",
          "description": "brewing",
          "startDateTime": "2020-01-01T00:07:35",
          "data": [
            {
              "id": "MY_PREFIX.A.1.3886278.Loss_During_Brewing",
              "label": "Loss_During_Brewing",
              "value": "3.553205213034",
              "description": ""
            },
            {
              "id": "MY_PREFIX.A.1.3886278.Temperature",
              "label": "Temperature",
              "value": "18.6193029311194",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "MY_PREFIX.A.1.3886278.fermentation",
          "description": "fermentation",
          "data": [
            {
              "id": "MY_PREFIX.A.1.3886278.Loss_During_Fermentation",
              "label": "Loss_During_Fermentation",
              "value": "2.70305568585915",
              "description": "The percentage of volume loss during the fermentation process."
            },
            {
              "id": "MY_PREFIX.A.1.3886278.Fermentation_Time",
              "label": "Fermentation_Time",
              "value": "15",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "MY_PREFIX.A.1.3886278.bottling",
          "description": "bottling",
          "data": [
            {
              "id": "MY_PREFIX.A.1.3886278.Loss_During_Bottling_Kegging",
              "label": "Loss_During_Bottling_Kegging",
              "value": "1.73668873696842",
              "description": ""
            }
          ]
        }
      ],
      "materialActual": {
        "id": "MY_PREFIX.A.1.3886278.prod",
        "materialLot": [
          {
            "id": "MY_PREFIX.A.1.3886278",
            "quantity": 3599,
            "quantityUnitOfMeasure": {
              "id": "liters"
            },
            "materialDefinition": {
              "id": "Lager",
              "label": "Lager"
            },
            "materialDefinitionVersion": {
              "id": "Lager",
              "version": "1",
              "versionStatus": "ACTIVE",
              "materialDefinition": {
                "id": "LagerwhatIfDefNoExist",
                "label": "LagerwhatIfDefNoExist"
              }
            },
            "properties": [
              {
                "id": "MY_PREFIX.A.1.3886278.pH_Level",
                "label": "pH_Level",
                "value": "4.53287889755344",
                "description": "The pH level of the beer, indicating its acidity or alkalinity."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Gravity",
                "label": "Gravity",
                "value": "1.03411721040703",
                "description": "A measure of the density of the beer as compared to water, indicating the potential alcohol content."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Alcohol_Content",
                "label": "Alcohol_Content",
                "value": "5.86357633184315",
                "description": "The percentage of alcohol by volume in the beer."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Bitterness",
                "label": "Bitterness",
                "value": "48",
                "description": "The bitterness of the beer, measured in International Bitterness Units (IBU)."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Color",
                "label": "Color",
                "value": "15",
                "description": "The color of the beer measured using the Standard Reference Method (SRM)."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Ingredient_Ratio",
                "label": "Ingredient_Ratio",
                "value": "1:0.36:0.24",
                "description": "The ratio ingredients as water : grains: hops."
              },
              {
                "id": "MY_PREFIX.A.1.3886278.Quality_Score",
                "label": "Quality_Score",
                "value": "7.87839585495581",
                "description": "An overall quality score assigned to the beer batch, rated out of 10."
              }
            ]
          }
        ]
      }
    }
  ]
}

```
</details>

## Extensions

An extended version of this model may use material classes to categorize the material and properties.
