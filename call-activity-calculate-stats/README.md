# Use a call activity to create aggregate statistics

This example has two workflows, a parent and child:
The parent, `MSG_conditionalOnStats.bpmn` uses a call activity to call the child `FUNC_calculateStats.bpmn`.

To run it:
1. Import both BPMN files. Ensure they are active.
1. Enable the `MSG` workflow so that it actively listens to that topic.
1. Use an MQTT client to send a message the `stats` topic on your Rhize broker, with a payload in this structure:
   ```json
   {
     "data":{
        "arr": [1,2,3]
        }
    }
    ```
1. Look for the output that Rhize returns on `stats/calculations`.

Alternatively, you can trigger it from the API. To inspect the values, change the `stats` variable to `customResponse`.
For details, read [Trigger workflows](https://docs.rhize.com/how-to/bpmn/trigger-workflow/).

## How it works

![Diagram showing a call activity](https://raw.githubusercontent.com/libremfg/rhize-docs/main/static/images/bpmn/diagram-rhize-bpmn-call-activity.png)

The function expects an array of numbers called `arr`.
The main workflow extracts this array from a `data` object that it receives in the payload of a message or API call.

After the function returns the calculated values, the main workflow stores the result in a new variable, `stats`, and sends this variable to `stats/calculated` on the Rhize broker.
If `stats.mode` exceeds `200`, it also includes an alert property in the payload.

## Example JSOnata

The calculate function uses the following JSONata expression.

```
(
  $sorted := $sort($.arr);
  $length := $count($.arr);
  $mid := $floor($length/2);
  $length % 2 = 0
    ? $median := ($sorted[$mid-1] + $sorted[$mid]) /2
    : $median := $sorted[$mid];


{
    "sum":$sum($.arr),
    "mode": $max($.arr),
    "mean": $average($.arr),
    "median": $median
}

)
```
