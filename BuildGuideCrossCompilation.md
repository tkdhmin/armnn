# How to Cross-Compile Arm NN on x86_64 for arm64

- [Introduction](#introduction)
- [Cross-compiling ToolChain](#cross-compiling-toolchain)
- [Build and install Google's Protobuf library](#build-and-install-google-s-protobuf-library)
- [Build Compute Library](#build-compute-library)
- [Download ArmNN](#download-armnn)
- [Build Flatbuffer](#build-flatbuffer)
- [Build Onnx](#build-onnx)
- [Build TfLite](#build-tflite)
- [Build Arm NN](#build-armnn)
- [Build Standalone Sample Dynamic Backend](#build-standalone-sample-dynamic-backend)
- [Run Unit Tests](#run-unit-tests)
- [Troubleshooting and Errors:](#troubleshooting-and-errors-)


## Introduction
These are the step by step instructions on Cross-Compiling Arm NN under an x86_64 system to target an Arm64 system. This build flow has been tested with Ubuntu 16.04 and it depends on the same version of Ubuntu or Debian being installed on both the build host and target machines. The instructions assume you are using a bash shell and show how to build the Arm NN core library, Protobuf, Tflite, Flatbuffer and Compute Libraries.
Start by creating a directory to contain all components:

'''
mkdir $HOME/armnn-devenv
cd $HOME/armnn-devenv
'''


## Cross-compiling ToolChain
* Install the standard cross-compilation libraries for arm64:
```
sudo apt install crossbuild-essential-arm64
```

## Build and install Google's Protobuf library

We support protobuf version 3.12.0
* Get protobuf from here: https://github.com/protocolbuffers/protobuf : 
```bash
git clone -b v3.12.0 https://github.com/google/protobuf.git protobuf
cd protobuf
git submodule update --init --recursive
./autogen.sh
```
* Build a native (x86_64) version of the protobuf libraries and compiler (protoc):
  (Requires cUrl, autoconf, llibtool, and other build dependencies if not previously installed: sudo apt install curl autoconf libtool build-essential g++)
```
mkdir x86_64_build
cd x86_64_build
../configure --prefix=$HOME/armnn-devenv/google/x86_64_pb_install
make install -j16
cd ..
```
* Build the arm64 version of the protobuf libraries:
```
mkdir arm64_build
cd arm64_build
CC=aarch64-linux-gnu-gcc \
CXX=aarch64-linux-gnu-g++ \
../configure --host=aarch64-linux \
--prefix=$HOME/armnn-devenv/google/arm64_pb_install \
--with-protoc=$HOME/armnn-devenv/google/x86_64_pb_install/bin/protoc
make install -j16
cd ..
```


## Build Compute Library
* Building the Arm Compute Library:
```bash
cd $HOME/armnn-devenv
git clone https://github.com/ARM-software/ComputeLibrary.git
cd ComputeLibrary/
git checkout <tag_name>
scons arch=arm64-v8a neon=1 opencl=1 embed_kernels=1 extra_cxx_flags="-fPIC" -j4 internal_only=0
```

For example, if you want to checkout release tag of 21.02:
```bash
git checkout v21.02
```

## Download ArmNN

```bash
cd $HOME/armnn-devenv
git clone https://github.com/ARM-software/armnn.git
cd armnn
git checkout <branch_name>
git pull
```

For example, if you want to checkout release branch of 21.02:
```bash
git checkout branches/armnn_21_02
git pull
```

## Build Flatbuffer
* Building Flatbuffer version 1.12.0
```bash
cd $HOME/armnn-devenv
wget -O flatbuffers-1.12.0.tar.gz https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz
tar xf flatbuffers-1.12.0.tar.gz
cd flatbuffers-1.12.0
rm -f CMakeCache.txt
mkdir build
cd build
cmake .. -DFLATBUFFERS_BUILD_FLATC=1 \
     -DCMAKE_INSTALL_PREFIX:PATH=$HOME/armnn-devenv/flatbuffers \
     -DFLATBUFFERS_BUILD_TESTS=0
make all install
```

* Build arm64 version of flatbuffer
```bash
cd ..
mkdir build-arm64
cd build-arm64
# Add -fPIC to allow us to use the libraries in shared objects.
CXXFLAGS="-fPIC" cmake .. -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc \
     -DCMAKE_CXX_COMPILER=/usr/bin/aarch64-linux-gnu-g++ \
     -DFLATBUFFERS_BUILD_FLATC=1 \
     -DCMAKE_INSTALL_PREFIX:PATH=$HOME/armnn-devenv/flatbuffers-arm64 \
     -DFLATBUFFERS_BUILD_TESTS=0
make all install
```

## Build Onnx
* Building Onnx
```bash
cd $HOME/armnn-devenv
git clone https://github.com/onnx/onnx.git
cd onnx
git fetch https://github.com/onnx/onnx.git 553df22c67bee5f0fe6599cff60f1afc6748c635 && git checkout FETCH_HEAD
LD_LIBRARY_PATH=$HOME/armnn-devenv/google/x86_64_pb_install/lib:$LD_LIBRARY_PATH \
$HOME/armnn-devenv/google/x86_64_pb_install/bin/protoc \
onnx/onnx.proto --proto_path=. --proto_path=../google/x86_64_pb_install/include --cpp_out $HOME/armnn-devenv/onnx
```

## Build TfLite
* Building TfLite (Tensorflow version 2.3.1)
```bash
cd $HOME/armnn-devenv
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow/
git checkout fcc4b966f1265f466e82617020af93670141b009
cd ..
mkdir tflite
cd tflite
cp ../tensorflow/tensorflow/lite/schema/schema.fbs .
../flatbuffers-1.12.0/build/flatc -c --gen-object-api --reflect-types --reflect-names schema.fbs
```

## Build Arm NN
* Compile Arm NN for arm64:
```bash
cd $HOME/armnn-devenv/armnn
mkdir build
cd build
```

* Use CMake to configure your build environment, update the following script and run it from the armnn/build directory to set up the Arm NN build:
```bash
#!/bin/bash
CXX=aarch64-linux-gnu-g++ CC=aarch64-linux-gnu-gcc cmake .. \
-DARMCOMPUTE_ROOT=$HOME/armnn-devenv/ComputeLibrary \
-DARMCOMPUTE_BUILD_DIR=$HOME/armnn-devenv/ComputeLibrary/build/ \
-DARMCOMPUTENEON=1 -DARMCOMPUTECL=1 -DARMNNREF=1 \
-DONNX_GENERATED_SOURCES=$HOME/armnn-devenv/onnx \
-DBUILD_ONNX_PARSER=1 \
-DBUILD_TF_LITE_PARSER=1 \
-DTF_LITE_GENERATED_PATH=$HOME/armnn-devenv/tflite \
-DFLATBUFFERS_ROOT=$HOME/armnn-devenv/flatbuffers-arm64 \
-DFLATC_DIR=$HOME/armnn-devenv/flatbuffers-1.12.0/build \
-DPROTOBUF_ROOT=$HOME/armnn-devenv/google/x86_64_pb_install \
-DPROTOBUF_ROOT=$HOME/armnn-devenv/google/x86_64_pb_install/ \
-DPROTOBUF_LIBRARY_DEBUG=$HOME/armnn-devenv/google/arm64_pb_install/lib/libprotobuf.so.23.0.0 \
-DPROTOBUF_LIBRARY_RELEASE=$HOME/armnn-devenv/google/arm64_pb_install/lib/libprotobuf.so.23.0.0
```

* If you want to include standalone sample dynamic backend tests, add the argument to enable the tests and the dynamic backend path to the CMake command:
```bash
-DSAMPLE_DYNAMIC_BACKEND=1 \
-DDYNAMIC_BACKEND_PATHS=$SAMPLE_DYNAMIC_BACKEND_PATH
```
* Run the build
```bash
make -j32
```

## Build Standalone Sample Dynamic Backend
* The sample dynamic backend is located in armnn/src/dynamic/sample
```bash
cd $HOME/armnn-devenv/armnn/src/dynamic/sample
mkdir build
cd build
```

* Use CMake to configure your build environment, update the following script and run it from the armnn/src/dynamic/sample/build directory to set up the Arm NN build:
```bash
#!/bin/bash
CXX=aarch64-linux-gnu-g++ CC=aarch64-linux-gnu-gcc cmake .. \
-DCMAKE_CXX_FLAGS=--std=c++14 \
-DARMNN_PATH=$HOME/armnn-devenv/armnn/build/libarmnn.so
```

* Run the build
```bash
make
```

## Run Unit Tests
* Copy the build folder to an arm64 linux machine
* Copy the libprotobuf.so.23.0.0 library file to the build folder
* If you enable the standalone sample dynamic tests, also copy libArm_SampleDynamic_backend.so library file to the folder specified as $SAMPLE_DYNAMIC_BACKEND_PATH when you build Arm NN 
* cd to the build folder on your arm64 machine and set your LD_LIBRARY_PATH to its current location:

```bash
cd build/
```

* Create a symbolic link to libprotobuf.so.23.0.0:

```bash
ln -s libprotobuf.so.23.0.0 ./libprotobuf.so.23
```

* Run the UnitTests:

```bash
LD_LIBRARY_PATH=./:$LD_LIBRARY_PATH ./UnitTests
Running 4493 test cases...

*** No errors detected
```

## Troubleshooting and Errors:
### Missing libz.so.1
* When compiling armNN:
```bash
/usr/lib/gcc-cross/aarch64-linux-gnu/5/../../../../aarch64-linux-gnu/bin/ld: warning: libz.so.1, needed by /home/<username>/armNN/usr/lib64/libprotobuf.so.23.0.0, not found (try using -rpath or -rpath-link)
```

* Missing arm64 libraries for libz.so.1, these can be added by adding a second architecture to dpkg and explicitly installing them:
```bash
sudo dpkg --add-architecture arm64
sudo apt-get install zlib1g:arm64
sudo apt-get update
sudo ldconfig
```
* If apt-get update returns 404 errors for arm64 repos refer to section 5 below.
* Alternatively the missing arm64 version of libz.so.1 can be downloaded and installed from a .deb package here:
      https://launchpad.net/ubuntu/wily/arm64/zlib1g/1:1.2.8.dfsg-2ubuntu4
```bash
sudo dpkg -i zlib1g_1.2.8.dfsg-2ubuntu4_arm64.deb
```
<br><br>

### Unable to install arm64 packages after adding arm64 architecture
* Using sudo apt-get update should add all of the required repos for arm64 but if it does not or you are getting 404 errors the following instructions can be used to add the repos manually:
* From stackoverflow:
https://askubuntu.com/questions/430705/how-to-use-apt-get-to-download-multi-arch-library/430718
* Open /etc/apt/sources.list with your preferred text editor.

* Mark all the current (default) repos as \[arch=<current_os_arch>], e.g.
```bash
deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ xenial main restricted
```
* Then add the following:
```bash
deb [arch=arm64] http://ports.ubuntu.com/ xenial main restricted
deb [arch=arm64] http://ports.ubuntu.com/ xenial-updates main restricted
deb [arch=arm64] http://ports.ubuntu.com/ xenial universe
deb [arch=arm64] http://ports.ubuntu.com/ xenial-updates universe
deb [arch=arm64] http://ports.ubuntu.com/ xenial multiverse
deb [arch=arm64] http://ports.ubuntu.com/ xenial-updates multiverse
deb [arch=arm64] http://ports.ubuntu.com/ xenial-backports main restricted universe multiverse
```
* Update and install again:
```bash
sudo apt-get install zlib1g:arm64
sudo apt-get update
sudo ldconfig
```
<br><br>

### Undefined references to google::protobuf:: functions
* Missing or out of date protobuf compilation libraries.
    Use the command 'protoc --version' to check which version of protobuf is available (version 3.12.0 is required).
    Follow the instructions above to install protobuf 3.12.0
<br><br>

### Errors on strict-aliasing rules when compiling the Compute Library
* When compiling the Compute Library there are multiple errors on strict-aliasing rules:
 ```
cc1plus: error: unrecognized command line option ‘-Wno-implicit-fallthrough’ [-Werror]
 ```
* Add Werror=0 to the scons command:
```
scons arch=arm64-v8a neon=1 opencl=1 embed_kernels=1 extra_cxx_flags="-fPIC" -j8 internal_only=0 Werror=0
```
