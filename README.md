# Minimal DNS Leak Test

Minimal dns leak test script, only needs basic command line tools available in busybox or minimal embedded linux (including openwrt/librecmc). To use, download and run the standalone script:

```bash
wget https://raw.githubusercontent.com/possiblynaught/minimal_dnsleaktest/master/leaktest.sh
chmod +x leaktest.sh
./leaktest.sh
```

Inspired by: [macvk's dnsleaktest](https://github.com/macvk/dnsleaktest)

## TODO

- [x] Use something other than shuf for rng, maybe proc based?
- [x] Test internet connection
- [ ] Add more dns leak test sites
