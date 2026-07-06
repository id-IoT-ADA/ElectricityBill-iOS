# ⚡ Savergy

> An intelligent home energy monitoring application that helps people living abroad track electricity usage, estimate electricity costs, and prevent unexpected power outages caused by exceeding their electrical capacity.

## Table of Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [How It Works](#how-it-works)
- [System Architecture](#system-architecture)
- [Installation](#installation)
- [Future Improvements](#future-improvements)
- [License](#license)

---

## Overview

Savergy is an iOS application designed to monitor household electricity consumption at both the device and household levels. By integrating smart IoT hardware with Apple's ecosystem, Savergy provides real-time insights into energy usage, electricity spending, and proactive blackout prevention.

The application is designed for people living abroad, renters, and individuals living in apartments or boarding houses where electrical capacity is limited and circuit breakers can easily trip when multiple high-power appliances are used simultaneously.

---

## Motivation

Unexpected blackouts are a common issue in apartments and boarding houses with limited electrical capacity. Since residents often do not know how much electricity each appliance consumes, they may unknowingly exceed the circuit breaker limit by operating multiple devices at once.

Savergy helps users better understand their electricity usage by providing real-time monitoring, estimated electricity costs, and timely alerts before the electrical limit is reached, allowing them to take preventive action.

---

## Features

### ⚠️ Blackout Prevention Alerts

- Receive notifications when electricity usage approaches the circuit breaker limit.
- Prevent unexpected power outages before they occur.

### 🔌 Device-Level Energy Monitoring

- Monitor real-time electricity usage for each connected appliance.
- View individual device consumption in kilowatt-hours (kWh).

### ⚡ Household Energy Monitoring

- Track the total electricity consumption across all connected devices.
- Understand overall household energy usage at a glance.

### 💰 Electricity Spending Estimation

- Estimate electricity costs based on accumulated kWh usage.
- Monitor spending in real time to better manage monthly electricity expenses.

---

## Technology Stack

### Mobile Application

- SwiftUI
- HomeKit
- FoundationModels
- EnergyKit
- Foundation

### IoT Hardware

- ESP32
- HomeSpan
- INA219

### Development Environment

- Xcode
- Arduino IDE

---

## How It Works

1. Smart plugs powered by **ESP32** measure the energy consumption of connected appliances.
2. **HomeSpan** enables the ESP32 devices to communicate with **Apple HomeKit**.
3. The Savergy iOS application retrieves electricity usage data from HomeKit.
4. The application aggregates device-level consumption into household-level statistics.
5. Electricity spending is estimated based on accumulated energy usage.
6. When the total electrical load approaches the configured circuit breaker limit, Savergy sends a blackout warning notification.

---

## System Architecture

```text
           Appliances
                │
                ▼
     ESP32 + HomeSpan Smart Plug
                │
                ▼
          Apple HomeKit
                │
                ▼
       Savergy iOS Application
                │
      ┌─────────┼──────────┐
      │         │          │
      ▼         ▼          ▼
 Device     Household   Spending
Monitoring  Monitoring  Estimation
                │
                ▼
        Blackout Alerts
```

---

## Installation

> **Note:** Installation instructions will be updated as the project setup is finalized.

1. Clone the repository.

```bash
git clone https://github.com/yourusername/savergy.git
```

2. Open the project using Xcode.

3. Configure the required Apple Developer capabilities.

4. Pair the ESP32 smart plug with Apple HomeKit.

5. Build and run the application on an iPhone.

---

## Future Improvements

- Historical energy consumption analytics
- AI-powered energy-saving recommendations using Foundation Models
- Smart appliance scheduling
- Carbon footprint estimation
- Multi-home support
- Shared household monitoring for families and roommates

---

## License

This project is currently intended for academic and research purposes.

Update this section if an open-source license (such as MIT or Apache 2.0) is adopted.
