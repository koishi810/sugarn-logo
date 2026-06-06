# Logo crop variants

Three standalone web versions for comparing final logo crops.

- `corner_lower_left/`: keeps the lower-left quarter of the logo plus a small extra overlap across the center.
- `center_square/`: keeps a centered square crop. It is intentionally large, so it only cuts the edge when the logo scale is large.
- `lower_vertical_rect/`: keeps a vertical rectangle with its center shifted slightly downward.
- `cut_upper_right_quarter/`: cuts away only the upper-right quarter of the logo.

Each folder contains its own `index.html`, `style.css`, and `sketch.js`.

`保存` stores the current settings as this page's initial values in browser local storage.
After saving, `初期化` returns to the saved state, and reloading the same page restores it.
Use `データコピー` when you need a JSON export.

The parameter panel includes four crop controls:

- `裁切 X`: crop rectangle left edge, relative to the logo center.
- `裁切 Y`: crop rectangle top edge, relative to the logo center.
- `裁切 幅`: crop rectangle width.
- `裁切 高`: crop rectangle height.

Default crop rectangles:

- `corner_lower_left`: `x=-214`, `y=-46`, `width=260`, `height=260`
- `center_square`: `x=-214`, `y=-214`, `width=428`, `height=428`
- `lower_vertical_rect`: `x=-168`, `y=-218`, `width=336`, `height=472`

Saved JSON from these variant pages also includes a top-level `cropRect` field.

The `cut_upper_right_quarter` version uses `切除 X/Y/幅/高` instead of `裁切 X/Y/幅/高`.
Default cut rectangle: `x=0`, `y=-214`, `width=214`, `height=214`.
Saved JSON from that page includes a top-level `cutRect` field.
