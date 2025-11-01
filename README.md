# eepyXR

A Linux OpenXR overlay to help you sleep in VR, built for runtimes implementing EXTX_overlay

## Building

- Requires the latest dev build of Zig (tested against `0.15.2`)
- Requires the latest dev build of [Beyley/SDL#openxr](https://github.com/Beyley/SDL/tree/openxr) (tested against `f516f2011668f6b8c9deacdaee1287620ca6b8bc`)

```bash
zig build -Doptimize=ReleaseSafe

zig-out/bin/eepyxr
```
