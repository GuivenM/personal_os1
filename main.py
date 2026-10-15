import os
import subprocess
from collections import defaultdict
from datetime import datetime

files_by_date = defaultdict(list)

def is_ignored(filepath):
    # Returns True if gitignore blocks this file
    result = subprocess.run(
        ['git', 'check-ignore', '-q', filepath]
    )
    return result.returncode == 0

for root, _, files in os.walk('.'):
    if '.git' in root:
        continue
    for file in files:
        filepath = os.path.join(root, file)
        
        # Skip files matching .gitignore rules
        if is_ignored(filepath):
            continue
            
        mtime = os.path.getmtime(filepath)
        date_str = datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')
        files_by_date[date_str].append((mtime, filepath))

# Process dates chronologically
for date_str in sorted(files_by_date.keys()):
    latest_mtime = max(mtime for mtime, _ in files_by_date[date_str])
    commit_time = datetime.fromtimestamp(latest_mtime).strftime('%Y-%m-%d %H:%M:%S')

    staged_any = False
    for _, filepath in files_by_date[date_str]:
        # Double-check before adding
        res = subprocess.run(['git', 'add', filepath])
        if res.returncode == 0:
            staged_any = True

    if staged_any:
        env = os.environ.copy()
        env['GIT_AUTHOR_DATE'] = commit_time
        env['GIT_COMMITTER_DATE'] = commit_time
        subprocess.run(
            ['git', 'commit', '-m', f'Build updates for {date_str}'],
            env=env,
            check=True
        )