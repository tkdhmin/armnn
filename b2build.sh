#!/bin/bash

b2 --build-dir=$BASEDIR/boost_1_64_0/build -j 4 \
			   toolset=gcc-arm \
			   link=static \
			   cxxflags=-fPIC \
			   --with-filesystem \
			   --with-test \
			   --with-log \
			   --with-program_options install \
			   --prefix=$BASEDIR/boost
