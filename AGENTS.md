# AGENTS.md — Tracer

Tracer is an AUv3 pitch-to-MIDI plugin for macOS with a SwiftUI host app. It detects the pitch of incoming audio (YIN) in C++ and emits MIDI notes. Requires macOS 14+ and full Xcode.

## Commands

- `make setup`: install XcodeGen if missing and generate `Tracer.xcodeproj` (git-ignored) from `project.yml`.
- `make dev`: regenerate, rebuild Debug into `build/Debug`, and open `Tracer.app`.
- `make build`: Release build into `build/Release`.
- `make install` / `make uninstall` / `make reinstall`: manage `~/Applications/Tracer.app`.
- `make close`: quit the app. `make clean`: remove `build/`.

There is no test target yet.

## Layout

- `TracerExtension/DSP/`: realtime C++ (`TracerDSPKernel.hpp`, `YinPitchDetector`, `NoteStateMachine.hpp`, `MidiMath.hpp`).
- `TracerExtension/Parameters/`: parameter addresses (shared with C++) and the Swift parameter spec.
- `TracerExtension/UI/`: SwiftUI plugin views.
- `TracerExtension/Common/`: Apple's AUv3 template plumbing (audio unit, buffered bus, process helper).
- `TracerApp/`: the host app, with an audio-engine harness and virtual MIDI output for testing the extension.

## Conventions

- Edit `project.yml`, not the generated project, then run `make setup`.
- The DSP kernel runs on the audio thread: no allocation, locks, or Swift/Objective-C calls in the render path.
- A new parameter needs a matching address in `TracerParameterAddresses.h`, the spec in `Parameters.swift`, and handling in the kernel.
- Keep pitch-to-note logic (`NoteStateMachine`, `MidiMath`) pure, so it can be unit tested.

## Design principles

Follow the [design principles](docs/rules/design-principles.md) for any UI work.

## After changing code

1. `make dev`

Commit messages are one short, imperative line, like the existing history.
