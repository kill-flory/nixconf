import json, os, glob, subprocess, time, threading
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

DIR = os.environ.get("HUD_DIR", os.path.dirname(os.path.abspath(__file__)))
HOST = os.environ.get("HUD_HOST", "127.0.0.1")
PORT = int(os.environ.get("HUD_PORT", "8090"))

def rd(p):
    try:
        return open(p).read().strip()
    except Exception:
        return None

def hwmons():
    return sorted(glob.glob("/sys/class/hwmon/hwmon*"), key=lambda p: int(p.rsplit("hwmon", 1)[1]))

def hwmon():
    out = {}
    for d in hwmons():
        s = out.setdefault(rd(d + "/name") or "?", {})
        for f in glob.glob(d + "/temp*_input"):
            v = rd(f)
            if v:
                s[rd(f.replace("_input", "_label")) or os.path.basename(f)[:-6]] = int(v) / 1000
        for f in glob.glob(d + "/fan*_input"):
            v = rd(f)
            if v:
                s[os.path.basename(f)[:-6]] = int(v)
    return out

def by_name(name):  # по одному словарю на каждое устройство (несколько DIMM / NVMe)
    out = []
    for d in hwmons():
        if rd(d + "/name") == name:
            t = {}
            for f in sorted(glob.glob(d + "/temp*_input")):
                v = rd(f)
                if v:
                    t[rd(f.replace("_input", "_label")) or os.path.basename(f)[:-6]] = int(v) / 1000
            out.append(t)
    return out

_u, _r = [None], [None]
def cpu_usage():
    p = list(map(int, open("/proc/stat").readline().split()[1:]))
    idle, tot = p[3] + p[4], sum(p)
    prev, _u[0] = _u[0], (idle, tot)
    if not prev or tot == prev[1]:
        return 0
    return round(100 * (1 - (idle - prev[0]) / (tot - prev[1])), 1)

def cpu_power():  # RAPL package energy -> ватты (нужны права на чтение energy_uj)
    for f in glob.glob("/sys/class/powercap/*/name"):
        if rd(f) == "package-0":
            d = os.path.dirname(f)
            e = rd(d + "/energy_uj")
            if e is None:
                return None
            e, now = int(e), time.time()
            prev, _r[0] = _r[0], (e, now)
            if not prev or now <= prev[1]:
                return None
            de = e - prev[0]
            if de < 0:
                de += int(rd(d + "/max_energy_range_uj") or 0)
            return round(de / 1e6 / (now - prev[1]), 1)
    return None

def cpu_freq():
    v = [int(x) for f in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq") if (x := rd(f))]
    return round(sum(v) / len(v) / 1000) if v else None

def mem():
    m = {l.split(":")[0]: int(l.split()[1]) for l in open("/proc/meminfo")}
    return {"total": m["MemTotal"] // 1024, "used": (m["MemTotal"] - m["MemAvailable"]) // 1024}

FIELDS = "name,temperature.gpu,power.draw,clocks.sm,clocks.mem,utilization.gpu,memory.used,memory.total,fan.speed"
def gpu():
    for extra in (",temperature.memory", ""):  # не на всех драйверах/картах поле есть
        try:
            o = subprocess.check_output(["nvidia-smi", "--query-gpu=" + FIELDS + extra,
                "--format=csv,noheader,nounits"], timeout=3, text=True, stderr=subprocess.DEVNULL).strip().split(", ")
            f = lambda x: float(x) if x.replace(".", "").isdigit() else None
            return dict(name=o[0], temp=f(o[1]), power=f(o[2]), clock=f(o[3]), mclock=f(o[4]), util=f(o[5]),
                        vram=f(o[6]), vram_total=f(o[7]), fan=f(o[8]), mem_temp=f(o[9]) if len(o) > 9 else None)
        except Exception:
            continue
    return None

S = {}
def sampler():
    while True:
        try:
            S["usage"], S["rapl"], S["gpu"] = cpu_usage(), cpu_power(), gpu()
        except Exception:
            pass
        time.sleep(1)

rgb = {"devices": [], "ok": False}
def rgb_loop():
    from openrgb import OpenRGBClient
    while True:
        try:
            c = OpenRGBClient(address="127.0.0.1", port=6742, name="pc-hud")
            devs = [{"name": d.name, "colors": [[k.red, k.green, k.blue] for k in d.colors],
                     "zones": [{"name": z.name, "colors": [[k.red, k.green, k.blue] for k in z.colors]} for z in d.zones]}
                    for d in c.devices]
            c.disconnect()
            rgb.update(devices=devs, ok=True)
        except Exception as e:
            rgb.update(ok=False, err=str(e))
        time.sleep(0.4)

def stats():
    h = hwmon()
    fans = {k: v for s in h.values() for k, v in s.items() if k.startswith("fan")}
    k10 = h.get("k10temp", {})
    usage, g = S.get("usage", 0), S.get("gpu")
    pc, est = S.get("rapl"), False
    if pc is None:  # RAPL недоступен — грубая оценка по загрузке, помечаем флагом
        pc, est = round(20 + usage * 0.65, 1), True
    pg = (g or {}).get("power") or 0
    nv = by_name("nvme")
    nvme_list = [{"l": (f"{i}·" if len(nv) > 1 else "") + k, "v": v} for i, t in enumerate(nv) for k, v in t.items()]
    return {"cpu": {"temp": k10.get("Tctl") or next(iter(k10.values()), None), "usage": usage, "freq": cpu_freq()},
            "gpu": g, "mem": mem(), "nvme": (nv[0].get("Composite") if nv else None), "nvme_list": nvme_list,
            "dimms": [t.get("temp1") for t in by_name("spd5118")],
            "power": {"cpu": pc, "cpu_est": est, "gpu": pg, "total": round(pc + pg, 1)},
            "fans": fans, "rgb": rgb,
            "temps": {f"{n}/{k}": v for n, x in h.items() for k, v in x.items() if not k.startswith("fan")},
            "load": os.getloadavg()[0], "uptime": float((rd("/proc/uptime") or "0").split()[0]), "t": time.time()}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path.startswith("/api/stats"):
            body, ct = json.dumps(stats()).encode(), "application/json"
        else:
            page = "sensors.html" if self.path.split("?")[0].endswith("sensors.html") else "index.html"
            body, ct = open(os.path.join(DIR, page), "rb").read(), "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ct)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

threading.Thread(target=sampler, daemon=True).start()
threading.Thread(target=rgb_loop, daemon=True).start()
ThreadingHTTPServer((HOST, PORT), H).serve_forever()
