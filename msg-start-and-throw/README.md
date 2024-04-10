# Demo of a message start and throw


This workflow is triggered from a message on `material/stuff` on the Rhize NATS broker.
You can also publish from an MQTT client and the Rhize agent will bridge the message.

The workflow reads the `quantity` property of the message payload:
- If the quantity is less than `50` or greater than `100`, send a message to `material/alerts`
- Else, create a material actual with this quantity and (optional) the `id` from the message start body.



![image](https://github.com/libremfg/bpmn-templates/assets/47385188/349e70ad-212b-4594-87bb-9f6d1406140f)
