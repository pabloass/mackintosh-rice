#!/usr/bin/python3
import json, sys, time, subprocess
from gi.repository import Gio, GLib

subprocess.Popen(['/usr/libexec/geoclue-2.0/demos/agent'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
time.sleep(0.5)
bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
service = 'org.freedesktop.GeoClue2'
def call(path, iface, method, signature=None, values=None):
    args = GLib.Variant(signature, values) if signature else None

    try: return bus.call_sync(service, path, iface, method, args, None, Gio.DBusCallFlags.NONE, 8000, None).unpack()
    except Exception as e: raise RuntimeError(iface + '.' + method + ': ' + str(e))
def get(path, iface, prop):
    return call(path, 'org.freedesktop.DBus.Properties', 'Get', '(ss)', (iface, prop))[0]
def set_prop(path, iface, prop, signature, value):
    call(path, 'org.freedesktop.DBus.Properties', 'Set', '(ssv)', (iface, prop, GLib.Variant(signature, value)))
try:
    client = call('/org/freedesktop/GeoClue2/Manager', service+'.Manager', 'GetClient')[0]
    iface = service+'.Client'
    set_prop(client, iface, 'DesktopId', 's', 'macshell-weather')
    set_prop(client, iface, 'RequestedAccuracyLevel', 'u', 6)
    call(client, iface, 'Start')
    deadline = time.monotonic() + 12
    while time.monotonic() < deadline:
        loc = get(client, iface, 'Location')
        if loc and loc != '/':
            props = call(loc, 'org.freedesktop.DBus.Properties', 'GetAll', '(s)', (service+'.Location',))[0]
            print(json.dumps({'latitude': props['Latitude'], 'longitude': props['Longitude'], 'accuracy': props['Accuracy'], 'city': 'Current Location'}))
            sys.exit(0)
        time.sleep(0.5)
    raise RuntimeError('location unavailable')
except Exception as e:
    print(str(e), file=sys.stderr)
    sys.exit(1)
