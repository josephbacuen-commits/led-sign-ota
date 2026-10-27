# Builds the LED sign sketch and makes the two files for an update by SMS:
#   firmware.bin.gz  the compressed firmware
#   latest.txt       "<CODE_VERSION> <md5 of firmware.bin.gz>"
# Upload both to the folder set with UPDATEURL, then text UPDATE to the sign.
# Bump CODE_VERSION in the sketch first: the sign skips a version it already runs.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sketch = Join-Path $here '..\Air780ScrollWith-Time_v2\Air780ScrollWith-Time_v2.ino'
$build = Join-Path $env:TEMP 'led-ota-build'
$board = 'esp8266:esp8266:nodemcuv2:xtal=80,vt=flash,exception=disabled,stacksmash=disabled,ssl=all,mmu=3232,non32xfer=fast,eesz=4M2M,led=2,ip=lm2f,dbg=Disabled,lvl=None____,wipe=none,baud=115200'

$m = Select-String -Path $sketch -Pattern 'const char\* CODE_VERSION = "([^"]+)"'
if (-not $m) { throw 'CODE_VERSION not found in the sketch' }
$version = $m.Matches[0].Groups[1].Value

New-Item -ItemType Directory -Force $build | Out-Null
& 'C:\Program Files (x86)\Arduino\arduino_debug.exe' --verify --pref "build.path=$build" --board $board $sketch | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Compile failed' }

$bin = Join-Path $build 'Air780ScrollWith-Time_v2.ino.bin'
$gzPath = Join-Path $here 'firmware.bin.gz'
$in = [IO.File]::OpenRead($bin)
$out = [IO.File]::Create($gzPath)
$gz = New-Object IO.Compression.GZipStream($out, [IO.Compression.CompressionLevel]::Optimal)
$in.CopyTo($gz)
$gz.Close(); $in.Close()

$md5 = (Get-FileHash $gzPath -Algorithm MD5).Hash.ToLower()
[IO.File]::WriteAllText((Join-Path $here 'latest.txt'), "$version $md5`n")

"$version  firmware.bin.gz $((Get-Item $gzPath).Length) bytes  md5 $md5"
"Upload firmware.bin.gz and latest.txt from $here"
