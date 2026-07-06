## 1. Present your team
- Karen Regina Susanto
- Najwa Iqna Auliya
- Julius Diky Ardianto
- Ikhwan Inzaghi
- ⁠⁠Clarisa Michelle Eugenia

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
In the documentation, there is no explicit explanation that in order to have a long range control over the smart devices we need a HomeHub. We did not find alteratives solution to this. Therefore, we lend Apple HomePod to simulate the device control. 

## 6. The Revised Decision
Final decision: HomeKit (Main Framework), EnergyKit, FoundationModel, CoreBluetooth

From thinking we would use Network, it changed into those 4 frameworks because through exploration we found that HomeKit supports DIY accessory. We also added EnergyKit because it supports the feature we want in our app which is to track and give insights on energy usage per device. We added FoundationModel to generate weekly insight on user's electricity consumption. Lastly, CoreBluetooth is needed in order to send local wifi credentials to ESP32.


## About the Frameworks
Our app can still run even without the EnergyKit Framework since the purpose of EnergyKit is to give insight regarding electricity usage. The data of the energy usage that is generated from INA219 can be calculated by adding function to calculate it. However, with the implementation of EnergyKit it would be much easier. On the other hand, FoundationModel inside the app is very much needed to help generate recommendation and such towards the duration of usage and energy consumption itself. Then, the use of CoreBluetooth is important in this app because it will help our ESP32 to connect to the local wifi.

## About Accessibility and Localization
- Accessibility: Larger Text

at first, this application main target is for young people who lived abroad. but then, throughout the building process we found that this app may serves a larger audience with a higher range of age. By applying larger text, it would help people in the higher range of the age spectrum since they may have a limited vision.
- Localization: Bahasa Indonesia

Building this app with the "anak rantau" in mind, we choose to implement bahasa indonesia as part of the localization. Our first target would be indonesian since this app is currently build in Indonesia.

## About Privacy
The data needed in the application is primarily from the Home App. Once you have downloaded the app it will ask permission to the Home data. Declining the permission request would make the app to stand on its own and no integration will be made to the home app that is available to your phone. 
