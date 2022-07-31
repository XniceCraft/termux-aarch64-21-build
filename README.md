## Termux Aarch64 Packages Builder

### Note
```The NDK may not working properly.```

### Known Issue(s)
Nothing

### Toolchain Download r24 (Use the ndk r25 instead)
<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Google_Drive_logo.png/669px-Google_Drive_logo.png" style="width: 20px;heigth: 20px;"> GDrive : https://drive.google.com/file/d/1UIgXaRwsQT6wddB981H8vkKgZIyAOMy0 (Linux Only)

### Toolchain Changelog (will update soon)
- Remove x86_64-linux-android i686-linux-android arm-linux-androideabi and aarch64-linux-android23-33 toolchains to decrease size.
- Remove x86_64-linux-android i686-linux-android arm-linux-androideabi (include, sysroot lib, and clang static lib) to decrease size.
- Replace crtbegin_so.o, crtend_android.o, crtend_so.o, libc.so, libdl.so, libm.so with the ndk r10e one. (To avoid versioned symbol warning)
- Replace libstdc++.so with the ndk r13b.
- Replace ndk r25 lld with ld.lld from ndk r21e. (To avoid unsupported DT_FLAGS_1)
- Symlink sysroot/usr/lib/aarch64-linux-android/22 to sysroot/usr/lib/aarch64-linux-android/21
- Patching sysroot with ndk-patches from termux repo.

### Compiler Flags (Experimental)
```
PKG_CONFIG_LIBDIR=/data/data/com.termux/files/usr/lib/pkgconfig \
TOOLCHAIN=/home/r25 \
CC=${TOOLCHAIN}/bin/aarch64-linux-android21-clang \
CXX=${TOOLCHAIN}/bin/aarch64-linux-android21-clang++ \
CPP=${TOOLCHAIN}/bin/aarch64-linux-android21-cpp \
AS=${CC} \
ADDR2LINE=${TOOLCHAIN}/bin/llvm-addr2line \
AR=${TOOLCHAIN}/bin/llvm-ar \
DWP=${TOOLCHAIN}/bin/llvm-dwp \
GCOV=${TOOLCHAIN}/bin/llvm-cov \
GPROF=${TOOLCHAIN}/bin/llvm-profdata \
LD=${TOOLCHAIN}/bin/lld \
NM=${TOOLCHAIN}/bin/llvm-nm \
OBJCOPY=${TOOLCHAIN}/bin/llvm-objcopy \
OBJDUMP=${TOOLCHAIN}/bin/llvm-objdump \
STRIP=${TOOLCHAIN}/bin/llvm-strip \
RANLIB=${TOOLCHAIN}/bin/llvm-ranlib \
READELF=${TOOLCHAIN}/bin/llvm-readelf \
SIZE=${TOOLCHAIN}/bin/llvm-size \
STRINGS=${TOOLCHAIN}/bin/llvm-strings \
CFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -march=armv8-a+simd -mtune=cortex-a53 -mcpu=cortex-a53 -fPIE -fPIC -O3 -mlittle-endian -fassociative-math -mfix-cortex-a53-835769 -fstack-protector-strong -fuse-ld=lld -Wno-unused-command-line-argument " \
LDFLAGS="-pie -L/data/data/com.termux/files/usr/lib -Wl,--as-needed -Wl,-z,relro,-z,now -Wl,--hash-style=sysv " \
CXXFLAGS="${CFLAGS}" \
CPPFLAGS="-I/data/data/com.termux/files/usr/include " \
```

### Info (obtained from termux_step_setup_toolchain.sh)
```
libintl.h: Inline implementation gettext functions.
langinfo.h: Inline implementation of nl_langinfo().
Remove <sys/capability.h> because it is provided by libcap.
Remove <sys/shm.h> from the NDK in favour of that from the libandroid-shmem.
Remove <sys/sem.h> as it doesn't work for non-root.
Remove <glob.h> as we currently provide it from libandroid-glob.
Remove <iconv.h> as it's provided by libiconv.
Remove <spawn.h> as it's only for future (later than android-27).
Remove <zlib.h> and <zconf.h> as we build our own zlib.
Remove unicode headers provided by libicu.
Remove KRH/khrplatform.h provided by mesa.
```

### Credit :<br>
- <a href="https://github.com/termux/termux-packages">@termux</a> for packages patch.
- <a href="https://source.android.com">AOSP</a> for ndk r24, r25 toolchain.
