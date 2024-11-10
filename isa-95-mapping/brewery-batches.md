# Map Brewery Batch Data to ISA-95

https://www.kaggle.com/datasets/ankurnapa/brewery-operations-and-market-analysis-dataset

Overview:
> This dataset presents an extensive collection of data from a craft beer brewery| spanning from January 2020 to January 2024. It encapsulates a rich blend of brewing parameters| sales data| and quality assessments| providing a holistic view of the brewing process and its market implications.

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

Since brewing, fermentaion, and bottling all have their own loss parameters, we are going to separate these processes into child job responses.

## Example: Expression with material actual properties


This expression maps as closely as possible to the dataset.
The only implied fields are the top-level job response object, which is the smallest unit of work in ISA-95.




<details>
  
<summary>Input JSON</summary>

```json
[
  {
    "Batch_ID": "7870796",
    "Brew_Date": "2020-01-01 00:00:19",
    "Beer_Style": "Wheat Beer",
    "SKU": "Kegs",
    "Location": "Whitefield",
    "Fermentation_Time": 16,
    "Temperature": 24.204250857069873,
    "pH_Level": 5.2898454476095615,
    "Gravity": 1.0395041267301979,
    "Alcohol_Content": 5.370842159553436,
    "Bitterness": 20,
    "Color": 5,
    "Ingredient_Ratio": "1:0.32:0.16",   
    "Volume_Produced": 4666,
    "Total_Sales": 2664.7593448382822,
    "Quality_Score": 8.57701633109399,
    "Brewhouse_Efficiency": 89.19588216376087,
    "Loss_During_Brewing": 4.1049876591878345,
    "Loss_During_Fermentation": 3.2354851724654683,
    "Loss_During_Bottling_Kegging": 4.663204448186049
  },
  {
    "Batch_ID": "9810411",
    "Brew_Date": "2020-01-01 00:00:31",
    "Beer_Style": "Sour",
    "SKU": "Kegs",
    "Location": "Whitefield",
    "Fermentation_Time": 13,
    "Temperature": 18.086762947259544,
    "pH_Level": 5.275643382756193,
    "Gravity": 1.0598189516987164,
    "Alcohol_Content": 5.096053082797625,
    "Bitterness": 36,
    "Color": 14,
    "Ingredient_Ratio": "1:0.39:0.24",
    "Volume_Produced": 832,
    "Total_Sales": 9758.801062471319,
    "Quality_Score": 7.420540752553908,
    "Brewhouse_Efficiency": 72.4809153900275,
    "Loss_During_Brewing": 2.6765280953921122,
    "Loss_During_Fermentation": 4.2461292104108574,
    "Loss_During_Bottling_Kegging": 2.04435836917023
  }
]
```
</summary>
</details>



<details>
  
<summary>Transform expression</summary>
  


