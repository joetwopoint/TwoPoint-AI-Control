# TwoPoint AI Control

Unified AI/world control and police interaction resource for FiveM.

This build combines:

- world AI density / dispatch control
- emergency vehicle and emergency ped cleanup
- siren reaction overrides
- full police pullover / interaction flow
- arrests
- callouts
- tow support
- loadouts

This README is written for the **stable traffic build** and the **fully merged police interaction build**.  
If you are running `TwoPoint_AI_Control_TrafficStable`, this README still applies, with the note that custom handling loading and the extra emergency blocker logic were removed for better behavior on newer FiveM artifacts.

---

## What this resource does

### World / AI control
- Sets configurable vehicle, ped, random vehicle, parked vehicle, and scenario ped density.
- Disables AI dispatch / wanted escalation when enabled in config.
- Suppresses and removes ambient emergency / military-style vehicles and peds.
- Loads `events.meta` to reduce unwanted AI siren-event behavior.

### Police interaction system
Integrated police interaction features include:

- AI pullover initiation
- lock / unlock a target vehicle while behind it
- traffic stop interaction menu
- mimic mode
- follow mode
- questioning driver
- running plate / ID
- tickets / warnings
- ordering driver out
- tow truck
- prisoner transport
- arrests
- callouts
- weapon / radio / misc menu actions
- police loadouts

---

## Resource name

Use this as a single resource:

```cfg
ensure TwoPoint_AI_Control
```

Do **not** also run a separate old PIS resource beside it unless you intentionally want duplicate systems.

---

## Permissions

This build is set up to be **LEO-only** using:

```cfg
group.LEO
```

The resource checks that ace and only allows LEO players to use police interaction keybinds / menus.

Make sure your permission system grants your law enforcement players the `group.LEO` ace.

Example:

```cfg
add_ace group.police "group.LEO" allow
```

If you use Badger Discord Ace Perms or another ace-based system, just make sure your LEO group resolves to `group.LEO`.

---

## Folder structure

Typical merged build structure:

```text
TwoPoint_AI_Control/
  fxmanifest.lua
  config.lua
  client.lua
  server.lua
  events.meta
  handling.meta   (not loaded in the stable traffic build)
  README.md

  police/
    config_police.lua
    pullover/
      pullover.lua
      po_server.lua
    arrest/
      arr_client.lua
      arr_server.lua
    callouts/
      call_client.lua
      call_server.lua
    other/
      warmenu.lua
      menu_client.lua
      loadouts_cl.lua
      loadouts_sv.lua
    addons/
      tow.lua
```

---

## Installation

1. Remove older versions of:
   - `TwoPoint_AI_Control`
   - any older merged police interaction build
   - any separate copy of the old police interaction resource if you no longer want it

2. Drop the new `TwoPoint_AI_Control` folder into your server `resources` folder.

3. Add to `server.cfg`:

```cfg
ensure TwoPoint_AI_Control
```

4. Make sure your LEO permissions grant `group.LEO`.

5. Restart the server.

---

## Main config

### `config.lua`
This controls the AI/world side of the resource.

Common settings:

```lua
Config = {
    VehDensity = 0.8,
    PedDensity = 0.8,
    RanVehDensity = 0.8,
    ParkCarDensity = 0.8,
    ScenePedDensity = 0.4,
    DispatchDead = true
}
```

### `police/config_police.lua`
This controls original police interaction keybinds and settings.

Default keybinds from the police interaction config:

```lua
modifier = 210   -- Left Control
kbpomnu  = 21    -- Left Shift (keyboard pullover key)
ctrpomnu = 22    -- Controller pullover key
trfmnu   = 51    -- E (traffic stop interaction menu)
trfcveh  = 246   -- Y (mimic/follow menu)
mainmnu  = 303   -- U (main interaction menu)
```

Other important settings there include:

```lua
reverseWithPlayer = true
towfadetime = 6
```

---

## Police interaction controls

These are the practical controls players actually use.

### 1. Start AI pullover
**Default:** `Left Shift`  
**Requires:** You are LEO and in an emergency class vehicle with siren behavior matching the police interaction flow.

Behavior:
- Targets the vehicle in front of you.
- If the target is valid and occupied, it initiates the pullover.
- If the target is already stopped, pressing the pullover key again can release it depending on current state.
- If mimic mode is active, the same key can un-mimic first.

### 2. Main police interaction menu
**Default combo:** `Left Control + U`

Opens the main police interaction menu.

Main sections:
- Arrests
- Interactions
- Radio
- Weapons
- Other

### 3. Traffic stop interaction menu
**Default combo:** `Left Control + E`

Requirements:
- a vehicle has already been pulled over
- you are near the stopped driver

This opens the traffic stop menu.

### 4. Mimic / follow / callout follow-up menu
**Default combo:** `Left Control + Y`

Usage depends on state:
- if a stopped vehicle exists, opens the vehicle/interaction follow-up menu
- during some callout states, opens the callout action menu

---

## Main menu breakdown

### Weapons
From the main menu:
- Equip Loadout
- Equip Carbine
- Equip Shotgun

Some weapon options depend on being in a police vehicle.

### Arrests (WIP)
Typical options:
- Handcuff
- Grab
- Kneel
- Unsecure
- Book

### Interactions
Typical options:
- Breathalyze
- Drugalyze
- Search

### Radio
Typical options:
- Run Plate
- Run ID

### Other
Typical options:
- Tow Truck
- Prisoner Transport

