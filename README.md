# Gothic Plus

A general-purpose mod for Gothic 1 Remake that expands and improves the base game. Rather than
adding one big standalone feature, it bundles a growing collection of quality-of-life and
gameplay tweaks (currently health/mana regeneration, with more — like craftable arrows or full
regen on sleep — planned).

## Installation

1. Install [RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) into your Gothic 1 Remake install,
   if you haven't already. Make sure to use the latest pre-release version.
2. Drop the `GothicPlus` folder into `G1R\Binaries\Win64\ue4ss\Mods\`.
3. Make sure `enabled.txt` is present inside `Mods\GothicPlus\` (it ships with the mod).
4. Launch the game. UE4SS loads the mod automatically.

## Configuration

Settings live in `Mods\GothicPlus\config.ini`. Edit the values, save the file, then restart
the game to apply the changes.

| Setting | Description | Default |
|---|---|---|
| `health_regen_enabled` | Turn health regeneration on or off (`true`/`false`). | `true` |
| `health_per_tick` | Health restored per second. | `1` |
| `mana_regen_enabled` | Turn mana regeneration on or off (`true`/`false`). | `true` |
| `mana_per_tick` | Mana restored per second. | `1` |

Lines starting with `#` are comments. Any setting left out of the file, or set to an invalid
value, falls back to its default.
