using [java] fanx.interop::Interop
using [java] fanx.interop::ByteArray
using [java] purejavahidapi::HidDevice
using [java] purejavahidapi::HidDeviceInfo
using [java] purejavahidapi::PureJavaHidApi
using [java] purejavahidapi::InputReportListener

** Represents a Gamepad controller.
** Use [listHidDevices()]`listHidDevices` to obtain an instance.
class Gamepad {
	private static const Log log := Gamepad#.pod.log

	** The 16 bit vendor ID.
	const Int	vendorId
	
	** The 16 bit product ID.
	const Int	productId

	** Name of the manufacturer.
	const Str?	manufacturer
	
	** Product description. 
	const Str?	prodcutDesc
	
	** A platform dependent path that describes the 'physical' path through hubs and ports to the device.
	const Str 	path
	
	** A number between 0 - 1, over which a button value is considered to be pressed.
	** Used to created 'buttonUp' and 'buttonDown' event data.
	Float		buttonThreshold		:= 0.6f
	
	** Listener that's called when the Gamepad input changes.
	|GamepadEvent|?	onInput {
		set {
			if (it == null) close; else if (&onInput == null) open
			&onInput = it
		}
	}
	
	** Listener that's called when the Gamepad is disconnected / unplugged.
	|Gamepad|?	onDisconnect

	private HidDevice?		hidDevice
	private HidDeviceInfo	hidDeviceInfo
	private Enum:Float		oldValues	:= Enum:Float[:]
	
	private new make(HidDeviceInfo hidDeviceInfo) {
		this.hidDeviceInfo	= hidDeviceInfo
		this.vendorId		= hidDeviceInfo.getVendorId
		this.productId		= hidDeviceInfo.getProductId
		this.manufacturer	= hidDeviceInfo.getManufacturerString
		this.prodcutDesc	= hidDeviceInfo.getProductString
		this.path			= hidDeviceInfo.getPath
	}
	
	** Lists all USB-HID devices. Some may be Gamepad controllers, some may not be.
	static Gamepad[] listHidDevices() {
		((HidDeviceInfo[]) Interop.toFan(PureJavaHidApi.enumerateDevices)).map { Gamepad(it) }
	}

	** Lists all supported Gamepad controllers.
	static Gamepad[] listGamepads() {
		listHidDevices.findAll {
			(it.vendorId == 0x045E && it.productId == 0x028E) ||
			(it.vendorId == 0x0E8F && it.productId == 0x310D)
		}
	}
	
