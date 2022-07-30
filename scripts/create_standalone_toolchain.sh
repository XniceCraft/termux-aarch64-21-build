#!/bin/bash
ndk_version=r25
ndk_sha1_checksum=9fce956edb6abd5aca42acf6bbfb21a90a67f75b
ndk_foldername="android-ndk-${ndk_version}"
pkg_config_libdir="/data/data/com.termux/files/usr/lib/pkgconfig"
patch_list=("bits-struct_file.h.patch"
"dirent.h.patch"
"grp.h.patch"
"linux-fcntl.h.patch"
"paths.h.patch"
"pwd.h.patch"
"redefine-TCSAFLUSH.patch"
"semaphore.h.patch"
"stdio.h.patch"
"stdlib.h.patch"
"sys-cdefs.h.patch"
"syslog.patch"
"unistd.h.patch"
"utmp.h.patch"
"langinfo.h"
"libintl.h"
)

wget_handler(){
  local url=$1
  local output_file=$2
  while (true); do
    wget -q --no-check-certificate -T 8 "$url" -O "$output_file"  && break; echo "Success" || echo "Failed. Retrying!"
  done
}

download(){
  echo "[~] Downloading NDK $ndk_version from developer.android.com"
  wget_handler "https://dl.google.com/android/repository/android-ndk-${ndk_version}-linux.zip" "${ndk_foldername}.zip"
  local checksum_result
  checksum_result=$(sha1sum "${ndk_foldername}.zip" | cut -f 1 -d ' ')

  if [[ "$checksum_result" != "$ndk_sha1_checksum" ]]; then
    echo "[-] Invalid SHA1 Checksum!"
    echo "Expected: ${ndk_sha1_checksum}"
    echo "Result: ${checksum_result}"

    local sel
    read -p -r "(R) Retry/(Q) Quit : " sel
    rm "${ndk_foldername}.zip"
    if [[ ${sel^^} == "Q" ]]; then exit; fi
    download
    return
  fi
  echo "[+] SHA1 Checksum check passed"
}

setup(){
  echo "[~] Unzipping!"
  unzip -q "${ndk_foldername}.zip" && echo "[+] Success"
  rm "${ndk_foldername}.zip"
  echo "[~] Move prebuilt toolchain to ${PWD}/${ndk_version}"
  mv "${ndk_foldername}/toolchains/llvm/prebuilt/linux-x86_64" "$ndk_version" && echo "[+] Success"
  rm -rf "$ndk_foldername"
}

remove_unnecessary(){
  local arch api_number
  rm -rf "${ndk_version}/sysroot/usr/local"
  for arch in x86_64-linux-android i686-linux-android armv7a-linux-androideabi arm-linux-androideabi; do
    rm -f "${ndk_version}/bin/${arch}"*
    rm -rf "${ndk_version}/sysroot/usr/lib/${arch}"
    rm -rf "${ndk_version}/sysroot/usr/include/${arch}"
  done
  for api_number in $(seq 23 33); do
    rm -f "${ndk_version}/bin/aarch64-linux-android${api_number}"*
    rm -rf "${ndk_version}/sysroot/usr/lib/aarch64-linux-android/${api_number}"
  done
  rm -rf "${ndk_version}/sysroot/usr/lib/aarch64-linux-android/22"
  ln -sd 21 "${ndk_version}/sysroot/usr/lib/aarch64-linux-android/22"
  for arch in arm x86_64 i386 i686; do
    rm -rf "${ndk_version}/lib64/clang/14.0.6/lib/linux/"*"${arch}"*
  done
}

