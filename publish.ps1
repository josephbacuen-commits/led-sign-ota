# Builds the LED sign sketch and makes the files for an update by SMS:
#   firmware.bin.gz.000, .001, ...  the compressed firmware in 64 KB parts
#                                   (the modem cannot hold the whole file)
#   latest.txt                      "<CODE_VERSION> <md5> <size> <parts>"
# Commit and push them, wait ~5 min (GitHub raw cache), then text UPDATE.
# Bump CODE_VERSION in the sketch first: the sign skips a version it already runs.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sketch = Join-Path $here '..\Air780ScrollWith-Time_v2\Air780ScrollWith-Time_v2.ino'
$build = Join-Path $env:TEMP 'led-ota-build'
$board = 'esp8266:esp8266:nodemcuv2:xtal=80,vt=flash,exception=disabled,stacksmash=disabled,ssl=all,mmu=3232,non32xfer=fast,eesz=4M2M,led=2,ip=lm2f,dbg=Disabled,lvl=None____,wipe=none,baud=115200'
$partSize = 65536

$m = Select-String -Path $sketch -Pattern 'const char\* CODE_VERSION = "([^"]+)"'
if (-not $m) { throw 'CODE_VERSION not found in the sketch' }
$version = $m.Matches[0].Groups[1].Value

New-Item -ItemType Directory -Force $build | Out-Null
& 'C:\Program Files (x86)\Arduino\arduino_debug.exe' --verify --pref "build.path=$build" --board $board $sketch | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Compile failed' }

# gzip in memory
$bin = [IO.File]::ReadAllBytes((Join-Path $build 'Air780ScrollWith-Time_v2.ino.bin'))
$ms = New-Object IO.MemoryStream
$gz = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionLevel]::Optimal)
$gz.Write($bin, 0, $bin.Length)
$gz.Close()
$data = $ms.ToArray()

# Old parts (and the old single file) go away
Get-ChildItem $here -Filter 'firmware.bin.gz*' | Remove-Item

$parts = [Math]::Ceiling($data.Length / $partSize)
for ($i = 0; $i -lt $parts; $i++) {
  $len = [Math]::Min($partSize, $data.Length - $i * $partSize)
  $chunk = New-Object byte[] $len
  [Array]::Copy($data, $i * $partSize, $chunk, 0, $len)
  [IO.File]::WriteAllBytes((Join-Path $here ('firmware.bin.gz.{0:D3}' -f $i)), $chunk)
}

$md5 = [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash($data)).Replace('-', '').ToLower()
[IO.File]::WriteAllText((Join-Path $here 'latest.txt'), "$version $md5 $($data.Length) $parts`n")

"$version  $($data.Length) bytes in $parts parts  md5 $md5"
