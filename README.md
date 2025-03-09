# eepyXR

A Linux OpenXR overlay to help you sleep in VR, built for runtimes implementing EXTX_overlay

## Building

- Requires the latest dev build of Zig (tested against `0.15.0-dev.23+1eb729b9b`)
- Requires the latest dev build of [Beyley/SDL#openxr](https://github.com/Beyley/SDL/tree/openxr) (tested against `d64e41f95ea641a32da18e526d57013966a96b41`)

```bash
zig build -Doptimize=ReleaseSafe

zig-out/bin/eepyxr
```
