# Fonts

All UI text currently uses Godot's default theme font (set nowhere
explicitly, so it falls back automatically). Drop a `.ttf`/`.otf` here and
apply it globally via **Project Settings → GUI → Theme → Custom Font**, or
per-control with `add_theme_font_override("font", load("res://assets/fonts/your_font.ttf"))`
in the UI scripts under `scripts/ui/`. A monospaced or technical sci-fi
display face suits the AI/terminal aesthetic described in the design doc.
