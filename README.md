# 🚀 Star Trek Modules & Entities

A comprehensive **Star Trek-themed addon** for Garry's Mod that brings essential starship systems to life! Experience authentic Star Trek gameplay with interactive ship systems, environmental hazards, and immersive communication features.

![Star Trek](https://img.shields.io/badge/Star%20Trek-Themed-blue)
![Garry's Mod](https://img.shields.io/badge/Garry's%20Mod-Addon-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Table of Contents

- [Features](#-features)
- [Entities](#-entities)
- [Installation](#-installation)
- [Usage](#-usage)
- [Admin Commands](#-admin-commands)
- [Configuration](#-configuration)
- [API & Hooks](#-api--hooks)
- [Requirements](#-requirements)
- [Contributing](#-contributing)
- [Credits](#-credits)
- [License](#-license)

---

## ✨ Features

### 🔧 **Core Systems**
- **Life Support System** - Manage oxygen levels across ship sections
- **Gravity Generator** - Control artificial gravity in different areas
- **Communications Array** - Ship-wide communication with damage effects
- **Systems Disablers** - Section and deck-based system disablers

### 🛠️ **Interactive Tools**
- **Sonic Driver** - Star Trek-themed repair tool for fixing ship systems
- **Visual Health Displays** - Real-time system status monitoring
- **Damage Effects** - Realistic system degradation and failure states

### 💾 **Persistence & Management**
- **Auto-Save System** - Automatically saves entity positions and states
- **Admin Controls** - Full administrative control over all systems
- **Zone-Based Logic** - Smart location detection for system effects

---

## 🎯 Entities

### 🫁 **Life Support System**
- **Entity**: `lifesupport`
- **Function**: Provides breathable atmosphere to ship sections
- **Features**:
  - Configurable damage per tick (1-15 HP)
  - Adjustable damage intervals (1-5 seconds)
  - Visual health bar display
  - Explosive destruction effects
  - Oxygen deprivation damage when offline

### 🌍 **Gravity Generator**
- **Entity**: `gravgen`
- **Function**: Maintains artificial gravity throughout the ship
- **Features**:
  - Reduced gravity (1/6th) and friction (1/8th) when destroyed
  - Health-based performance degradation
  - Visual and audio damage indicators
  - Automatic player gravity management

### 📡 **Communications Array**
- **Entity**: `commsarray`
- **Function**: Enables ship-wide communication systems
- **Features**:
  - Chat message scrambling based on damage level
  - `/comms` command for ship communications
  - Progressive text corruption effects
  - Damage-based interference intensity (0-6 levels)

### 🚫 **Environmental Control Zones**

#### **Life Support Disablers**
- `disablelifesupport_section` - Disables life support for specific ship sections
- `disablelifesupport_deck` - Disables life support for entire decks

#### **Gravity Disablers**
- `disablegravity_section` - Disables gravity for specific ship sections  
- `disablegravity_deck` - Disables gravity for entire decks

**Note**: All disabler entities are admin-only and only visible when using Physics Gun or Tool Gun.

---

## 📦 Installation

1. **Download** the addon files
2. **Extract** to your Garry's Mod addons folder:
   ```
   steamapps/common/GarrysMod/garrysmod/addons/stm_modules_entities/
   ```
3. **Restart** Garry's Mod
4. **Check** that entities appear in the spawn menu under "Star Trek Entities"

### 📋 Required Dependencies
- [Star Trek Modules - Base](https://steamcommunity.com/workshop/filedetails/?id=2711305622) (for Sections System)
- Any **Star Trek ship maps** with deck/section support
- [TBN - Content #3](https://steamcommunity.com/sharedfiles/filedetails/?id=2891353846)
- [ONI - SWEP Base](https://steamcommunity.com/sharedfiles/filedetails/?id=2633296847)
- [Star Trek Tools](https://steamcommunity.com/sharedfiles/filedetails/?id=3473791167)

---

## 🎮 Usage

### 🔧 **Basic Setup**
1. **Spawn entities** as an admin from the "Star Trek Entities" category
2. **Configure settings** using the Entity Editor (C menu)
3. **Position systems** strategically throughout your ship
4. **Use the Sonic Driver** to repair damaged systems

### ⚙️ **Entity Configuration**
All entities support real-time configuration:
- **Health Settings**: Adjust maximum health and current health
- **Model Settings**: Change entity appearance
- **Display Options**: Toggle health bar visibility
- **Damage Settings**: Configure damage amounts and intervals

### 💬 **Communication System**
Use the communications array with the `/comms` command:
```
/comms Hello crew, this is the bridge!
```
Message corruption increases with array damage level.

---

## 👨‍💼 Admin Commands

### 🗃️ **Entity Persistence**
- `star_trek_entities_save` - Save the entity you're looking at
- `star_trek_entities_load` - Reload all saved entities
- `star_trek_entities_remove` - Remove saved data for targeted entity

### 🔧 **Usage**
1. Look at any Star Trek entity
2. Run the appropriate command in console
3. Entities automatically reload after map cleanup

---

## ⚙️ Configuration

### 🛡️ **Safe Zones**
The addon includes predefined safe zones where players won't take environmental damage:
- Turbo Lift areas
- Holodeck zones
- Jefferies Tubes
- Emergency areas

### 🧬 **Damage Immunity**
Players are automatically immune to environmental damage when:
- In **noclip** or **observer** mode
- Wearing **space suit** model (`startrek_female_spacesuit.mdl`)
- In designated **safe zones**

### 📊 **System Limits**
- **Maximum 1** Life Support System per map
- **Maximum 1** Gravity Generator per map
- **Maximum 1** Communications Array per map
- **Unlimited** environmental control zones

---

## 🔗 API & Hooks

### 📡 **Life Support Hooks**
```lua
-- Called when life support is created
hook.Add("OnLifeSupportCreated", "YourFunction", function(ent) end)

-- Called when life support takes damage
hook.Add("OnLifeSupportDamage", "YourFunction", function(ent, dmg) end)

-- Called when life support is destroyed
hook.Add("OnLifeSupportDestroyed", "YourFunction", function(ent) end)

-- Called when life support is repaired
hook.Add("OnLifeSupportRepaired", "YourFunction", function(ent) end)
```
> All hooks will have the first parameter to be the entity itself.
> - On `LifeSupportDamage`, you can access the damage entity and the damage report.

#### 🌌 **Life Support Damage Override**
- `ply` - Player who will receive the damage for life support failure (or not)
- `location` - Location of the player in the ship (considering sections and decks)
```lua
-- Override life support damage
hook.Add("ShouldIgnoreLifeSupportDamage", "YourFunction", function(ply, location) 
    return ignore_damage, override_life_support
end)
```

### 🌍 **Gravity Generator Hooks**
```lua
-- Called when gravity generator is initialized
hook.Add("OnGravGenInitialized", "YourFunction", function(ent) end)

-- Called when gravity generator takes damage  
hook.Add("OnGravGenDamaged", "YourFunction", function(ent, dmg) end)

-- Called when gravity generator is repaired
hook.Add("OnGravGenRepaired", "YourFunction", function(ent) end)
```
> All hooks will have the first parameter to be the entity itself.
> - On `OnGravGenDamaged`, you can access the damage entity and the damage report.

#### 🌌 **Gravity Override**
- `ply` - Player who will receive the gravity effects (or not)
- `location` - Location of the player in the ship (table with the key `section` and `deck`)
```lua
-- Override gravity effects
hook.Add("ShouldIgnoreGravity", "YourFunction", function(ply, location)
    return ignore_gravity, override_gravity
end)
```

### 📡 **Communications Hooks**
```lua
-- Called when communications array is initialized
hook.Add("CommunicationsArrayInitialized", "YourFunction", function(ent) end)

-- Called when communications array takes damage
hook.Add("CommunicationsArrayDamaged", "YourFunction", function(ent, dmg, damage_level) end)

-- Called when communications array is being repaired
hook.Add("CommunicationsArrayRepairing", "YourFunction", function(ent, intensity) end)

-- Called when communications array is removed
hook.Add("CommunicationsArrayRemoved", "YourFunction", function(ent) end)
```
> All hooks will have the first parameter to be the entity itself.
> - On `CommunicationsArrayDamaged`, you can access the damage entity and the damage report and the damage level on a scale of 0-6. [0 = no damage, 6 = critical damage]

### 🌐 **Environmental Control Hooks**
```lua
-- Life support disablers
hook.Add("OnDisableLifeSupportSectionCreated", "YourFunction", function(ent) end)
hook.Add("OnDisableLifeSupportSectionRemoved", "YourFunction", function(ent) end)
hook.Add("OnDisableLifeSupportDeckCreated", "YourFunction", function(ent) end)
hook.Add("OnDisableLifeSupportDeckRemoved", "YourFunction", function(ent) end)

-- Gravity disablers  
hook.Add("OnDisableGravitySectionCreated", "YourFunction", function(ent) end)
hook.Add("OnDisableGravitySectionRemoved", "YourFunction", function(ent) end)
hook.Add("OnDisableGravityDeckCreated", "YourFunction", function(ent) end)
hook.Add("OnDisableGravityDeckRemoved", "YourFunction", function(ent) end)
```

---

## 📋 Requirements

### 🎮 **Core Requirements**
- **Garry's Mod** (latest version)
- [TBN - Content #3](https://steamcommunity.com/sharedfiles/filedetails/?id=2891353846)
- [Star Trek Modules - Base](https://steamcommunity.com/workshop/filedetails/?id=2711305622) (for Sections System)
- [ONI - SWEP Base](https://steamcommunity.com/sharedfiles/filedetails/?id=2633296847)
- [Star Trek Tools](https://steamcommunity.com/sharedfiles/filedetails/?id=3473791167)

### 🗺️ **Recommended**
- All the scripts of the [Star trek Modules](https://steamcommunity.com/sharedfiles/filedetails/?id=2818861994) for more immersive gameplay
- [Star Trek - Intrepid Class](https://steamcommunity.com/sharedfiles/filedetails/?id=2818321513) (or any other ship with deck/section support)

---

## 👏 Credits

### 👨‍💻 **Development Team**
- Void - **Main Developer of the Systems** [Steam Profile](https://steamcommunity.com/id/VoidRoyal/)
- GuuscoNL - **Tools Creator & Developer** [Steam Profile](https://steamcommunity.com/profiles/76561198168362402)
- Oninoni - **SWEP Base Developer & Star Trek TBN Owner** [Steam Profile](https://steamcommunity.com/id/oninoni)

### 🎨 **Assets & Resources**
- **Models**: [Crazy Canadian](https://steamcommunity.com/profiles/76561198445454854)
- **Sounds**: Star Trek audio effects and notifications
- **Inspiration**: Star Trek universe and lore

### 🙏 **Special Thanks**
- Star Trek community for inspiration and feedback
- Star Trek TBN Network join the [Star Trek TBN Discord](https://discord.gg/HAXKzkwKpm)
- Garry's Mod modding community for tools and resources
- Beta testers and server operators

---

## 📄 License

This project is licensed under the **MIT License** - see the individual file headers for details.

```
Copyright (c) 2024 Void and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/henriquecgarcia/stm_modules_entities/issues)
- **Documentation**: This README and inline code comments
- **Community**: Star Trek Garry's Mod communities

---

**🖖 Live Long and Prosper!** 

*May your ship systems never fail and your repairs be swift.*

---

### 📊 Version Info
- **Current Version**: 1.0
- **Compatible GMod**: 2024+
- **Last Updated**: 2025
- **Addon Category**: Star Trek / Roleplay / Entities
