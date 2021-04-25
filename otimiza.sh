#!/bin/bash

docker run -d -v ${PWD}:/otc julia julia modelagem.jl $1
