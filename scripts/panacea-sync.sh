#!/usr/bin/env bash
# Раскладывает конфиги Panacea из ~/Panacea по местам. NixOS-замена install.sh:
# пакеты и службы ставит Nix (modules/*/panacea.nix), здесь только файлы.
#
#   panacea-sync.sh               панель, foot, fish, fastfetch, nano, voxtype, скрипты
#   panacea-sync.sh --mime        + сделать Panacea приложением по умолчанию для картинок/текста/папок
#   panacea-sync.sh --wallpapers  + скачать набор обоев (~400 МБ) в ~/.config/hypr/wallpaper/shell
#   panacea-sync.sh --palette     + запустить hypr/scripts/palette.sh (раскрасить foot, btop, редакторы)
#
# ~/.config/hypr и niri НЕ трогаются (кроме флагов --wallpapers и --palette). Настройки, которые оболочка пишет сама
# (settings.json, .vibrance, assets, foot/panacea-theme), не перезаписываются.
# Перед началом делается архив старых конфигов в ~/panacea-backup-<время>.tar.gz.

set -euo pipefail

SRC="${PANACEA_SRC:-$HOME/Panacea}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

DO_MIME=0
DO_WALLS=0
DO_PALETTE=0
for arg in "$@"; do
    case "$arg" in
        --mime) DO_MIME=1 ;;
        --wallpapers) DO_WALLS=1 ;;
        --palette) DO_PALETTE=1 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "неизвестный флаг: $arg" >&2; exit 1 ;;
    esac
done

step() { printf '\n\e[1m▍ %s\e[0m\n' "$*"; }
ok()   { printf '  \e[32m✓\e[0m %s\n' "$*"; }
warn() { printf '  \e[33m!\e[0m %s\n' "$*"; }
die()  { printf '\n\e[31mОшибка:\e[0m %s\n' "$*" >&2; exit 1; }

[ -d "$SRC/panacea" ] || die "не нашёл $SRC/panacea — склонируй репозиторий в ~/Panacea или задай PANACEA_SRC"
command -v rsync >/dev/null || die "нет rsync — сначала выполни rebuild"

# ------------------------------------------------------------------ резервная копия
step "Резервная копия"
existing=()
for d in panacea foot fish fastfetch voxtype; do
    [ -e "$CONF/$d" ] && existing+=("$d")
done
if [ "${#existing[@]}" -gt 0 ]; then
    tar czf "$HOME/panacea-backup-$STAMP.tar.gz" -C "$CONF" "${existing[@]}" 2>/dev/null \
        && ok "старые конфиги → ~/panacea-backup-$STAMP.tar.gz"
else
    ok "старых конфигов нет, копировать нечего"
fi

# ------------------------------------------------------------------ конфиги
step "Копирование конфигов"

# sync <каталог> [что не перезаписывать, если уже есть...]
# Сначала копируем всё, кроме «своих» файлов пользователя, потом докладываем недостающие.
sync_dir() {
    local name="$1"; shift
    local ex=()
    local keep
    for keep in "$@"; do ex+=(--exclude="$keep"); done
    mkdir -p "$CONF/$name"
    rsync -a "${ex[@]}" --exclude='*.bak*' "$SRC/$name/" "$CONF/$name/"
    rsync -a --ignore-existing --exclude='*.bak*' "$SRC/$name/" "$CONF/$name/"
    ok "$name → $CONF/$name"
}

sync_dir panacea /settings.json /.vibrance /assets/
sync_dir foot /panacea-theme
sync_dir fish
sync_dir fastfetch

if [ -f "$SRC/nano/nanorc" ]; then
    cp "$SRC/nano/nanorc" "$HOME/.nanorc" && ok "nanorc → ~/.nanorc"
fi

