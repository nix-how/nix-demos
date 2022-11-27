# nix-demos

Sometimes you want to show people the power of Nix.

## runtimeReport

Based on [Recovering Nix derivation attributes of runtime
dependencies](https://www.nmattia.com/posts/2019-10-08-runtime-dependencies.html)
by Nicolas Mattia, you can generate a runtime dependency report, which includes
recursive license information, if you run it as follows:

`nix bundle --bundler github:nix-how/nix-demos#runtimeReport nixpkgs#hello`

This will produce a symlink to the `/nix/store` by the name and version of the
package, with the following output:

```
❯ nix bundle --bundler .#runtimeReport nixpkgs#hello
❯ cat hello-2.12.1-report
  ---------------------------------
  |        OFFICIAL REPORT        |
  |   requested by: the lawyers   |
  |    written by: yours truly    |
  |    TOP SECRET - TOP SECRET    |
  ---------------------------------

runtime dependencies of hello-2.12.1:
 - libidn2-2.3.2 (lgpl3Plus, gpl2Plus, gpl3Plus) maintained by Franz Pletz
 - hello-2.12.1 (gpl3Plus) maintained by Eelco Dolstra
 - glibc-2.35-163 (lgpl2Plus) maintained by Eelco Dolstra, Maximilian Bosch
 - libunistring-1.0 (lgpl3Plus) maintained by
```

This is similar to an SBOM, but in no particular format such as SPDX or
CycloneDX. This could be expanded upon.

