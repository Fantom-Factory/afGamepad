#Gamepad v0.0.2
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom-lang.org/)
[![pod: v0.0.2](http://img.shields.io/badge/pod-v0.0.2-yellow.svg)](http://www.fantomfactory.org/pods/afGamepad)
![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)

## Overview

*Gamepad is a support library that aids Alien-Factory in the development of other libraries, frameworks and applications. Though you are welcome to use it, you may find features are missing and the documentation incomplete.*

The Gamepad library lets you receive input data and events from USB connected gamepads.

Those who play XBox or Playstation are aware that the controllers are USB connected, but did you know you they also work on laptops and PCs!?

Well, they do!

Gamepad controllers are Human Input Devices (HID) over USB. This library wraps the [Pure Java HID-API](https://github.com/nyholku/purejavahidapi) library to provide gamepad support in Fantom.

## Install

Install `Gamepad` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afGamepad

Or install `Gamepad` with [fanr](http://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afGamepad

To use in a [Fantom](http://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afGamepad 0.0"]

## Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afGamepad/) - the Fantom Pod Repository.

## Quick Start

1. Create a text file called `Example.fan`

        using concurrent
        
        class Example {
            Void main() {
                // list all available HID devices
                Gamepad.listAllHidDevices.each { echo(it) }
        
                // choose your controller
                gamepad := Gamepad.listAllHidDevices.find { it.prodcutDesc == "GAMEPAD 3 TURBO" }
        
                // print which buttons are pressed
                gamepad.onInput = |GamepadEvent event| {
                    if (event.buttonsDown.size > 0)
                        echo(event.buttonsDown)
                }
                Actor.sleep(Duration.maxVal)
            }
        }


2. Run `Example.fan` as a Fantom script from the command line:

        C:\> fan Example.fan
        
        USB Keyboard
        GAMEPAD 3 TURBO
        Razer Orochi
        [start]
        [select]
        [rightTrigger]
        [leftShoulder]
        [rightShoulder]
        [dpadLeft]
        [dpadRight]



## Gamepad

The standard controller button layout is as follows:

![Generic Controller Layout](http://eggbox.fantomfactory.org/pods/afGamepad/doc/gamepad.png)

Only the following controllers are currently supported out of the box:

```
table:

Vendor ID  Product ID  Product Description
---------  ----------  -------------------
 0xE8F      0x310D      GAMEPAD 3 TURBO
```

If your controller is not listed, get in touch and we'll work to add it.

## Dependencies

Gamepad comes bundled with the following jars:

- `jna-4.2.1.jar`
- `purejavahidapi-0.0.10.jar`

Later versions of `Gamepad` may brake the .jars out into their own pods, but for now they're exploded into `afGamepad.pod`.

Note that due to how `purejavahidapi` is compiled, Gamepad is only compatible with JDK 8 or later.

## Compatibility

Note that the following controllers do not register as USB HID devices and hence are not compatible with the Gamepad library:

- Official XBox One Wireless Controller

## TODO

- Add built-in support for more controllers
- Create controller mapping contributions
- Create a Javascript implementation. Oh yes! Did you not know of the [W3C Gamepad Specification](https://w3c.github.io/gamepad/)!?

