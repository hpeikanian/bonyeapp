#!/usr/bin/env python3
"""Guard untranslated static UI copy without changing API or user data."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
catalog = (root / 'lib/core/translations.dart').read_text()
keys = set(re.findall(r'^\s*[\'"](.+?)[\'"]\s*:', catalog, re.MULTILINE))
# Separators and digit alphabets are used for parsing, not visible UI labels.
non_copy = {'،', '۰۱۲۳۴۵۶۷۸۹', '٠١٢٣٤٥٦٧٨٩'}
missing = []
paths = [root / 'lib/core/api.dart', root / 'lib/core/widgets.dart', *sorted((root / 'lib/screens').glob('*.dart'))]
for path in paths:
    for match in re.finditer(r'''([\'"])([^\'"\n$\\]*)\1''', path.read_text()):
        value = match.group(2)
        if re.search('[\u0600-\u06ff]', value) and value not in keys | non_copy:
            missing.append(f'{path.relative_to(root)}: {value}')
assert not missing, 'Missing English copy:\n' + '\n'.join(missing)
print(f'PASS: static UI copy coverage ({len(keys)} catalog entries); dynamic templates covered by widget tests')
