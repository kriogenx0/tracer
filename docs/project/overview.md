## Overview

Tracer is a macOS Audio Unit (AUv3) that detects pitch and turns it into MIDI notes, with a SwiftUI host app that loads the extension. The DSP is C++ (YIN pitch detection and a note state machine) and the AU, parameters and UI are Swift. Building needs macOS 14+ and full Xcode.

### Commands

- `make setup`: install XcodeGen if missing and generate `Tracer.xcodeproj` from `project.yml`.
- `make dev`: regenerate, delete the previous Debug build, build into `build/Debug`, and open `Tracer.app`.
- `make build`: Release build into `build/Release`.
- `make install` / `make uninstall` / `make reinstall`: install the Release app into `~/Applications`.
- `make clean`: remove `build/`.
- `make rules` / `make rules-check`: sync or check the shared rules in `docs/rules/`.

There is no test target yet. Check changes with `make dev` by loading the AU in the host app (or a DAW).

### Layout

- `TracerExtension/DSP/`: realtime pitch detection (`YinPitchDetector`), note tracking (`NoteStateMachine`), MIDI helpers, and the DSP kernel.
- `TracerExtension/Parameters/`: parameter addresses and the Swift parameter tree.
- `TracerExtension/UI/`: the plugin's SwiftUI views.
- `TracerExtension/Common/`: AU plumbing (audio unit, buffered bus, view controller, parameter UI helpers).
- `TracerApp/`: the standalone host, with an audio engine harness and a virtual MIDI output.
- `project.yml`: source of truth for targets and build settings. The `.xcodeproj` is generated from it.
