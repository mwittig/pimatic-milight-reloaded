# pimatic-milight-reloaded

A pimtaic plugin to control Milight LED lights and its OEM equivalents such as Rocket LED, Limitless LED Applamp, 
Easybulb, s`luce, iLight, iBulb, and Kreuzer. 


## Configuration

### Plugin Configuration

```json
{
	"plugin" : "milight-reloaded"
}
```

### Device Configuration

```json
{
	"id": "milightzone1",
    "class": "MilightRGBWZone",
    "name": "Milight Zone 1",
    "ip": "192.168.1.xxx",
    "port": 8899,
    "zoneId": 1
}
```
ip: the IP/HOST of the wifi box. Reccommended to set static.<br/>
port: port on the Wifi box. (default 8899, or older: 5000)<br/>
zoneId: 1 - 4 (for the zone)<br/>
