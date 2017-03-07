using concurrent

class Example {
	Void main() {
		// list all available HID devices
		Gamepad.listHidDevices.each { echo("$it.vendorId.toHex $it.productId.toHex $it") }

		// choose your controller
		gamepad := Gamepad.listHidDevices.find { it.prodcutDesc == "GAMEPAD 3 TURBO" }
		
		// print which buttons are pressed
		gamepad.onInput = |GamepadEvent event| {
			if (event.buttonsDown.size > 0)
				echo(event.buttonsDown)
		}
		Actor.sleep(Duration.maxVal)
	}	
}

