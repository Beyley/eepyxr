# eepyXR

A Linux OpenXR overlay to help you sleep in VR, built for runtimes implementing EXTX_overlay

- [x] Dim the user's screen
- [x] Configuration file
- [ ] System tray for closing app
- [ ] Automatically enable when the user is detected sleep
- [ ] Automatically disable when the user is detected awake
- [ ] Custom dim overlay
- [ ] OSC message on enable/disable, and to enable/disable

## Building

- Requires the latest dev build of Zig (tested against `0.14.0-dev.3062+ff551374a`)
- Requires the latest dev build of [Beyley/SDL#openxr](https://github.com/Beyley/SDL/tree/openxr) (tested against `d64e41f95ea641a32da18e526d57013966a96b41`)

```bash
zig build -Doptimize=ReleaseSafe
```
