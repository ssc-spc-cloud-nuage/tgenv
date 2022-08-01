![CI](https://github.com/tfutils/tgenv/workflows/CI/badge.svg)

# tgenv

[Terragrunt](https://terragrunt.gruntwork.io/) version manager inspired by [tfenv](https://github.com/tfutils/tfenv)

## Support

Currently tgenv supports the following OSes

- macOS
  - 64bit
  - Arm (Apple Silicon)
- Linux
  - 64bit
  - Arm
- Windows (64bit) - only tested in git-bash - currently presumed failing due to symlink issues in git-bash

## Installation

### Manual

1. Check out tgenv into any path (here is `${HOME}/.tgenv`)

```console
$ git clone --depth=1 https://github.com/ssc-spc-cloud-nuage/tgenv.git ~/.tgenv
```

2. Add `~/.tgenv/bin` to your `$PATH` any way you like

```console
$ echo 'export PATH="$HOME/.tgenv/bin:$PATH"' >> ~/.bash_profile
```

  For WSL users
```bash
$ echo 'export PATH=$PATH:$HOME/.tgenv/bin' >> ~/.bashrc
```

  OR you can make symlinks for `tgenv/bin/*` scripts into a path that is already added to your `$PATH` (e.g. `/usr/local/bin`) `OSX/Linux Only!`

```console
$ ln -s ~/.tgenv/bin/* /usr/local/bin
```

  On Ubuntu/Debian touching `/usr/local/bin` might require sudo access, but you can create `${HOME}/bin` or `${HOME}/.local/bin` and on next login it will get added to the session `$PATH`
  or by running `. ${HOME}/.profile` it will get added to the current shell session's `$PATH`.

```console
$ mkdir -p ~/.local/bin/
$ . ~/.profile
$ ln -s ~/.tgenv/bin/* ~/.local/bin
$ which tgenv
```

## Usage

### tgenv install [version]

Install a specific version of Terragrunt.

If no parameter is passed, the version to use is resolved automatically via [TGENV\_TERRAGRUNT\_VERSION environment variable](#tgenv_terragrunt_version) or [.terragrunt-version files](#terragrunt-version-file), in that order of precedence, i.e. TGENV\_TERRAGRUNT\_VERSION, then .terragrunt-version. The default is 'latest' if none are found.

If a parameter is passed, available options:

- `x.y.z` [Semver 2.0.0](https://semver.org/) string specifying the exact version to install
- `latest` is a syntax to install latest version
- `latest:<regex>` is a syntax to install latest version matching regex (used by grep -e)
- `min-required` is a syntax to recursively scan your Terragrunt files to detect which version is minimally required. See [required_version](https://www.terragrunt.io/docs/configuration/terragrunt.html) docs. Also [see min-required](#min-required) section below.

```console
$ tgenv install
$ tgenv install 0.7.0
$ tgenv install latest
$ tgenv install latest:^0.8
$ tgenv install min-required
```

#### .terragrunt-version

If you use a [.terragrunt-version](#terragrunt-version-file) file, `tgenv install` (no argument) will install the version written in it.

#### min-required

Please note that we don't do semantic version range parsing but use first ever found version as the candidate for minimally required one. It is up to the user to keep the definition reasonable. I.e.

```terragrunt
// this will detect 0.12.3
terragrunt {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

```terragrunt
// this will detect 0.10.0
terragrunt {
  required_version  = ">= 0.10.0, <0.12.3"
}
```

### Environment Variables

#### TGENV

##### `TGENV_ARCH`

String (Default: amd64)

Specify architecture. Architecture other than the default amd64 can be specified with the `TGENV_ARCH` environment variable

```console
$ TGENV_ARCH=arm64 tgenv install 0.7.9
```

##### `TGENV_AUTO_INSTALL`

String (Default: true)

Should tgenv automatically install terragrunt if the version specified by defaults or a .terragrunt-version file is not currently installed.

```console
$ TGENV_AUTO_INSTALL=false terragrunt plan
```

```console
$ terragrunt use <version that is not yet installed>
```

##### `TGENV_CURL_OUTPUT`

Integer (Default: 2)

Set the mechanism used for displaying download progress when downloading terragrunt versions from the remote server.

* 2: v1 Behaviour: Pass `-#` to curl
* 1: Use curl default
* 0: Pass `-s` to curl

##### `TGENV_DEBUG`

Integer (Default: 0)

Set the debug level for TGENV.

* 0: No debug output
* 1: Simple debug output
* 2: Extended debug output, with source file names and interactive debug shells on error
* 3: Debug level 2 + Bash execution tracing

##### `TGENV_REMOTE`

String (Default: https://releases.hashicorp.com)

To install from a remote other than the default

```console
$ TGENV_REMOTE=https://example.jfrog.io/artifactory/hashicorp
```

##### `TGENV_REVERSE_REMOTE`

Integer (Default: 0)

When using a custom remote, such as Artifactory, instead of the Hashicorp servers,
the list of terragrunt versions returned by the curl of the remote directory may be inverted.
In this case the `latest` functionality will not work as expected because it expects the
versions to be listed in order of release date from newest to oldest. If your remote
is instead providing a list that is oldes-first, set `TGENV_REVERSE_REMOTE=1` and
functionality will be restored.

```console
$ TGENV_REVERSE_REMOTE=1 tgenv list-remote
```

##### `TGENV_CONFIG_DIR`

Path (Default: `$TGENV_ROOT`)

The path to a directory where the local terragrunt versions and configuration files exist.

```console
TGENV_CONFIG_DIR="$XDG_CONFIG_HOME/tgenv"
```

##### `TGENV_TERRAGRUNT_VERSION`

String (Default: "")

If not empty string, this variable overrides Terragrunt version, specified in [.terragrunt-version files](#terragrunt-version-file).
`latest` and `latest:<regex>` syntax are also supported.
[`tgenv install`](#tgenv-install-version) and [`tgenv use`](#tgenv-use-version) command also respects this variable.

e.g.

```console
$ TGENV_TERRAGRUNT_VERSION=latest:^0.11. terragrunt --version
```

##### `TGENV_NETRC_PATH`

String (Default: "")

If not empty string, this variable specifies the credentials file used to access the remote location (useful if used in conjunction with TGENV_REMOTE).

e.g.

```console
$ TGENV_NETRC_PATH="$PWD/.netrc.tgenv"
```

#### Bashlog Logging Library

##### `BASHLOG_COLOURS`

Integer (Default: 1)

To disable colouring of console output, set to 0.


##### `BASHLOG_DATE_FORMAT`

String (Default: +%F %T)

The display format for the date as passed to the `date` binary to generate a datestamp used as a prefix to:

* `FILE` type log file lines.
* Each console output line when `BASHLOG_EXTRA=1`

##### `BASHLOG_EXTRA`

Integer (Default: 0)

By default, console output from tgenv does not print a date stamp or log severity.

To enable this functionality, making normal output equivalent to FILE log output, set to 1.

##### `BASHLOG_FILE`

Integer (Default: 0)

Set to 1 to enable plain text logging to file (FILE type logging).

The default path for log files is defined by /tmp/$(basename $0).log
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_FILE=1 tgenv use latest
```

will log to `/tmp/tgenv-use.log`

##### `BASHLOG_FILE_PATH`

String (Default: /tmp/$(basename ${0}).log)

To specify a single file as the target for all FILE type logging regardless of the executing script.

##### `BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX`

String (Default: "")

*BE CAREFUL - MISUSE WILL DESTROY EVERYTHING YOU EVER LOVED*

This variable allows you to pass a string containing a command that will be executed using `eval` in order to produce a prefix to each console output line, and each FILE type log entry.

e.g.

```console
$ BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX='echo "${$$} "'
```
will prefix every log line with the calling process' PID.

##### `BASHLOG_JSON`

Integer (Default: 0)

Set to 1 to enable JSON logging to file (JSON type logging).

The default path for log files is defined by /tmp/$(basename $0).log.json
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_JSON=1 tgenv use latest
```

will log in JSON format to `/tmp/tgenv-use.log.json`

JSON log content:

`{"timestamp":"<date +%s>","level":"<log-level>","message":"<log-content>"}`

##### `BASHLOG_JSON_PATH`

String (Default: /tmp/$(basename ${0}).log.json)

To specify a single file as the target for all JSON type logging regardless of the executing script.

##### `BASHLOG_SYSLOG`

Integer (Default: 0)

To log to syslog using the `logger` binary, set this to 1.

The basic functionality is thus:

```console
$ local tag="${BASHLOG_SYSLOG_TAG:-$(basename "${0}")}";
$ local facility="${BASHLOG_SYSLOG_FACILITY:-local0}";
$ local pid="${$}";
$ logger --id="${pid}" -t "${tag}" -p "${facility}.${severity}" "${syslog_line}"
```

##### `BASHLOG_SYSLOG_FACILITY`

String (Default: local0)

The syslog facility to specify when using SYSLOG type logging.

##### `BASHLOG_SYSLOG_TAG`

String (Default: $(basename $0))

The syslog tag to specify when using SYSLOG type logging.

Defaults to the PID of the calling process.



### tgenv use [version]

Switch a version to use

If no parameter is passed, the version to use is resolved automatically via [.terragrunt-version files](#terragrunt-version-file) or [TGENV\_TERRAGRUNT\_VERSION environment variable](#tgenv_terragrunt_version) (TGENV\_TERRAGRUNT\_VERSION takes precedence), defaulting to 'latest' if none are found.

`latest` is a syntax to use the latest installed version

`latest:<regex>` is a syntax to use latest installed version matching regex (used by grep -e)

`min-required` will switch to the version minimally required by your terragrunt sources (see above `tgenv install`)

```console
$ tgenv use
$ tgenv use min-required
$ tgenv use 0.7.0
$ tgenv use latest
$ tgenv use latest:^0.8
```

Note: `tgenv use latest` or `tgenv use latest:<regex>` will find the latest matching version that is already installed. If no matching versions are installed, and TGENV_AUTO_INSTALL is set to `true` (which is the default) the the latest matching version in the remote repository will be installed and used.

### tgenv uninstall &lt;version>

Uninstall a specific version of Terragrunt
`latest` is a syntax to uninstall latest version
`latest:<regex>` is a syntax to uninstall latest version matching regex (used by grep -e)

```console
$ tgenv uninstall 0.7.0
$ tgenv uninstall latest
$ tgenv uninstall latest:^0.8
```

### tgenv list

List installed versions

```console
$ tgenv list
* 0.10.7 (set by /opt/tgenv/version)
  0.9.0-beta2
  0.8.8
  0.8.4
  0.7.0
  0.7.0-rc4
  0.6.16
  0.6.2
  0.6.1
```

### tgenv list-remote

List installable versions

```console
$ tgenv list-remote
0.9.0-beta2
0.9.0-beta1
0.8.8
0.8.7
0.8.6
0.8.5
0.8.4
0.8.3
0.8.2
0.8.1
0.8.0
0.8.0-rc3
0.8.0-rc2
0.8.0-rc1
0.8.0-beta2
0.8.0-beta1
0.7.13
0.7.12
...
```

## .terragrunt-version file

If you put a `.terragrunt-version` file on your project root, or in your home directory, tgenv detects it and uses the version written in it. If the version is `latest` or `latest:<regex>`, the latest matching version currently installed will be selected.

Note, that [TGENV\_TERRAGRUNT\_VERSION environment variable](#tgenv_terragrunt_version) can be used to override version, specified by `.terragrunt-version` file.

```console
$ cat .terragrunt-version
0.6.16

$ terragrunt version
Terragrunt v0.6.16

Your version of Terragrunt is out of date! The latest version
is 0.7.3. You can update by downloading from www.terragrunt.io

$ echo 0.7.3 > .terragrunt-version

$ terragrunt version
Terragrunt v0.7.3

$ echo latest:^0.8 > .terragrunt-version

$ terragrunt version
Terragrunt v0.8.8

$ TGENV_TERRAGRUNT_VERSION=0.7.3 terragrunt --version
Terragrunt v0.7.3
```

## Upgrading

```console
$ git --git-dir=~/.tgenv/.git pull
```

## Uninstalling

```console
$ rm -rf /some/path/to/tgenv
```

## LICENSE

- [tgenv itself](https://github.com/ssc-spc-cloud-nuage/tgenv/blob/main/LICENSE)
- [tfenv](https://github.com/tfutils/tfenv/blob/master/LICENSE)
- tgenv uses most of [tfenv](https://github.com/tfutils/tfenv)'s source code. Great work tfenv team!
