#!/bin/bash

#  -- Removing old project files --
rm -rf ./dist/commonjs ./dist/ecmascript ./dist/types &&
mkdir -p ./dist/commonjs ./dist/ecmascript ./dist/types &&

#  -- Typescript transpilation --
tsc --skipLibCheck --project ./dist/commonjs.tsconfig.json > /dev/null &
tsc --skipLibCheck --project ./dist/ecmascript.tsconfig.json &
wait

#  -- Minification --
uglifyjs-folder ./dist/commonjs -x .js -o ./dist/commonjs -e > /dev/null &
uglifyjs-folder ./dist/ecmascript -x .js -o ./dist/ecmascript -e &
wait