using concurrent
using [java] fanx.interop::Interop
using [java] fanx.interop::ByteArray
using [java] java.nio::ByteBuffer
using [java] purejavahidapi::HidDevice
using [java] purejavahidapi::HidDeviceInfo
using [java] purejavahidapi::PureJavaHidApi
using [java] purejavahidapi::InputReportListener

class GetMask {
	
	Int[]?	controlData
	Int		calibrate
	
	Void main() {
		// list all available HID devices
		Gamepad.listHidDevices.each { echo("$it.vendorId.toHex $it.productId.toHex $it") }

		// choose your controller
		hidDeviceInfo := listHidDevices.find { it.getProductString == "XBOX 360 For Windows (Controller)" }
		hidDevice := PureJavaHidApi.openDevice(hidDeviceInfo)
		hidDevice.setInputReportListener((|HidDevice?, Int, ByteArray?, Int|) #onHidInput.func.bind([this]))

		Actor.sleep(Duration.maxVal)
	}
	
	HidDeviceInfo[] listHidDevices() {
		((HidDeviceInfo[]) Interop.toFan(PureJavaHidApi.enumerateDevices))
	}
	
	Void onHidInput(HidDevice? source, Int id, ByteArray? rawData, Int len) {
		data := Int[,]
		for (i := 0; i < rawData.size; ++i) {
			data.add(rawData[i].and(0xFF))
		}
		
		if (controlData == null) {
			controlData = data
			return
		}
		
		if (controlData.size != data.size) {
			echo("Control Calibration size mis-match: $controlData.size != $data.size")
			return
		}

//		// make sure we get the same control data 10 times
//		if (calibrate < 10) {
//			for (i := 0; i < data.size; ++i) {
//				dat1 := data[i]
//				dat2 := controlData[i]
//				if (dat1 != dat2) {
//					echo("Control Calibration data mis-match @ $i: ${dat1.toHex(2)} != ${dat2.toHex(2)}")
//					controlData = data
//					return					
//				}
//			}
//			calibrate++
//			echo("Calibrating ... $calibrate")
//			if (calibrate == 10) 
//				echo("Device calibrated -> press some buttons!")
//			return
//		}
		
		str1 := " 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14\n"
		str2 := ""
		diffs := Int[,]
		for (i := 0; i < data.size; ++i) {
			dat1 := data[i]
			dat2 := controlData[i]
			
//			if (i != 2 && (i < 8 || i == 12 || i == 13)) {
//			if ( (i < 8) ) {
//				str1 += "-- "
//				str2 += "-- "				
//				continue
//			}
			
			if (dat1 != dat2) {
				diffs.add(i)
				str1 += dat1.toHex(2) + " "
				str2 += dat2.toHex(2) + " "
			} else {
				str1 += "-- "
				str2 += "-- "				
			}
		}

		if (diffs.isEmpty) {
			return
		}
		
		if (diffs.size > 1) {
			echo("Unsupported number of diffs (>1): $diffs")
			echo(str1)
			echo(str2)
			echo
			controlData = data
			return
		}
		
		i := diffs.first
		echo("@ $i :: ${controlData[i].toHex(2)} != ${data[i].toHex(2)}")
		echo(str1)
		echo(str2)
		echo
		controlData = data
	}

	private static Buf toBuf(ByteArray array) {
		// we can't base64 a NioBuf, so copy the contents to a standard Fantom MemBuf
		Buf().writeBuf(Interop.toFan(ByteBuffer.wrap(array))).flip
	}
}
