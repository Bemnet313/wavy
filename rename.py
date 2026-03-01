import os

root_dir = "/home/bemnet/Documents/Wavy App"

skip_dirs = {
    '.git',
    'build',
    '.dart_tool',
    '.idea',
    'Pods',
    'Runner.xcworkspace'
}

# 1. Rename contents
for dirpath, dirnames, filenames in os.walk(root_dir):
    parts = set(dirpath.split(os.sep))
    if parts.intersection(skip_dirs):
        continue
        
    for filename in filenames:
        if filename.endswith(('.pdf', '.png', '.jpg', '.jpeg', '.zip', '.tar', '.gz')):
            continue
            
        filepath = os.path.join(dirpath, filename)
        if not os.path.isfile(filepath) or os.path.islink(filepath):
            continue
            
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            if 'Wavy' in content or 'wavy' in content or 'WAVY' in content:
                new_content = content.replace('Wavy', 'Wavy').replace('wavy', 'wavy').replace('WAVY', 'WAVY')
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
        except Exception as e:
            pass

# 2. Rename files and directories bottom-up
for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
    parts = set(dirpath.split(os.sep))
    if parts.intersection(skip_dirs):
        continue
        
    for filename in filenames:
        if 'Wavy' in filename or 'wavy' in filename or 'WAVY' in filename:
            new_filename = filename.replace('Wavy', 'Wavy').replace('wavy', 'wavy').replace('WAVY', 'WAVY')
            old_path = os.path.join(dirpath, filename)
            new_path = os.path.join(dirpath, new_filename)
            try:
                os.rename(old_path, new_path)
            except Exception as e:
                print(f"Error renaming file {old_path}: {e}")
            
    for dirname in dirnames:
        if 'Wavy' in dirname or 'wavy' in dirname or 'WAVY' in dirname:
            new_dirname = dirname.replace('Wavy', 'Wavy').replace('wavy', 'wavy').replace('WAVY', 'WAVY')
            old_path = os.path.join(dirpath, dirname)
            new_path = os.path.join(dirpath, new_dirname)
            try:
                os.rename(old_path, new_path)
            except Exception as e:
                print(f"Error renaming directory {old_path}: {e}")
