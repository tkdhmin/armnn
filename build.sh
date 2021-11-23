#!/bin/bash

cmake -DCMAKE_LINKER=/usr/bin/arm-linux-gnueabihf-ld \
					 -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabihf-gcc \
					 -DCMAKE_CXX_COMPILER=/usr/bin/arm-linux-gnueabihf-g++ \
					 -DCMAKE_C_COMPILER_FLAGS=-fPIC \
					 -DCMAKE_CXX_FLAGS=-mfpu=neon \
					 -DARMCOMPUTE_ROOT=$BASEDIR/ComputeLibrary \
					 -DARMCOMPUTE_BUILD_DIR=$BASEDIR/ComputeLibrary/build \
					 -DBOOST_ROOT=$BASEDIR/boost \
					 -DBUILD_TF_PARSER=1 \
					 -DTF_GENERATED_SOURCES=$BASEDIR/tensorflow-protobuf \
					 -DPROTOBUF_ROOT=$BASEDIR/protobuf-host \
					 -DBUILD_TF_LITE_PARSER=1 \
					 -DTF_LITE_GENERATED_PATH=$BASEDIR/tensorflow/tensorflow/lite/schema \
					 -DFLATBUFFERS_ROOT=$BASEDIR/flatbuffers \
					 -DFLATBUFFERS_LIBRARY=$BASEDIR/flatbuffers/libflatbuffers.a \
					 -DARMCOMUTENEON=1 \
					 -DBUILD_TESTS=1 \
					 -DARMNNREF=1 ..