---

## Traffic stop system

After successfully pulling a vehicle over:

### Traffic stop menu options
Typical options include:
- Speech mode selection
- Hello
- Ask for Identification
- Question Driver
- Issue Ticket
- Issue Warning
- Order out of vehicle
- order related weapon / compliance commands depending on state

### What the stop system tracks internally
The system can generate / track things like:
- driver name
- date of birth
- registration owner
- registration year
- plate
- insurance / registration / stolen flags
- warrants / offense flags
- citation count
- breath test results
- drug test results
- possible contraband / illegal items

This is why traffic stops can feel more dynamic than just stopping a car.

### Questioning
Questioning is done through the original integrated traffic stop flow after a valid stop is active.

Typical flow:
1. pull a vehicle over
2. walk to the driver
3. open the traffic stop interaction menu with `Ctrl + E`
4. choose identification / questioning / ticketing actions

---

## Mimic and follow

### Mimic
Command / event behavior inside the integrated script allows the stopped vehicle to mimic your driving.

Typical use:
- pull vehicle over first
- use the mimic/follow interaction path
- vehicle mirrors steering and movement
- can be released / un-mimicked

### Follow
Lets the stopped vehicle follow your police vehicle rather than directly mimicking wheel input.

---

## Tow truck

Tow support is integrated.

Access:
- Main menu -> Other -> Tow Truck

This triggers the integrated tow behavior from the police interaction addon.

---

## Prisoner transport

Access:
- Main menu -> Other -> Prisoner Transport

This triggers the prisoner transport flow from the integrated arrest system.

---

## Callouts

The merged build still includes the original callout files.

Available callout functionality depends on the included callout scripts and whatever state those scripts are in for your build.

You can expect:
- callout menu access
- callout action / code 4 menu
- scenario-specific behaviors depending on the original callout files

If your callouts seem incomplete or WIP, that is inherited from the original police interaction content that was merged in.

---

## Loadouts

Integrated loadout scripts are included:

- `police/other/loadouts_cl.lua`
- `police/other/loadouts_sv.lua`

These handle police loadout options used from the menu.

---

## AI cleanup / emergency suppression

The world AI side suppresses and removes many ambient emergency / military-style vehicles and peds.

That helps keep player services as the focus and reduces unwanted vanilla response traffic.

Examples of cleanup targets include:
- ambulance
- fire truck
- police vehicles
- riot / military-style vehicles
- paramedics
- firemen
- cops
- SWAT / marine-style peds

---

## Stable traffic build notes

If you are using the **TrafficStable** build:

### Removed for stability
- custom handling loading from `handling.meta`
- extra emergency blocker logic thread that tried to force AI braking around stopped emergency vehicles

### Kept
- airborne safeguard behavior in the police pullover/mimic logic
- AI density / dispatch control
- emergency vehicle / ped cleanup
- integrated police interaction system

This was done because newer FiveM artifacts changed vehicle/AI behavior enough that the extra handling / blocker logic could make traffic behave unpredictably.

---

## Commands

This build is mostly **keybind/menu driven**, not command driven, for the police interaction side.

### Main resource command
No required chat command is needed for normal police interaction usage.

### Traffic zone commands
Only present in builds where traffic zone support was added.  
If your current build includes those, they are:

```text
/speedzone [radius] [speed]
/speedremove
/securezone [radius]
/secureremove
```

If your current build is the stable no-handling/no-blocker build and you are not using the traffic-zone variant, ignore those.

---

## Recommended usage flow for LEO

1. Enter a police/emergency class vehicle.
2. Activate your lights / normal stop setup.
3. Get behind the AI vehicle.
4. Press `Left Shift` to initiate the pullover.
5. Once stopped, approach the driver.
6. Press `Left Control + E` to open the traffic stop interaction menu.
7. Use:
   - Hello
   - Ask for ID
   - Question Driver
   - Issue Ticket / Warning
   - Order out
8. Use `Left Control + Y` for mimic/follow related actions if needed.
9. Use `Left Control + U` for the main menu / arrest / tow / transport / radio / loadout functions.

---

## Troubleshooting

### Shift does nothing
Check:
- you are actually `group.LEO`
- you are in an emergency class vehicle
- there is a valid occupied vehicle in front of you
- you do not have another resource eating the same keybind

### Traffic stop menu will not open
Check:
- a vehicle is already pulled over
- you are close enough to the driver
- you are still LEO
- the stopped driver still exists

### Traffic acts weird on newer artifacts
Use the stable build that disables:
- `handling.meta` loading
- extra emergency blocker logic

### Handling loader spam
If you see errors like:
- `No such field BrakeForce during SET_VEHICLE_HANDLING_FIELD`
that is usually another resource or loader script, not this merged script directly.

### Menus not showing
Check for conflicts with:
- other WarMenu-based resources
- other police interaction resources
- duplicate old PIS installs still running

---

## Credits / note

This merged script combines:
- TwoPoint AI Control world/AI systems
- integrated police interaction content derived from the original police interaction script

This version has been reorganized and styled for TwoPoint Development use, while preserving the original police interaction behavior as much as possible.

---

## Suggested next improvements

RoadMap:
- configurable keybinds using FiveM key mapping instead of raw control IDs
- on-duty export checks in addition to `group.LEO`
- TwoPoint-themed menu colors / labels everywhere
- logging hooks for traffic stops, arrests, callouts, tow, and transport
- cleanup of older WIP callout sections
