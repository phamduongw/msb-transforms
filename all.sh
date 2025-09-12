#!/bin/bash

> _ALL.sql

find tables -type f -name "*.sql" -exec sh -c 'cat "$1" >> _ALL.sql; echo "" >> _ALL.sql' _ {} \;
find views -type f -name "*.sql" -exec sh -c 'cat "$1" >> _ALL.sql; echo "" >> _ALL.sql' _ {} \;
find types -type f -name "*.sql" -exec sh -c 'cat "$1" >> _ALL.sql; echo "" >> _ALL.sql' _ {} \;
cat packages/T24_UTILS_PKG.sql >> _ALL.sql
echo "" >> _ALL.sql
find packages -type f -name "*.sql" ! -name "T24_UTILS_PKG.sql" -exec sh -c 'cat "$1" >> _ALL.sql; echo "" >> _ALL.sql' _ {} \;
