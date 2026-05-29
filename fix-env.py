import os

env_path = os.path.expanduser('~/windsurf-container/.env')

with open(env_path, 'r') as f:
    raw = f.read().strip()

# Extract the token value whether or not key= prefix is present
if '=' in raw:
    val = raw.split('=', 1)[1]
else:
    val = raw

# Escape $ as $$ for docker compose .env parsing
val_escaped = val.replace('$', '$$')

# Rebuild full .env preserving any other lines
lines = []
found = False
try:
    with open(env_path, 'r') as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith('WINDSURF_TOKEN=') or (not found and '=' not in stripped and stripped):
                lines.append(f'WINDSURF_TOKEN={val_escaped}\n')
                found = True
            else:
                lines.append(line if line.endswith('\n') else line + '\n')
except:
    pass

if not found:
    lines.append(f'WINDSURF_TOKEN={val_escaped}\n')

with open(env_path, 'w') as f:
    f.writelines(lines)

print('Fixed .env:')
with open(env_path, 'r') as f:
    print(f.read())
