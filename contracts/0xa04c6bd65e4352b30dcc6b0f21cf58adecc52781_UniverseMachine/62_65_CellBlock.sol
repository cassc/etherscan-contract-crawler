// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct CellBlock {
    uint32 shift;
    uint32 size;
    uint32 mask;
    uint32 limit;
}

library CellBlockMethods {
    function create(uint32 sampling)
        internal
        pure
        returns (CellBlock memory cb)
    {
        cb.shift = sampling;
        cb.size = uint32(1) << cb.shift;
        cb.mask = cb.size - 1;
        cb.limit = 1024 * cb.size;
        return cb;
    }
}