```jsonata
(
  $payload := $map(
    $,
    function(
      $v,
      $i
    ) {
      (
        $id := "PREFIX." & $v.Batch_ID;
        $makeJrData := function(
          $key,
          $description
        ) {
          { "id": $id & "." & $key,
          "label": $string($key),
          "value": $string($lookup($key)[$i]),
          "description": $description }
        };
         $makeProp := function(
          $key,
          $description
        ) {
          { "id": $id & "." & $key,
          "label": $string($key),
          "quantity": $type($lookup($key)[$i]) = "string" ? null : $lookup($key)[$i],
          "value": $string($lookup($key)[$i]),
          "description": $description }
        };

        {
          "id": $id,
          "equipmentActual": [{ "id": $id &  "." & $v.Location }],
          "children": [
            {
              "id": $id & ".brew",
              "description": "brewing",
              "startDateTime": $replace($v.Brew_Date, " ", "T"),
              "data": [
                $makeJrData("Loss_During_Brewing", ""),
                $makeJrData("Temperature", "The average temperature (in Celsius) maintained during the brewing process.")
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
            "quantity": $v.Volume_Produced,
            /* "quanitityUnitOfMeasure": { "id": "liters" }, */
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
      "id": "PREFIX.7870796",
      "equipmentActual": [
        {
          "id": "PREFIX.7870796.Whitefield"
        }
      ],
      "children": [
        {
          "id": "PREFIX.7870796.brew",
          "description": "brewing",
          "startDateTime": "2020-01-01T00:00:19",
          "data": [
            {
              "id": "PREFIX.7870796.Loss_During_Brewing",
              "label": "Loss_During_Brewing",
              "value": "4.10498765918783",
              "description": ""
            },
            {
              "id": "PREFIX.7870796.Temperature",
              "label": "Temperature",
              "value": "24.2042508570699",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "PREFIX.7870796.fermentation",
          "description": "fermentation",
          "data": [
            {
              "id": "PREFIX.7870796.Loss_During_Fermentation",
              "label": "Loss_During_Fermentation",
              "quantity": 3.2354851724654683,
              "value": "3.23548517246547",
              "description": "The percentage of volume loss during the fermentation process."
            },
            {
              "id": "PREFIX.7870796.Fermentation_Time",
              "label": "Fermentation_Time",
              "quantity": 16,
              "value": "16",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "PREFIX.7870796.bottling",
          "description": "bottling",
          "data": [
            {
              "id": "PREFIX.7870796.Loss_During_Bottling_Kegging",
              "label": "Loss_During_Bottling_Kegging",
              "quantity": 4.663204448186049,
              "value": "4.66320444818605",
              "description": ""
            }
          ]
        }
      ],
      "materialActual": {
        "id": "PREFIX.7870796.prod",
        "quantity": 4666,
        "properties": [
          {
            "id": "PREFIX.7870796.pH_Level",
            "label": "pH_Level",
            "quantity": 5.2898454476095615,
            "value": "5.28984544760956",
            "description": "The pH level of the beer, indicating its acidity or alkalinity."
          },
          {
            "id": "PREFIX.7870796.Gravity",
            "label": "Gravity",
            "quantity": 1.0395041267301979,
            "value": "1.0395041267302",
            "description": "A measure of the density of the beer as compared to water, indicating the potential alcohol content."
          },
          {
            "id": "PREFIX.7870796.Alcohol_Content",
            "label": "Alcohol_Content",
            "quantity": 5.370842159553436,
            "value": "5.37084215955344",
            "description": "The percentage of alcohol by volume in the beer."
          },
          {
            "id": "PREFIX.7870796.Bitterness",
            "label": "Bitterness",
            "quantity": 20,
            "value": "20",
            "description": "The bitterness of the beer, measured in International Bitterness Units (IBU)."
          },
          {
            "id": "PREFIX.7870796.Color",
            "label": "Color",
            "quantity": 5,
            "value": "5",
            "description": "The color of the beer measured using the Standard Reference Method (SRM)."
          },
          {
            "id": "PREFIX.7870796.Ingredient_Ratio",
            "label": "Ingredient_Ratio",
            "quantity": null,
            "value": "1:0.32:0.16",
            "description": "The ratio ingredients as water : grains: hops."
          },
          {
            "id": "PREFIX.7870796.Quality_Score",
            "label": "Quality_Score",
            "quantity": 8.57701633109399,
            "value": "8.57701633109399",
            "description": "An overall quality score assigned to the beer batch, rated out of 10."
          }
        ]
      }
    },
    {
      "id": "PREFIX.9810411",
      "equipmentActual": [
        {
          "id": "PREFIX.9810411.Whitefield"
        }
      ],
      "children": [
        {
          "id": "PREFIX.9810411.brew",
          "description": "brewing",
          "startDateTime": "2020-01-01T00:00:31",
          "data": [
            {
              "id": "PREFIX.9810411.Loss_During_Brewing",
              "label": "Loss_During_Brewing",
              "value": "2.67652809539211",
              "description": ""
            },
            {
              "id": "PREFIX.9810411.Temperature",
              "label": "Temperature",
              "value": "18.0867629472595",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "PREFIX.9810411.fermentation",
          "description": "fermentation",
          "data": [
            {
              "id": "PREFIX.9810411.Loss_During_Fermentation",
              "label": "Loss_During_Fermentation",
              "quantity": 4.2461292104108574,
              "value": "4.24612921041086",
              "description": "The percentage of volume loss during the fermentation process."
            },
            {
              "id": "PREFIX.9810411.Fermentation_Time",
              "label": "Fermentation_Time",
              "quantity": 13,
              "value": "13",
              "description": "The average temperature (in Celsius) maintained during the brewing process."
            }
          ]
        },
        {
          "id": "PREFIX.9810411.bottling",
          "description": "bottling",
          "data": [
            {
              "id": "PREFIX.9810411.Loss_During_Bottling_Kegging",
              "label": "Loss_During_Bottling_Kegging",
              "quantity": 2.04435836917023,
              "value": "2.04435836917023",
              "description": ""
            }
          ]
        }
      ],
      "materialActual": {
        "id": "PREFIX.9810411.prod",
        "quantity": 832,
        "properties": [
          {
            "id": "PREFIX.9810411.pH_Level",
            "label": "pH_Level",
            "quantity": 5.275643382756193,
            "value": "5.27564338275619",
            "description": "The pH level of the beer, indicating its acidity or alkalinity."
          },
          {
            "id": "PREFIX.9810411.Gravity",
            "label": "Gravity",
            "quantity": 1.0598189516987164,
            "value": "1.05981895169872",
            "description": "A measure of the density of the beer as compared to water, indicating the potential alcohol content."
          },
          {
            "id": "PREFIX.9810411.Alcohol_Content",
            "label": "Alcohol_Content",
            "quantity": 5.096053082797625,
            "value": "5.09605308279763",
            "description": "The percentage of alcohol by volume in the beer."
          },
          {
            "id": "PREFIX.9810411.Bitterness",
            "label": "Bitterness",
            "quantity": 36,
            "value": "36",
            "description": "The bitterness of the beer, measured in International Bitterness Units (IBU)."
          },
          {
            "id": "PREFIX.9810411.Color",
            "label": "Color",
            "quantity": 14,
            "value": "14",
            "description": "The color of the beer measured using the Standard Reference Method (SRM)."
          },
          {
            "id": "PREFIX.9810411.Ingredient_Ratio",
            "label": "Ingredient_Ratio",
            "quantity": null,
            "value": "1:0.39:0.24",
            "description": "The ratio ingredients as water : grains: hops."
          },
          {
            "id": "PREFIX.9810411.Quality_Score",
            "label": "Quality_Score",
            "quantity": 7.420540752553908,
            "value": "7.42054075255391",
            "description": "An overall quality score assigned to the beer batch, rated out of 10."
          }
        ]
      }
    }
  ]
}
```
</details>

## Extensions

An extended version of this model may use material definitions| classes| and lots to categorize the material.
