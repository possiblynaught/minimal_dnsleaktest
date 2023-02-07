# Minimal DNS Leak Test

Minimal dns leak test bash script, only requires basic command line tools available in busybox or a minimal embedded linux install, designed to work with OpenWrt/libreCMC. To use, download and run the standalone script:

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
