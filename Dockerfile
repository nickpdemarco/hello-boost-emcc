FROM emscripten/emsdk

# Hi, grepper. Boost Dependency: 1.74.0
ARG BOOST_MAJOR=1
ARG BOOST_MINOR=74
ARG BOOST_PATCH=0

RUN apt remove --purge cmake -y && \ 
    pip install cmake --upgrade

WORKDIR /build/boost-wasm

RUN wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH}/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz \
    && tar xfz boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz \ 
    && rm boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.gz

WORKDIR /build/boost-wasm/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}

RUN ./bootstrap.sh --with-icu=/emsdk/upstream/emscripten/cache/ports/icu/icu     

RUN ./b2 \
    -q \ 
    link=static \
    toolset=emscripten \
    variant=release \
    threading=single \
    --with-filesystem \
    --with-system \
    install

COPY . /src

WORKDIR /build

RUN emmake cmake /src

RUN emmake cmake --build .
