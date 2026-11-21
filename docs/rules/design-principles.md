<!-- agent-rules:synced from agent-rules@2.0.0 (e6de8a1) sha256:a4430666ec20. Edit agent-rules/docs/rules/design-principles.md, then run `make rules`; local edits here are not kept. -->
## Design Principles

These apply to every page, feature and backlog task. A task isn't done until it meets them. If the app has no UI, ignore them.

### 1. Responsive on all devices

Every page works on phones, tablets and large displays (1920px wide and up). On a phone, the layout fits a 375px-wide screen with no horizontal scrolling, and touch targets are at least 44×44px. Nothing may depend on hover or a keyboard shortcut alone. Check every change at mobile width as well as desktop. If a backlog task would only work on desktop, it should say how it works on mobile.

### 2. Native controls look the same everywhere

The experience is the same on every device the app is intended for. Browsers draw dialogs, buttons, text fields, selects (dropdowns), checkboxes and radio buttons differently, so whenever a device might render a control differently, style it so it looks and behaves the same everywhere. Never leave a UI component at its default look.

### 3. Interactive things react to the cursor; nothing else does

Anything clickable shows a pointer cursor and changes visibly (color, background or underline) when the cursor is over it, so people can see it responds. Anything that isn't clickable keeps the default cursor and doesn't change on hover, so it never suggests an action that isn't there.

### 4. View hierarchy: Global, then App, then View

Styles build up in three layers. Libraries and global styles are the base, app-wide changes sit on top of them, and each view overrides only what it needs to. Put every style at the broadest layer where it applies. See Styles in [frontend.md](frontend.md).

### 5. Text and UI components never touch the edge of the viewport

Text against the screen edge looks cut off. Keep text and components at least 12px away from the edge with margin or padding. The exception is a panel, which may touch the edge as long as its corners aren't rounded; text inside the panel still keeps the 12px minimum from the edge.

### 6. Animations last 150ms to 300ms

Anything under 150ms is too quick to register as an animation, and anything over 300ms feels slow. Treat an animation outside this range as a violation.

### 7. State changes never change an element's hover or click mask

The mask is the area that responds to hover and clicks. If it moves or resizes while the cursor is on it, clicking becomes glitchy, so it must stay exactly the same. The visible element may still grow or shrink on hover, for example with `transform: scale()`, as long as the mask keeps its original box. Anything that shifts the layout or resizes the responsive area is a violation.

### 8. UI components aren't selectable; text content is

UI components are not selectable unless they contain text people may want to copy. The labels on buttons, tabs, menus, dropdowns and icons can't be selected. Headings, paragraphs, text formats and messages, such as error messages, stay selectable.

### 9. Readability and organization come first; a minimal UI is more functional. Reducing user interactions is 2nd priority.

The UI helps people do what they came to do and never distracts from it. Show an element only if the user needs it for the task on that view. If removing it wouldn't make the task harder, remove it. This applies to every view you build or change. For example, don't show pagination when there's only one page. Each item on a view (text, controls, icons, colors, borders) is something the user has to scan past to find what they want, so more items mean a slower search and a harder read. Prefer one clear way to do something over several.

Minimal never means unclear. Every control is plainly what it is and familiar enough that anyone knows how to use it: a button looks like a button, and a text field looks like a text field. Keep wording short and plain. Keep color simple, with a small palette and strong color saved for what needs attention. Group things with spacing rather than extra borders, boxes and dividers.

Consider both how much the user sees at once and how many interactions it takes to see or do something. An interaction is a click, tap, scroll, or opening a menu or page. Being minimal and organized comes first, and reducing interactions comes second, so when they conflict, keep the view minimal. Within that, what people use often is visible or one interaction away, and only rarely used options go behind a menu or extra step. Think of putting things away in drawers: hidden from view, but organized and labeled so people know where to look.

### 10. No invisible masks or state changes

A control responds to interaction (hover, click, tap, focus, drag, a change in the mouse cursor) across its whole visible box and nowhere outside it. For example, hovering, clicking or tapping anywhere inside a text field's border, padding included, changes its state, shows its cursor and focuses it. Anything drawn as part of a control's state counts as part of the control. A focus ring, outline or glow therefore sits inside the box (for example an inset `box-shadow`), never outside it. If a frame is drawn around a native control that covers only part of it, such as a text field that only responds on its text line, the frame must forward every interaction to the control. The one exception is dragging: once a drag has started, it can continue outside the box.

### 11. Show that something is happening

When people are waiting, give a subtle sign that work is in progress. If someone clicks something and waits for the server to respond, show a loader. Show one whenever the wait could be longer than 300ms. Put a small spinner or progress bar in or next to the thing the user acted on, without changing that control's size. Block the whole page only when the whole page is loading.

### 12. Common actions can use icons

Common actions can use an icon instead of text. Use your judgment about which actions are common, such as close, add, delete, edit and search. A button with an uncommon icon needs a tooltip that names its action, so no one has to guess what it does.

### 13. Icons are clear, familiar and monochrome

Use an icon where it is clear and familiar, and prefer a familiar icon over text. Icons are monochrome so they can match the text color. The UI's own icons are never emojis, whether in navigation, buttons, menus, lists or empty states. Content people write or choose can use emojis, such as text, messages, or an emoji or image someone picks for something they made, like a project.
