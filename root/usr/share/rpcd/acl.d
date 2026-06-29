{
  "luci-app-onlineupdate": {
    "description": "Online Update access",
    "read": {
      "ubus": {
        "system": ["board"]
      }
    },
    "write": {
      "ubus": {
        "onlineupdate": ["*"]
      }
    }
  }
}
