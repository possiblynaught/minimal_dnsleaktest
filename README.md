# Minimal DNS Leak Test

Minimal dns leak test script, mostly POSIX-compatible, and only uses limited tools availible in busybox or a embedded linux target (like a router). To use, download and run the script:

```bash
wget https://raw.githubusercontent.com/possiblynaught/minimal_dnsleaktest/master/leaktest.sh
chmod +x leaktest.sh
./leaktest.sh
```

Inspired by: [macvk's dnsleaktest](https://github.com/macvk/dnsleaktest)

## TODO

- [x] Use something other than shuf for rng, maybe proc based?
- [x] Test internet connection
- [x] Notify/fail internet connection test on timeout error
- [ ] Add more dns leak test sites