	private Void open() {
		hidDevice = PureJavaHidApi.openDevice(hidDeviceInfo)
		hidDevice.setInputReportListener	((|HidDevice?, Int, ByteArray?, Int|) #onHidInput.func.bind([this]))
		hidDevice.setDeviceRemovalListener	((|HidDevice?|) #onHidRemove.func.bind([this]))
	}
	
	private Void close() {
		try {
			hidDevice?.setInputReportListener(null)
			hidDevice?.setDeviceRemovalListener(null)
			hidDevice?.close
		} catch {
		} finally {
			hidDevice = null			
		}
	}
	
	private Void onHidRemove(HidDevice? source) {
		close
		onDisconnect?.call(this)
	}

	private Void onHidInput(HidDevice? source, Int id, ByteArray? data, Int len) {

		// for multi controller support, this could be converted to a generic structure, configured by pod Index:
		// 
		//   faceDown = ["byte":13, "mask":0xFF, "type":"val"]
		// Controller Mapping

		// or we could try to find a way to get and decode the HID Descriptor
		// or we could try to find a java native gamepad api

		rawValues := null as Enum:Float
		if (source.getHidDeviceInfo.getVendorId == 0x045E && source.getHidDeviceInfo.getProductId == 0x028E)
			rawValues = decodeXbox360Windows(data)
		if (source.getHidDeviceInfo.getVendorId == 0x0E8F && source.getHidDeviceInfo.getProductId == 0x310D)
			rawValues = decodeGamepad3Turbo(data)

		if (rawValues == null)
			log.warn("Gamepad not supported: 0x${source.getHidDeviceInfo.getVendorId.toHex(4)} 0x${source.getHidDeviceInfo.getProductId.toHex(4)} ${source.getHidDeviceInfo.getProductString}")
		
		changed		:= false
		buttonsUp	:= GamepadButton#.emptyList
		buttonsDown	:= GamepadButton#.emptyList

		rawValues.each |val, button| {
			if (val != oldValues[button]) {
				changed = true
				if (button is GamepadButton) {
					oldState := oldValues[button] > buttonThreshold
					newState := val > buttonThreshold
					if (oldState.xor(newState)) {
						if (newState) {
							buttonsDown = buttonsDown.rw
							buttonsDown.add(button)
						} else {
							buttonsUp = buttonsUp.rw
							buttonsUp.add(button)
						}
					}
				}
			}
		}
		
		oldValues = rawValues
		if (changed) {
			event := GamepadEvent {
				it.gamepad = this
				it.axesValues	= rawValues.findAll |val, key| { key is GamepadAxis }
				it.buttonValues	= rawValues.findAll |val, key| { key is GamepadButton }
				it.buttonsUp	= buttonsUp
				it.buttonsDown	= buttonsDown
			}

			try	onInput?.call(event)
			catch (Err err)
				err.trace
		}
	}
	
	private Enum:Float decodeXbox360Windows(ByteArray? data) {
		rawValues	:= Enum:Float[:]

		// this is a good site, but appears to be wrong!?
		// http://free60.org/wiki/GamePad
		
		rawValues[GamepadButton.faceDown]		= data[10].and(0x01) > 0 ? 1f : 0f
		rawValues[GamepadButton.faceLeft]		= data[10].and(0x04) > 0 ? 1f : 0f
		rawValues[GamepadButton.faceRight]		= data[10].and(0x02) > 0 ? 1f : 0f
		rawValues[GamepadButton.faceUp]			= data[10].and(0x08) > 0 ? 1f : 0f

		rawValues[GamepadButton.leftShoulder]	= data[10].and(0x10) > 0 ? 1f : 0f
		rawValues[GamepadButton.rightShoulder]	= data[10].and(0x20) > 0 ? 1f : 0f
		rawValues[GamepadButton.leftTrigger]	= (data[ 9].and(0xFF) - 0x80).max(0) / 0x80.toFloat			// 80-FF = left
		rawValues[GamepadButton.rightTrigger]	= (data[ 9].and(0xFF) - 0x80).negate.max(0) / 0x80.toFloat	// 00-80 = right

		rawValues[GamepadButton.select]			= data[10].and(0x40) > 0 ? 1f : 0f
		rawValues[GamepadButton.start]			= data[10].and(0x80) > 0 ? 1f : 0f
		rawValues[GamepadButton.logo]			= 0f	// ???
		
		rawValues[GamepadButton.leftAnalogue]	= data[11].and(0x01) > 0 ? 1f : 0f
		rawValues[GamepadButton.rightAnalogue]	= data[11].and(0x02) > 0 ? 1f : 0f
		
		dpad	:= data[11].and(0x04) > 0
		dpadVal := data[11].and(0x18).shiftr(3)
		rawValues[GamepadButton.dpadUp]			= dpad && dpadVal == 0x00 ? 1f : 0f
		rawValues[GamepadButton.dpadLeft]		= dpad && dpadVal == 0x03 ? 1f : 0f
		rawValues[GamepadButton.dpadRight]		= dpad && dpadVal == 0x01 ? 1f : 0f
		rawValues[GamepadButton.dpadDown]		= dpad && dpadVal == 0x02 ? 1f : 0f

		rawValues[GamepadAxis.leftX]			= (data[1].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.leftY]			= (data[3].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.rightX]			= (data[5].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.rightY]			= (data[7].and(0xFF) - 0x80) / 0x80.toFloat

		return rawValues
	}
	
	private Enum:Float decodeGamepad3Turbo(ByteArray? data) {
		rawValues	:= Enum:Float[:]

		rawValues[GamepadButton.faceDown]		= data[13].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.faceLeft]		= data[14].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.faceRight]		= data[12].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.faceUp]			= data[11].and(0xFF) / 0xFF.toFloat

		rawValues[GamepadButton.leftShoulder]	= data[15].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.rightShoulder]	= data[16].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.leftTrigger]	= data[17].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.rightTrigger]	= data[18].and(0xFF) / 0xFF.toFloat

		rawValues[GamepadButton.select]			= data[ 1].and(0x01) > 0 ? 1f : 0f
		rawValues[GamepadButton.start]			= data[ 1].and(0x02) > 0 ? 1f : 0f
		rawValues[GamepadButton.logo]			= data[ 1].and(0x10) > 0 ? 1f : 0f
		
		rawValues[GamepadButton.leftAnalogue]	= data[ 1].and(0x04) > 0 ? 1f : 0f
		rawValues[GamepadButton.rightAnalogue]	= data[ 1].and(0x08) > 0 ? 1f : 0f
		
		rawValues[GamepadButton.dpadUp]			= data[ 9].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.dpadLeft]		= data[ 8].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.dpadRight]		= data[ 7].and(0xFF) / 0xFF.toFloat
		rawValues[GamepadButton.dpadDown]		= data[10].and(0xFF) / 0xFF.toFloat

		rawValues[GamepadAxis.leftX]			= (data[3].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.leftY]			= (data[4].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.rightX]			= (data[5].and(0xFF) - 0x80) / 0x80.toFloat
		rawValues[GamepadAxis.rightY]			= (data[6].and(0xFF) - 0x80) / 0x80.toFloat

		return rawValues
	}

	@NoDoc
	override Str toStr() { prodcutDesc }
}

** Fired when the Gamepad input values change.
class GamepadEvent {
	** The owning Gamepad instance.
	Gamepad				gamepad
	
	** Thumbstick values that have been normalised between -1 and 1.
	** 
	** -1 means fully left / up. 1 means fully right / down. 
	GamepadAxis:Float	axesValues

	** Analogue button values that have been normalised between 0 and 1.
	** 
	** 0 means not pressed, 1 means fully pressed.  
	GamepadButton:Float	buttonValues
	
	** A list of buttons whose analogue values are less than the Gamepad 'buttonThreshold'.
	GamepadButton[]		buttonsUp

	** A list of buttons whose analogue values are more than the Gamepad 'buttonThreshold'.
	GamepadButton[]		buttonsDown
	
	@NoDoc
	new make(|This| f) { f(this) }
}


