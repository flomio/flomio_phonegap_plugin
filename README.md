# Flomio Cordova Plugin for SDK v2.2

Flomio's plugin for Cordova / Meteor, for use with the v2.2 of the Flomio SDK. [Get yours here.]
(http://flomio.com/shop/apps/flomio-sdk-basic-turnkey-oem-support/)
This plugin is only supported for FloBLE Plus

## Installation

- Download and install [Node](http://nodejs.org/) plus the [Cordova CLI](http://cordova.apache.org/docs/en/4.0.0/guide_cli_index.md.html) or [Meteor CLI](https://www.meteor.com/install).

- Create your Cordova or Meteor example app.

```bash
cordova create flomio-plugin-example-app && cd $_
--
meteor create flomio-plugin-example-app && cd $_
```

- Add the plugin to it.

```bash
cordova plugin add https://github.com/flomio/flomio_cordova_plugin#<latest-commit-code>
--
meteor add cordova:com.flomio.sdk@https://github.com/flomio/flomio_cordova_plugin/tarball/<latest-commit-code>
```

- Register plugin within `config.xml` of your app in Cordova. Meteor takes care of this for you (so skip this step).

```xml
<feature name="FlomioPlugin">
    <param name="ios-package" value="FlomioPlugin" />
</feature>
```

- Implement a simple code snippet to test your setup.

```
function resultCallback(result)
{
	console.log(result);
}
flomioPlugin.selectDeviceType("floble-plus");  
flomioPlugin.init();
```

- Prepare the app.

```bash
cordova prepare
--
meteor add-platform ios
```

- Open the generated Xcode project located at `platforms/ios` or with Meteor, `.meteor/local/cordova-build/platforms/ios`.

- Build and run the app on an iOS device.

## API

**Required for operation**

* `selectDeviceType(deviceType)`

	Activates the specified device type for the current session. Choice of FloJack-BZR, FloJack-MSR, FloBLE-EMV or FloBLE-Plus
	
	`String readerType: <"flojack-bzr", "flojack-msr", "floble-emv" or "floble-plus">`

* `init()`

	Initialises the plugin, preparing it for first use in the current session
	
	
**Optional methods**

* `setConfiguration(configuration)`

	Configures settings for the current session. Both values in `readerSettings` are optional
	
	```
	Object configuration
	{
		int scanPeriod,  // scan period in ms
		bool scanSound  // toggle scan sound on/off
	}

	e.g 
	let configuration = {}
      configuration = {
        scanPeriod: 1000,  // scan period in ms
        scanSound: true,  // toggle scan sound on/off
        readerState: 'read-data', //read-data or read-uuid
        powerOperation: 'auto-polling-control'  //bluetooth-connection-control or auto-polling-control
      }

      flomioPlugin.setConfiguration(configuration);
	```
	
* `getConfiguration(resultCallback)`

	Retrieves settings for the current session
	
	```
	function resultCallback(result)
	Object result
	{
		int scanPeriod,  // scan period in ms
		bool scanSound  // toggle scan sound on/off
	}
	```

* `stopReaders()`

	Stops all readers polling in the current session

* `sleepReaders()`

	Puts all readers in the current session to sleep

* `startReaders()`

	Starts up all readers in the current session that have been stopped or put to sleep

* `sendApdu(resultCallback, deviceId, apdu)`

	Sends an APDU command to a target device

	```
	function resultCallback(result)
	Object result
	{
		String deviceId,
		String responseApdu  // the APDU message received as a response
	}
	```
	`String deviceId`: unique ID code of the target reader (case insensitive, whitespace insensitive)

	`String apdu`: APDU command in hexadecimal format (case insensitive, whitespace insensitive)

* `addConnectedDevicesListener(resultCallback)`

	Assign a callback function to fire when any device connects or disconnects
	
	```
	function resultCallback(result)
	Object result
	{
		String 'Device ID',
		int 'Battery Level',
		int 'Communication Status',
		String 'Firmware Revision',
		String 'Hardware Revision'
	}
	```
	`String 'Device ID'`: unique ID code of the reader which either connected or disconnected

	`int 'Battery Level'`: an int between 0 and 100 (0 == empty, 100 == fully charged)

	`int 'Communication Status'`: 0 == disconnected, 1 == connected but not polling for tags, 2 == connected and polling for tags

	`String 'Firmware Revision'`: firmware version i.e. `'FWV 1.16.03'`

	`String 'Hardware Revision'`: hardware version i.e. `'HWV 1.03'`

* `addTagStatusChangeListener(resultCallback)`

	Assign a callback function to fire when a tag enters or leaves the proximity of any reader
	
	```
	function resultCallback(result)
	Object result
	{
		String deviceId,
		int status  // 0 == out of proximity, 1 == within proximity
	}
	```

* `addTagDiscoveredListener(resultCallback)`

	Assign a callback function to fire when the UID of a tag is found by any reader
	
	```
	function resultCallback(result)
	Object result
	{
		String deviceId,
		String tagUid
	}
	```

* `addNdefListener(resultCallback)`

	Retrieve NDEF formatted data from a tag in proximity of a specified target device.
	Configuration must be "read-data" upon initialization.
	Only supported for FloBLE Plus
	```
	function resultCallback(result)
	Object result
	{
		String deviceId,
		Object payload  //Dictionary with keys 'Uuid', 'Raw Data', 'Ndef'
	}
	
	example usage: 	
		flomioPlugin.addNdefListener(this.didFindTagData)
		
		didFindTagData(dict){
			var returnedData  = dict.payload
			if ('Uuid' in returnedData){
				console.log('Uuid :' + returnedData['Uuid'])
			}
			if ('Raw Data' in returnedData){
				console.log('Raw Data' + returnedData['Raw Data'])
			}
			if (returnedData['Ndef']){
				var ndefMessage = returnedData['Ndef'];
				for (var i = 0; ndefMessage.length > i; i++) {
					var ndefRecord = ndefMessage[i];
					for (var key in ndefRecord){
						console.log(key + ": " + ndefRecord[key])
					}
				}
			}
		}	
	```
