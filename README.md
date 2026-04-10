# eepyXR

A Linux OpenXR overlay to help you sleep in VR, built for runtimes implementing EXTX_overlay

## Building

- Zig 0.15.2
- Requires the latest dev build of SDL3, tested against `57f3d2ea0aada9131c109aaa0dfda41839997ebf`.

```bash
zig build -Doptimize=ReleaseSafe

zig-out/bin/eepyxr
```
