#!/usr/bin/python3
import hashlib, io, json, os, subprocess, sys
from pathlib import Path
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk
from PIL import Image

cache = Path.home() / '.cache/macshell/dock-icons'
cache.mkdir(parents=True, exist_ok=True)
display = Gdk.Display.get_default()
theme = Gtk.IconTheme.get_for_display(display) if display else None
result = {}
for name in dict.fromkeys(sys.argv[1:]):
    try:
        if name.startswith('/'):
            source = name
        else:
            icon = theme.lookup_icon(name, [], 512, 1, Gtk.TextDirection.NONE, Gtk.IconLookupFlags.FORCE_REGULAR) if theme else None
            file = icon.get_file() if icon else None
            source = file.get_path() if file else None
        if not source or not os.path.isfile(source):
            continue
        st = os.stat(source)
        key = hashlib.sha256((source + ':' + str(st.st_mtime_ns) + ':full-v2').encode()).hexdigest()[:24]
        output = cache / (key + '.png')
        if not output.exists():
            if source.lower().endswith('.svg'):
                raw = subprocess.run(['rsvg-convert', '-w', '1024', '-h', '1024', '--keep-aspect-ratio', source], check=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout
                im = Image.open(io.BytesIO(raw)).convert('RGBA')
            else:
                im = Image.open(source).convert('RGBA')
            bbox = im.getchannel('A').getbbox()
            if not bbox: continue
            im = im.crop(bbox)
            scale = min(512 / im.width, 512 / im.height)
            im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', (512, 512))
            canvas.alpha_composite(im, ((512-im.width)//2, (512-im.height)//2))
            canvas.save(output)
        result[name] = str(output)
    except Exception:
        continue
print(json.dumps(result, ensure_ascii=False))
