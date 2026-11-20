<!-- agent-rules:synced from agent-rules@1.5.0+10 (906e099) sha256:1b2f39fbc854. Edit agent-rules/docs/rules/audio-plugins.md, then run `make rules`; local edits here are not kept. -->
# Audio Plugins

For audio plugins (effects and instruments) and the host apps that test them. Applies when the project's platforms include `audio-plugin`.

## Controls

- Continuous parameters use knobs, not sliders.
- Discrete choices use the right non-knob control: a segmented control or menu for a few named options, a toggle for on/off.
- Every knob shows its name and its current value with units (`50%`, `+3 st`, `120 ms`, `1/16`).
- The user can set an exact value. Clicking the value turns it into a text field.
  - Return or clicking away commits the value. Escape cancels.
  - Units in the typed text are accepted (`50%` and `50` mean the same thing).
  - Values outside the range are clamped. Text that isn't a number leaves the value unchanged.
- Dragging up or down changes the value; don't use rotary dragging. A held modifier key gives fine adjustment. The scroll wheel also adjusts the value.
- Double-clicking a knob resets the parameter to its default.
- The knob's arc shows the value. Bipolar parameters (pitch, pan, detune) fill from the center.
- Knobs are accessible as adjustable controls with a label and a spoken value. Arrow keys step the value when the knob has focus.

## Parameters

- Every control reads and writes through the plugin's parameter system so host automation, presets and state saving work. The UI also updates when the host changes a parameter.
- Each parameter defines its range, default, unit and display strings once, in the parameter definition. The UI reads them from there instead of repeating them.
- Parameter addresses and IDs are stable and never derived from array position. Hosts store automation and presets by them.

## The audio thread

- The render callback never allocates, locks, logs, does I/O or waits on another thread.
- Never create the render callback inside code bound to the main or UI thread. Some languages add a check that the callback runs on that thread, and it traps on the audio thread. Build the callback in code that isn't bound to a thread.
- State shared with the render callback uses parameters, atomics or lock-free structures, not UI-thread objects.
