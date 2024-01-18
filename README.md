# installtelmac.sh

`installtelmac.sh` is a bash script used to download & install the Teleport pkg and then the signed `tsh` pkg for MacOS.
`tsh` installed after so you get the signed version that enables touchid. The pkgs are prompted to delete after installation.

You can have it match to a specific Teleport proxy version or give a specific version.

## To install:

```bash
git clone https://github.com/stevenGravy/installtelmac
cd installtelmac
chmod +x installtelmac.sh
sudo cp installtelmac.sh /usr/local/bin
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

### Install with community package (default is enterprise)
```bash
installtelmac.sh -v 13.2.1 -e false
```
