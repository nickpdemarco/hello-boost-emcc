FROM emscripten/emsdk

# Hi, grepper. Boost Dependency: 1.65.1
ARG BOOST_MAJOR=1
ARG BOOST_MINOR=65
ARG BOOST_PATCH=1

# Note: This is a variable visible to cmake. Not sure how it gets there.
# Should try to find the real source of truth and replace.
ARG EMSCRIPTEN_SYSROOT=/emsdk/upstream/emscripten/cache/sysroot

RUN apt remove --purge cmake -y && \ 
    pip install cmake --upgrade

# One or all of these might be redundant considering we're building off the emsdk image.
# Try removing this once everything is working.
RUN emsdk install latest \ 
    && emsdk activate latest \
    && chmod +x /emsdk/emsdk_env.sh \
    && /emsdk/emsdk_env.sh

WORKDIR ${EMSCRIPTEN_SYSROOT}/build/boost-wasm

RUN wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH}/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz \
    && tar xfz boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz \ 
    && rm boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz

WORKDIR ${EMSCRIPTEN_SYSROOT}/build/boost-wasm/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}

RUN emconfigure ./bootstrap.sh \
    --with-icu=/emsdk/upstream/emscripten/cache/ports/icu/icu \
    printf "using clang : emscripten : emcc -s USE_ZLIB=1 -s USE_ICU=1 : <archiver>emar <ranlib>emranlib <linker>emlink <cxxflags>\"-std=c++17 -fPIC -s USE_ICU=1\" ;" \
        | tee -a ./project-config.jam >/dev/null

RUN emconfigure ./b2 \
    # -j $(nproc) \
    -q \ 
    link=static \
    toolset=clang-emscripten \
    variant=release \
    threading=single \
    # Find other libraries with `./b2 --show-libraries`.
    --with-filesystem \
    --with-system \
    # --with-test \
    install

WORKDIR ${EMSCRIPTEN_SYSROOT}/build/boost-wasm/libs

RUN find ${EMSCRIPTEN_SYSROOT}/build/boost-wasm/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}/bin.v2/libs \ 
    -name \*.a \ 
    -exec cp {} ${EMSCRIPTEN_SYSROOT}/build/boost-wasm/libs \;

COPY . /src

WORKDIR ${EMSCRIPTEN_SYSROOT}/build

RUN emcmake cmake /src \ 
  -DBOOST_ROOT=${EMSCRIPTEN_SYSROOT}/build/boost-wasm/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH} \
  # -DBOOST_INCLUDEDIR=${EMSCRIPTEN_SYSROOT}/build/boost-wasm/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH} \ 
  -DBOOST_LIBRARYDIR=${EMSCRIPTEN_SYSROOT}/build/boost-wasm/libs
  # -DVERBOSE=1 \
  # -DCMAKE_FIND_DEBUG_MODE=ON

# All of the following fail in the same way: trying to link elf files together. 
# Somewhere above we're failing to call emcc/em++, and are probably getting the system compiler.
# It may be that b2 doesn't respect some environment variable set by emconfigure. 
# RUN emmake make VERBOSE=1
# RUN emmake cmake --build . 

# This fails with a parsing error - -DCMAKE_TOOLCHAIN_FILE=/... gets appended after "cmake --build ."
# emcmake cmake --build .