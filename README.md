# LED sign firmware updates

The sign downloads `latest.txt` (`<version> <md5> <size> <parts>`) and, if the
version is new, `firmware.bin.gz.000`, `.001`, ... (64 KB parts of the gzipped
firmware). Only the admin number can start an update (text `UPDATE`).

To publish a new version: bump `CODE_VERSION` in the sketch, run `publish.ps1`,
then commit and push the parts and `latest.txt`.
