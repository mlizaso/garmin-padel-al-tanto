"""Check the tracked files for personal contact details and private build inputs."""

from pathlib import Path
import re
import subprocess
import sys


def main():
    paths = subprocess.check_output(["git", "ls-files", "-z"]).split(b"\0")
    private_types = {".der", ".pem", ".p12", ".pfx", ".key", ".fit", ".iq"}
    email = re.compile(rb"[\w.+%-]+@[\w.-]+\.[a-zA-Z]{2,}\b")
    private_key = re.compile(rb"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----")
    issues = []
    for entry in filter(None, paths):
        path = Path(entry.decode("utf-8"))
        if path.parts[0] == "work" or path.suffix.lower() in private_types:
            issues.append((path, "private build input or activity"))
            continue
        data = path.read_bytes()
        if private_key.search(data):
            issues.append((path, "private key header"))
        if path.suffix.lower() in {".html", ".txt", ".md"} and email.search(data):
            issues.append((path, "literal email address in public documentation"))
    for path, reason in issues:
        print(f"{path}: {reason}", file=sys.stderr)
    return int(bool(issues))


if __name__ == "__main__":
    sys.exit(main())
