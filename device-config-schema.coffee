module.exports = {
  title: "pimatic-chronotherm device config schemas"
  ChronoThermDevice: {
    title: "ChronoThermDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      interface:
        description: "User interface"
        type: "number"
        default: 0
        required: false
      showseason:
        description: "Show the season interface"
        type: "boolean"
        default: false
        required: false
      cas1Ref:
        description: "Variable to insert value"
        type: "string"
      cas2Ref:
        description: "Variable to insert value"
        type: "string"
      cas3Ref:
        description: "Variable to insert value"
        type: "string"
      cas4Ref:
        description: "Variable to insert value"
        type: "string"
      cas5Ref:
        description: "Variable to insert value"
        type: "string"
      cas6Ref:
        description: "Variable to insert value"
        type: "string"
      cas7Ref:
        description: "Variable to insert value"
        type: "string"
      sum1Ref:
        description: "Variable to insert value"
        type: "string"
      sum2Ref:
        description: "Variable to insert value"
        type: "string"
      sum3Ref:
        description: "Variable to insert value"
        type: "string"
      sum4Ref:
        description: "Variable to insert value"
        type: "string"
      sum5Ref:
        description: "Variable to insert value"
        type: "string"
      sum6Ref:
        description: "Variable to insert value"
        type: "string"
      sum7Ref:
        description: "Variable to insert value"
        type: "string"
      realtemperature:
        description: "variable with the real temperature"
        type: "string"
      boost:
        description: "boost mode"
        type: "boolean"
        required: false
      interval:
        description: "time in seconds to refresh the schedule"
        type: "number"
      offtemperature:
        description: "the temperature for the off button"
        type: "number"
      ontemperature:
        description: "the temperature for the on button"
        type: "number"
  }
}
