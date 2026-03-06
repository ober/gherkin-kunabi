#!chezscheme
;;; db-leveldb.sls -- Redirect (clan db-leveldb) to (leveldb)
;;; Bridges Gerbil's :clan/db/leveldb import to chez-leveldb

(library (clan db-leveldb)
  (export
    leveldb-open leveldb-close
    leveldb-put leveldb-get leveldb-delete leveldb-key?
    leveldb-write
    leveldb-writebatch leveldb-writebatch-put leveldb-writebatch-delete
    leveldb-writebatch-clear leveldb-writebatch-append leveldb-writebatch-destroy
    leveldb-iterator leveldb-iterator-close leveldb-iterator-valid?
    leveldb-iterator-seek-first leveldb-iterator-seek-last leveldb-iterator-seek
    leveldb-iterator-next leveldb-iterator-prev
    leveldb-iterator-key leveldb-iterator-value
    leveldb-iterator-error
    leveldb-fold leveldb-for-each
    leveldb-fold-keys leveldb-for-each-keys
    leveldb-snapshot leveldb-snapshot-release
    leveldb-options leveldb-default-options
    leveldb-read-options leveldb-default-read-options
    leveldb-write-options leveldb-default-write-options
    leveldb-compact-range leveldb-destroy-db leveldb-repair-db
    leveldb-property leveldb-approximate-size)
  (import (leveldb)))