mkdir -p "$HOME/.local/bin"
if [ -d "$SRC/bin" ]; then
    cp -f "$SRC"/bin/* "$HOME/.local/bin/"
    ok "скрипты → ~/.local/bin"
fi

# Пути автора (/home/ensi) → твой домашний каталог. hypr намеренно пропущен.
n=0
while IFS= read -r f; do
    sed -i "s|/home/ensi|$HOME|g" "$f" && n=$((n + 1))
done < <(grep -rIl '/home/ensi' "$CONF/panacea" "$CONF/foot" "$CONF/fish" "$CONF/fastfetch" "$HOME/.local/bin" 2>/dev/null || true)
[ "$n" -gt 0 ] && ok "пути /home/ensi заменены на $HOME в $n файлах"

# На NixOS нет /bin/bash и /usr/bin/python3 — только /usr/bin/env.
n=0
while IFS= read -r f; do
    if head -n1 "$f" | grep -qE '^#!(/usr)?/bin/(bash|python3?)'; then
        sed -i -E '1s|^#!(/usr)?/bin/bash.*|#!/usr/bin/env bash|; 1s|^#!(/usr)?/bin/python3?.*|#!/usr/bin/env python3|' "$f"
        n=$((n + 1))
    fi
done < <(find "$CONF/panacea/scripts" "$HOME/.local/bin" -maxdepth 1 -type f 2>/dev/null)
[ "$n" -gt 0 ] && ok "исправлены shebang в $n скриптах"

chmod +x "$CONF"/panacea/scripts/*.sh "$CONF"/panacea/scripts/*.py 2>/dev/null || true
chmod +x "$HOME"/.local/bin/* 2>/dev/null || true

# `qs -c panacea` ищет конфиг в ~/.config/quickshell/panacea
mkdir -p "$CONF/quickshell"
ln -sfn "$CONF/panacea" "$CONF/quickshell/panacea"
ok "qs -c panacea → $CONF/panacea"

# ------------------------------------------------------------------ voxtype
step "Голос → текст (voxtype)"
if [ -f "$CONF/panacea/scripts/voxtype.config.toml" ]; then
    mkdir -p "$CONF/voxtype"
    cp "$CONF/panacea/scripts/voxtype.config.toml" "$CONF/voxtype/config.toml"
    ok "конфиг voxtype записан"
fi
models="$HOME/.local/share/voxtype/models"
if [ -f "$models/ggml-medium.bin" ]; then
    ok "модель Whisper medium уже скачана"
else
    warn "модели Whisper ещё нет — команда для скачивания в инструкции (~1.5 ГБ)"
fi

# ------------------------------------------------------------------ ярлыки и ассоциации
step "Ярлыки"
if [ -d "$SRC/applications" ]; then
    apps="$HOME/.local/share/applications"
    mkdir -p "$apps"
    for f in "$SRC"/applications/*.desktop; do
        [ -f "$f" ] || continue
        sed "s|@HOME@|$HOME|g" "$f" > "$apps/$(basename "$f")"
    done
    command -v update-desktop-database >/dev/null && update-desktop-database "$apps" >/dev/null 2>&1 || true
    ok "panacea-*.desktop → $apps"

    if [ "$DO_MIME" = "1" ]; then
        for m in image/png image/jpeg image/gif image/webp image/bmp image/tiff image/svg+xml \
                 video/mp4 video/webm video/x-matroska; do
            xdg-mime default panacea-media.desktop "$m" 2>/dev/null || true
        done
        for m in text/plain text/markdown application/x-shellscript text/x-python \
                 text/x-lua application/json text/csv; do
            xdg-mime default panacea-text.desktop "$m" 2>/dev/null || true
        done
        xdg-mime default panacea-files.desktop inode/directory 2>/dev/null || true
        ok "Panacea назначена приложением по умолчанию (картинки, видео, текст, папки)"
    else
        ok "ассоциации файлов не менял (включить: --mime; учти, что тогда папки в GNOME тоже откроются в Panacea)"
    fi
fi

# ------------------------------------------------------------------ палитра и миниатюры
step "Палитра"
if [ "$DO_PALETTE" = "1" ]; then
    if [ -x "$CONF/hypr/scripts/palette.sh" ]; then
        "$CONF/hypr/scripts/palette.sh" >/dev/null 2>&1 && ok "цвета применены к терминалам, btop и редакторам" \
            || warn "palette.sh завершился с ошибкой — запусти его вручную и посмотри вывод"
    else
        warn "hypr/scripts/palette.sh не найден"
    fi
else
    ok "palette.sh не запускался (если цвета терминала не те — запусти скрипт с --palette)"
fi
if [ -x "$CONF/panacea/scripts/thumbs.sh" ]; then
    (setsid "$CONF/panacea/scripts/thumbs.sh" all >/dev/null 2>&1 &) || true
    ok "миниатюры обоев греются в фоне"
fi

# ------------------------------------------------------------------ обои (по флагу)
if [ "$DO_WALLS" = "1" ]; then
    step "Обои (~400 МБ)"
    dst="$CONF/hypr/wallpaper/shell"
    tmp="$(mktemp -d)"
    if git clone --depth 1 https://github.com/ilyamiro/shell-wallpapers "$tmp/w" >/dev/null 2>&1; then
        mkdir -p "$dst" "$CONF/hypr/wallpaper/live"
        n=0
        while IFS= read -r -d '' f; do
            # пробелы и спецсимволы в именах ломают file://-пути в Qt
            name="$(basename "$f" | tr ' ' '_' | tr -cd '[:alnum:]._-')"
            [ -n "$name" ] && cp -n "$f" "$dst/$name" && n=$((n + 1))
        done < <(find "$tmp/w/images" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)
        ok "обои → $dst ($n файлов)"
    else
        warn "не удалось скачать набор обоев"
    fi
    rm -rf "$tmp"
fi

# ------------------------------------------------------------------ проверки hypr (только сообщаем)
step "Проверка ~/.config/hypr (файлы не менялись)"
if grep -rIl '/home/ensi' "$CONF/hypr" >/dev/null 2>&1; then
    warn "в hypr остались пути /home/ensi — обои, тема и медиаклавиши будут ломаться:"
    grep -rIl '/home/ensi' "$CONF/hypr" | sed 's/^/        /'
    printf '        исправить (это единственное, что затронет hypr):\n'
    printf "        grep -rIl /home/ensi %s/hypr | xargs sed -i 's|/home/ensi|%s|g'\n" "$CONF" "$HOME"
else
    ok "путей /home/ensi в hypr нет"
fi
for f in lua/binds_data.lua lua/monitors_data.lua; do
    if [ ! -f "$CONF/hypr/$f" ]; then
        warn "нет hypr/$f — сочетания клавиш/режим экрана не подхватятся. Создаётся скриптами:"
        printf '        %s/panacea/scripts/genbinds.sh ; %s/panacea/scripts/genmonitors.sh\n' "$CONF" "$CONF"
        break
    fi
done

printf '\n\e[32m✓ Готово.\e[0m Перезапусти foot и панель: pkill -x foot; setsid -f foot --server\n'
