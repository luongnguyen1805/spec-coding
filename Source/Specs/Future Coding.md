# Main

- Diagram: Coding Approaches
  - Theme: Monochrome Minimalist
    - Background: Pure White (`#FFFFFF`)
    - Foreground/Lines/Text: Solid Black (`#000000`)
    - Font: Modern sans-serif stack (system-ui, -apple-system, Arial, sans-serif)
  - Root Node: Coding Approaches
    - Icon: SVG Vector Code Brackets (`</>`)
    - Text: "Coding Approaches"
    - Style: Centered top pill-header with a solid rounded border
  - Left Domain Node: Human Coding
    - Icon: SVG Vector Human Avatar (horizontal layout, icon to the left of text block)
    - Title: "Human Coding"
    - Subtitle: "Developed and owned by humans"
    - Style: Rounded rectangle card with horizontal row layout
  - Right Domain Node: Agent Coding
    - Icon: SVG Vector Robot Head (horizontal layout, icon to the left of text block)
    - Title: "Agent Coding"
    - Subtitle: "Generated and guided by AI agents"
    - Style: Rounded rectangle card with horizontal row layout
  - Left Leaf Nodes: Specific Human Approaches
    - Manual: Write and improve code by hand
      - Icon: SVG Vector Writing Pencil (centered at top of card)
      - Title: "Manual"
      - Description: "Write and improve code by hand" (centered below title)
    - Agentic: Use AI agents to assist/automate tasks
      - Icon: SVG Vector Agentic Human/Arrow (centered at top of card)
      - Title: "Agentic"
      - Description: "Use AI agents to assist or automate coding tasks" (centered below title)
  - Right Leaf Nodes: Specific Agentic Approaches
    - Vibe: AI generates code based on intent and context
      - Icon: SVG Vector Lightning Bolt (centered at top of card)
      - Title: "Vibe"
      - Description: "AI generates code based on intent and context" (centered below title)
    - Spec: AI develops code from explicit specifications
      - Icon: SVG Vector Document Page (centered at top of card)
      - Title: "Spec"
      - Description: "AI develops code from explicit specifications" (centered below title)

# Shapes & Layouts

- Layout Architecture: Hierarchical Tree Flow
  - Connections: Orthogonal black lines centered between parent/child nodes
    - Line weight: 2px solid black
    - Alignment: Perfectly snapped to box edges and midpoints
  - Canvas Dimensions
    - Width: 1200px (scalable via viewBox)
    - Height: 800px (scalable via viewBox)
  - Node Sizing & Spacing
    - Root Node: 500px width, 100px height, 15px border-radius
    - Domain Nodes: 360px width, 120px height, 12px border-radius
    - Leaf Nodes: 220px width, 240px height, 12px border-radius
    - Horizontal Gap: 40px between leaf nodes, 160px between domains
    - Vertical Gap: 80px between hierarchy levels
  - Alignment Grid
    - Root Node: Centered horizontally at Y = 50px
    - Domain Nodes: Balanced horizontally at Y = 230px
    - Leaf Nodes: Centered under respective Domain parents at Y = 430px

# Icons

- Vector SVG Specifications
  - General: Drawn inline using SVG `<svg>` container for high-fidelity rendering
    - Stroke: 2px solid Blue (`#0000FF`), round caps and joins
    - Fill: Transparent or None
    - Size: Centered within icon areas (Root: 40px, Domain: 50px, Leaf: 40px)
  - Code Symbol (`</>`):
    - Shape: Left and right angle brackets with a central slash
    - Structure: `<path>` elements defining `<` and `>` and `/`
  - Human Avatar:
    - Shape: Stylized outline of head and shoulders
    - Structure: A circle for the head and a rounded arc for the shoulders
  - Robot Head:
    - Shape: Rounded rectangle head with circular eyes, antennae, and mouth line
    - Structure: Large rect, two small circles, two small antennae lines with balls
  - Pencil/Manual Icon:
    - Shape: Angled pencil body pointing to a bottom-left tip
    - Structure: A rotated thin rectangle with a triangular tip and a lead mark
  - Agentic Icon:
    - Shape: Human bust outline integrated with a circular progress/gear or arrow
    - Structure: Avatar outline alongside an active circular pointer/badge
  - Lightning Bolt/Vibe Icon:
    - Shape: Sharp zig-zag lightning bolt
    - Structure: Path with sharp coordinates defining top-right to bottom-left flow
  - Document/Spec Icon:
    - Shape: Folded corner page outline with horizontal lines representing text
    - Structure: Rect with top-right corner fold and 3 horizontal lines

# Texts

- Typographical Rules
  - Font Families: Modern sans-serif stack
    - Primary: `system-ui, -apple-system, sans-serif`
  - Hierarchy & Sizes
    - Root Header: Bold, 32px, letter-spacing -0.5px
    - Domain Titles: Bold, 24px, margin-bottom 6px
    - Domain Subtitles: Medium/Regular, 14px, line-height 1.4, opacity 0.8
    - Leaf Titles: Bold, 20px, margin-bottom 12px
    - Leaf Body: Regular, 13px, line-height 1.5, opacity 0.7
  - Color & Contrast
    - Text color: Solid Blue (`#0000FF`)
    - Alignment: Perfectly centered horizontally
