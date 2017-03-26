using concurrent::Actor

class Example {
	Void main() {
		// list all available HID devices
		Gamepad.listHidDevices.each { echo("${it.vendorId.toHex(4)} ${it.productId.toHex(4)} $it") }

		// select any gamepad
		gamepad := Gamepad.listGamepads.first
		if (gamepad == null)
			return echo("No Gamepad detected")
		echo("\nSelected: ${gamepad.prodcutDesc}\n")
		
		// print which buttons are pressed
		gamepad.onInput = |GamepadEvent event| {
			if (event.buttonsDown.size > 0)
				echo(event.buttonsDown)
		}

		Actor.sleep(Duration.maxVal)
	}	
}
