#!/usr/bin/python3
"""Export a named screenshot attachment using Xcode 15's xcresulttool interface."""

import json
from pathlib import Path
import subprocess
import sys


def export_capture(result, output, attachment_name="launch"):
    if not result.is_absolute() or not output.is_absolute():
        raise ValueError("Result and output paths must be absolute")
    visited = set()

    def read(reference=None):
        command = ["/usr/bin/xcrun", "xcresulttool", "get", "--format", "json", "--path", str(result)]
        if reference:
            command.extend(["--id", reference])
        return json.loads(subprocess.run(command, check=True, capture_output=True, text=True).stdout)

    def find(node):
        if isinstance(node, list):
            for child in node:
                found = find(child)
                if found:
                    return found
        elif isinstance(node, dict):
            name = node.get("name", {}).get("_value", "")
            payload = node.get("payloadRef", {}).get("id", {}).get("_value")
            if name in (attachment_name, attachment_name + ".png") and payload:
                return payload
            for key, child in node.items():
                # Test summaries and activities contain attachment payload refs.
                # Avoid loading build logs, diagnostics, or unrelated objects.
                if key in ("testsRef", "summaryRef"):
                    reference = child.get("id", {}).get("_value")
                    if reference and reference not in visited:
                        visited.add(reference)
                        found = find(read(reference))
                        if found:
                            return found
                else:
                    found = find(child)
                    if found:
                        return found
        return None

    payload = find(read())
    if not payload:
        raise RuntimeError("The result bundle contains no screenshot attachment named " + attachment_name)
    # Export through the calling terminal, outside the test runner's restrictions.
    temporary = output.with_name(output.name + ".exporting")
    try:
        subprocess.run(["/usr/bin/xcrun", "xcresulttool", "export", "--type", "file",
                        "--path", str(result), "--id", payload,
                        "--output-path", str(temporary)], check=True)
        if temporary.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
            raise RuntimeError("Exported attachment is not a PNG")
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        if len(sys.argv) not in (3, 4):
            raise ValueError("Usage: export-capture.py ABSOLUTE_RESULT_BUNDLE ABSOLUTE_OUTPUT_PNG [ATTACHMENT_NAME]")
        export_capture(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3] if len(sys.argv) == 4 else "launch")
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print("Screenshot export failed: " + str(error), file=sys.stderr)
        sys.exit(1)
