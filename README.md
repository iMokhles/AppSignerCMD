# AppSignerCMD
command line tool to resign apps ( based on DanTheMan827's [iOS App Signer](https://github.com/DanTheMan827/ios-app-signer) application )

Supported input types are: ipa, deb, app, xcarchive

Usage
------

```
Usage: ./AppSignerCMD [options]
  -f, --file:
      Path to the input ipa file.
  -s, --certName:
      exmple: iPhone Developer: xxxx
  -p, --provisioningProfile:
      Path to the mobileprovision file.
  -i, --appID:
      exmple: com.imokhles.xxxx
  -n, --appName:
      exmple: iMDownloader
  -o, --outfile:
      Path to the output ipa file.
  -h, --help:
      Prints a help message.
  -v, --verbose:
      Print verbose messages. Specify multiple times to increase verbosity.
```

Note
------

code isn't fully clean ( if you want clean it do it and create new pull request )


Thanks To
------
[maciekish / iReSign](https://github.com/maciekish/iReSign): The basic process was gleaned from the source code of this project.

[DanTheMan827 / iOS App Signer](https://github.com/DanTheMan827/ios-app-signer)

[Jatoben / CommandLine](https://github.com/jatoben/CommandLine)