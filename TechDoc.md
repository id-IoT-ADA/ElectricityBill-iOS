## 1. Present your team
- Karen Regina Susanto
- Najwa Iqna Auliya
- Julius Diky Ardianto
- Ikhwan Inzaghi
- 

## 2. Starting Assumption
We thought we would end up using Network because considering we wanted to make our own device, we thought Network was the obvious framework to connect our DIY devices with our app.

## 3. The Exploration Log
We explored every single framework that were suggested (HomeKit, Matter, Core Bluetooth, Network, Multipeer Connectivity), each of us explored one. Here's what we found:
- HomeKit: for Apple smart home system.
- Matter: Helps smart devices from different brands and ecosystems to communicate easily  (Apple, Android, Amazon, etc).
- Core Bluetooth: connect our device to bluetooth, low energy 
- Network: Enables communication with devices and servers over local networks or the Internet. Use when we want direct access to protocols like TLS, TCP, and UDP for your custom application protocols.
- Multipeer Connectivity: framework to communicate between 2 iOS devices. Its purpose is to send and receive data between multiple devices using their networking hardware, such as Bluetooth and Wi-Fi, without using an internet connection

During that exploration we also discovered EnergyKit framework, that can give insights regarding energy usage, and control charging only when the energy comes from cleaner energy source. But this framework is quite new and some of its features are still in beta version.
We tried out HomeKit in code to see how it works and how it can be connected with the native Home app. However, we thought HomeKit only works with Apple's smart devices (since it's connected to the native Home app) so we were leaning towards using Matter and Network framework, but what surprised us was that we can make our own HomeKit accessory, using ESP32 and HomeSpan, and it will be able to work with the HomeKit framework.

## 4. What We Tried and Dropped
First, we tried using firebase when working on controlling smart devices remotely, because it stored data in cloud, but we dropped it when we revert back from Matter or Network framework to using HomeKit because HomeKit already uses iCloud to store and retrieve data. 
Secondly, when we realized that we can't control smart devices remotely using HomeKit without a hub at home, we tried implementing MQTT. Then we dropped it when we realized that implementing MQTT doesn't solve that problem, because we still don't have a device (hub) at home that can recieve commands from our phone via cloud (many smart devices (such as door locks or contact sensors) use localized, energy-saving wireless protocols like Bluetooth, Zigbee, or Z-Wave rather than Wi-Fi).


## 5. Real Limitations Hit


## 6. The Revised Decision
Final decision: HomeKit, EnergyKit, FoundationModel
From thinking we would use Network, it changed into those 3 frameworks because through exploration we found that HomeKit supports DIY accessory. We also added EnergyKit because it supports the feature we want in our app which is to track and give insights on energy usage per device. Lastly, we added FoundationModel for accessibility, to create a voice command feature.


## About the Frameworks


## About Accessibility and Localization


## About Privacy
