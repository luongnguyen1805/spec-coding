
# Specifications

- "Specs/Future Coding.md"

# Clarifications

# Main

- Step 1: Canvas & Background Setup
  - Create a modern, standalone HTML5 document.
  - Set viewport styling to eliminate margins/scrollbars and center content.
  - Insert a high-fidelity `<svg>` element with `viewBox="0 0 1200 800"` and size `100%`.
  - Add a pure white rect covering the entire 1200x800 background.
- Step 2: Connection Lines Drawing
  - Place lines behind node rectangles to ensure clean border rendering.
  - Draw central trunk line: Vertical from root bottom center to split level.
  - Draw left trunk branch: Horizontal split to Left Domain center, then vertical drop.
  - Draw right trunk branch: Horizontal split to Right Domain center, then vertical drop.
  - Draw leaf connector groups: Drop lines from Domain bottoms, split horizontally, and drop vertically to each Leaf center.
- Step 3: Draw Node Boxes & Borders
  - Root Node: Draw rounded rectangle at top center coordinates.
  - Domain Nodes: Draw rounded rectangles for Human and Agent Domains.
  - Leaf Nodes: Draw rounded rectangles for the four specific coding approaches.
  - Style: All nodes have a solid 2px black border and pure white fill.
- Step 4: Embed Icons and Typographic Text
  - Render each icon in its precise node-offset coordinate using clean `<g>` groups and vector paths.
  - Render title and description text using `<text>` elements.
  - Style text with CSS font-family, bold font-weights, and proper vertical offsets.
  - Use text-anchor "middle" or correct margins for pixel-perfect centering.