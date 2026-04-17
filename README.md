# build-scripts

Build shell scripts for embedded CI/CD pipelines. Used by **generic-cicd** shared library. Scripts handle only the build step — source fetching is done by the integration manifest via `repo sync`.

## Structure

```
build-scripts/
├── common.sh                    # Shared utilities (log, die, ensure_dir, elapsed, report_size)
├── backup-caches.sh             # Cache backup utility
├── integration/                 # Integration build scripts (multi-repo manifest)
│   ├── yocto-build.sh           #   Yocto BitBake (RPi4, poky + meta-raspberrypi)
│   ├── aosp-build.sh            #   AOSP (raspberry-vanilla, lunch + m)
│   └── custom-build.sh          #   CMake cross-compilation
└── component/                   # Component build scripts (single-repo)
    ├── cmake-build.sh           #   CMake (configure + build)
    ├── make-build.sh            #   GNU Make
    ├── autotools-build.sh       #   Autotools (configure + make)
    ├── meson-build.sh           #   Meson + Ninja
    ├── bazel-build.sh           #   Bazel
    ├── yocto-sdk-build.sh       #   Yocto SDK (cross-compile with SDK env)
    └── android-ndk-build.sh     #   Android NDK (ndk-build or CMake)
```

## Design Principles

- **Build only** — scripts never fetch sources. The integration manifest (`repo sync`) or git clone handles source checkout. Scripts validate that sources exist and fail fast if not.
- **Environment-driven** — scripts read `$WORKSPACE`, `$CACHE_DIR`, and type-specific env vars (e.g., `$MACHINE`, `$IMAGE`, `$TARGET`). No hardcoded paths in the build logic.
- **Cacheable** — Yocto uses `DL_DIR`, `SSTATE_DIR`, and `SOURCE_MIRROR_URL` (own-mirrors) for local premirror cache. AOSP uses `ccache`.
- **Docker-ready** — scripts run inside Docker containers on Jenkins agents. Toolchain paths (e.g., `/opt/toolchains/`) come from the Docker image.

## Environment Variables

### Common (injected by pipeliner)

| Variable | Description |
|----------|-------------|
| `WORKSPACE` | Workspace root (e.g., `/mnt/workspace/audioi2`) |
| `WORKSPACE_ROOT` | Same as `WORKSPACE` |
| `CACHE_DIR` | Cache directory for sstate/downloads/ccache |

### Yocto (`integration/yocto-build.sh`)

| Variable | Default | Description |
|----------|---------|-------------|
| `MACHINE` | `raspberrypi4-64` | Yocto target machine |
| `DISTRO` | `poky` | Yocto distribution |
| `IMAGE` | `core-image-minimal` | BitBake target image |
| `SOURCE_MIRROR` | `/mnt/workspace/cache/yocto/downloads` | Local premirror for fetches |

### AOSP (`integration/aosp-build.sh`)

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET` | `rpi4-ap3a-userdebug` | AOSP lunch target |
| `JOBS` | `$(nproc)` | Parallel build jobs |
| `SOURCE_DIR` | `${WORKSPACE}/aosp` | AOSP source tree root |
| `CCACHE_SIZE` | `50G` | ccache max size |

### Custom (`integration/custom-build.sh`)

| Variable | Default | Description |
|----------|---------|-------------|
| `SOURCE_DIR` | `${WORKSPACE}/projects/custom-firmware` | Source directory |
| `TOOLCHAIN_FILE` | `/opt/toolchains/aarch64-linux-gnu.cmake` | CMake toolchain file |

## Usage

Scripts are referenced in YAML pipeline configs:

```yaml
# In project-config/projects/yocto-bsp.yml
yocto:
  buildScript: build-scripts/integration/yocto-build.sh
  env:
    MACHINE: raspberrypi4-64
    IMAGE: core-image-minimal
```

The pipeline runs: `bash <buildScript> [args]` inside a Docker container.

## Related Repos

- **generic-cicd** — Jenkins shared library (pipeline orchestration)
- **project-config** — YAML pipeline configs that reference these scripts

## License

Internal Use — see [LICENSE](LICENSE)