patch_file(){
  echo "[~] Downloading NDK file replacement"
  wget_handler "https://github.com/XniceCraft/termux-aarch64-21-build/releases/download/Replacement/ndk_replacement.tar.xz" "ndk_replacement.tar.xz"
  echo "[~] Extracting"
  tar xf ndk_replacement.tar.xz && echo "[+] Success" || (echo "[-] Failed"; exit)
  rm ndk_replacement.tar.xz

  local file_name
  for file_name in crtbegin_dynamic.o crtbegin_static.o crtend_android.o crtbegin_so.o crtend_so.o libm.so libdl.so libc.so libstdc++.so lld; do
    if [[ "$file_name" != "lld" ]]; then
      rm "${ndk_version}/sysroot/usr/lib/aarch64-linux-android/21/${file_name}"
      mv "ndk_replacement/${file_name}" "${ndk_version}/sysroot/usr/lib/aarch64-linux-android/21/${file_name}"
    else
      rm "${ndk_version}/bin/lld"
      mv "ndk_replacement/lld" "${ndk_version}/bin/lld"
    fi
  done
  rm -r ndk_replacement

  echo "[~] Symlinking for non-prefixed binary"
  ln -s aarch64-linux-android21-clang "${ndk_version}/bin/aarch64-linux-android-clang"
  ln -s aarch64-linux-android21-clang++ "${ndk_version}/bin/aarch64-linux-android-clang++"
  ln -s aarch64-linux-android21-clang "${ndk_version}/bin/aarch64-linux-android-gcc"
  ln -s aarch64-linux-android21-clang++ "${ndk_version}/bin/aarch64-linux-android-g++"
  cp "${ndk_version}/bin/aarch64-linux-android21-clang" "${ndk_version}/bin/aarch64-linux-android-cpp"
  sed -i 's/clang/clang -E/' "${ndk_version}/bin/aarch64-linux-android-cpp"

  local _host_pkgconfig
  _host_pkgconfig=$(command -v pkg-config)
  cat << EOF > "${ndk_version}/bin/pkg-config"
#!/bin/sh
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$pkg_config_libdir
exec $_host_pkgconfig "\$@"
EOF
  chmod +x "${ndk_version}/bin/pkg-config"
  grep -lrw "${ndk_version}/sysroot/usr/include/c++/v1" -e '<version>' | xargs -n 1 sed -i 's/<version>/\"version\"/g'

  mkdir -p "${ndk_version}/aarch64-linux-android"
  local bin_name stripped_name
  for bin_name in llvm-addr2line llvm-ar llvm-as llvm-dwp llvm-nm llvm-objcopy llvm-objdump llvm-ranlib llvm-readelf llvm-readobj llvm-size llvm-strings llvm-strip; do
    stripped_name=$(echo "$bin_name" | sed "s/llvm-//")
    ln -s "../bin/${bin_name}" "${ndk_version}/aarch64-linux-android/${stripped_name}"
  done
  ln -s "../bin/lld" "${ndk_version}/aarch64-linux-android/ld"
  ln -s "../bin/lld" "${ndk_version}/aarch64-linux-android/ld.lld"
  cp "${ndk_version}/bin/aarch64-linux-android-clang" "${ndk_version}/aarch64-linux-android/clang"
  cp "${ndk_version}/bin/aarch64-linux-android-clang++" "${ndk_version}/aarch64-linux-android/clang++"
  cp "${ndk_version}/bin/aarch64-linux-android-cpp" "${ndk_version}/aarch64-linux-android/cpp"
  sed -i "s;bin_dir=\`dirname \"\$0\"\`;bin_dir=\`dirname \"\$0\"\`\/..\/bin;" "${ndk_version}/aarch64-linux-android/clang"
  sed -i "s;bin_dir=\`dirname \"\$0\"\`;bin_dir=\`dirname \"\$0\"\`\/..\/bin;" "${ndk_version}/aarch64-linux-android/clang++"
  sed -i "s;bin_dir=\`dirname \"\$0\"\`;bin_dir=\`dirname \"\$0\"\`\/..\/bin;" "${ndk_version}/aarch64-linux-android/cpp"
  ln -s clang "${ndk_version}/aarch64-linux-android/gcc"
  ln -s clang++ "${ndk_version}/aarch64-linux-android/g++"
  ln -s clang "${ndk_version}/aarch64-linux-android/cc"
  ln -s clang++ "${ndk_version}/aarch64-linux-android/c++"
  chmod +x "${ndk_version}/aarch64-linux-android/"*

  file_name=""
  echo "[~] Downloading termux ndk-patches & patching"
  cd "${ndk_version}/sysroot/usr" || (echo "${ndk_version}/sysroot/usr doest\'nt exist"; exit)
  for file_name in "${patch_list[@]}"; do
    wget_handler "https://github.com/termux/termux-packages/raw/master/ndk-patches/${file_name}" "$file_name"
    if [[ "$file_name" != "libintl.h" ]] && [[ "$file_name" != "langinfo.h" ]]; then
      sed -i -e "s;@TERMUX_PREFIX@;/data/data/com.termux/files/usr;g" -e "s;@TERMUX_HOME@;/data/data/com.termux/files/home;g" "$file_name"
      patch --silent -b -p2 -i "$file_name"
      rm "$file_name"
    else
      mv "$file_name" "include/${file_name}"
    fi
  done
  rm include/{sys/{capability,shm,sem},{glob,iconv,spawn,zlib,zconf},KHR/khrplatform}.h
  rm include/unicode/{char16ptr,platform,ptypes,putil,stringoptions,ubidi,ubrk,uchar,uconfig,ucpmap,udisplaycontext,uenum,uldnames,ulocdata,uloc,umachine,unorm2,urename,uscript,ustring,utext,utf16,utf8,utf,utf_old,utypes,uvernum,uversion}.h
  sed -i "s/define __ANDROID_API__ __ANDROID_API_FUTURE__/define __ANDROID_API__ 21/" include/android/api-level.h
  echo 'INPUT(-lunwind)' > lib/aarch64-linux-android/libgcc.a
  echo "[+] Patch finished"
}

if [[ -d "$ndk_version" ]]; then echo "Toolchain already exists. Please delete before creating new one"; exit; fi
[[ ! $(command -v wget) ]] && apt install wget -y
[[ ! $(command -v unzip) ]] && apt install unzip -y
[[ ! $(command -v pkg-config) ]] && apt install pkg-config -y
download
setup
remove_unnecessary
patch_file
echo "[=] NDK Installation Finished"
