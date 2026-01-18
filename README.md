# EcoDrive

<p align="center">
   <img src="./assets/icon/icon.svg" width="150"/>
</p>

EcoDrive is an experimental Flutter application that uses **on-device sensors and GPS** to analyze driving behavior and visualize estimated emissions and efficiency directly on a map.

The goal of the project is to explore how far you can go with **phone-only telemetry** (accelerometer, gyroscope, and GPS) to approximate vehicle dynamics such as acceleration, braking, and driving smoothness — without requiring access to the vehicle CAN bus.

## ✨ Features

* 🚗 **Trip recording** (start / stop drives)
* 🗺️ **Map-based trip visualization** using OpenStreetMap (via `flutter_map`)
* 📍 **GPS tracking** with polyline replay of trips
* 📊 **Real-time telemetry**

  * Speed
  * Longitudinal acceleration
  * Estimated emission intensity
* 🎨 **Color-coded route segments** based on emission intensity
* 💾 **Local trip storage** (JSON files on device)
* 🔁 **Trip replay mode**

<p align="center">
   <img src="https://github.com/user-attachments/assets/916952ab-8b1b-42b7-8732-432d0dfa6d1d" width="200">
   <img src="https://github.com/user-attachments/assets/44889f55-4581-47aa-86c6-dcbfddaad678" width="200">
   <img src="https://github.com/user-attachments/assets/bf301549-8149-4953-8ee2-1b0fe72cfb69" width="200">
</p>

## 🧠 Sensor Fusion Overview

EcoDrive combines multiple phone sensors to produce a more accurate, vehicle-aligned estimate of motion:

| Sensor             | Purpose                                               |
| ------------------ | ----------------------------------------------------- |
| Accelerometer      | Determines gravity vector → phone tilt (pitch / roll) |
| User Accelerometer | Linear acceleration (gravity removed)                 |
| Gyroscope          | Tracks short-term rotation (yaw) during turns         |
| GPS                | Provides absolute heading, speed, and position        |

### Fusion pipeline

```
User Acceleration
   ↓
Rotate by gravity vector (tilt compensation)
   ↓
Rotate by gyroscope yaw (vehicle turns)
   ↓
Correct yaw drift using GPS heading
   ↓
Vehicle-aligned longitudinal acceleration
```

This layered approach reduces errors caused by:

* Phone mounting angle
* Vehicle turns
* Gyroscope drift over long trips

## 🗺️ Map & Visualization

* Uses Carto basemap tiles (`basemaps.cartocdn.com`) for a clean, modern map style

  * Light and dark themed basemaps are supported
  * Built on top of OpenStreetMap data
* Rendered via flutter_map (non-commercial usage)
* Route segments are colored based on estimated emission intensity:

  * 🟢 Low
  * 🟡 Medium
  * 🟠 High
  * 🔴 Very High
* Start and end points are highlighted in trip replay mode

## ⚠️ Limitations & Disclaimer

* This app does **not** read real vehicle fuel or emission data
* Emission values are **heuristic estimates**, intended for visualization and experimentation only
* Accuracy depends on:

  * Phone mounting position
  * Sensor quality
  * GPS signal quality

This project should be treated as an **educational / experimental tool**, not a scientific instrument.

## 📜 License

EcoDrive is open-source software released under the [MIT License](https://opensource.org/licenses/MIT). You are free to modify and distribute the application under the terms of this license. See the [`LICENSE`](./LICENSE) file for more information.

Please note that this README file is subject to change as the application evolves. Refer to the latest version of this file in the repository for the most up-to-date information.
