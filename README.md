# installtelmac.sh

`installtelmac.sh` is used to install the Teleport pkg and then the signed `tsh` pkg for MacOS.
`tsh` installed after so you get the signed version that enables touchid.

You can have it match to a specific Teleport proxy version or give a specific version.

## To install:

```bash
git clone https://github.com/stevenGravy/installtelmac
cd macinstall
chmod +x installtelmac.sh
```

Copy `installtelmac.sh` to `/usr/local/bin` or another path.


## Example usage:

`installtelmac.sh` will give usage info.

### Specific version
```bash
installtelmac.sh -v 13.2.1
````

### Install to match a given proxy
```bash
installtelmac.sh -p teleport.example.com
```

### Install with communication package (default is enterprise)
```bash
installtelmac.sh -v 13.2.1 -e false
```
