// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct AntiAlias {
    uint32 value;
    uint32 scale;
    uint32 mask;
}

library AntiAliasMethods {
    function create(uint32 sampling)
        internal
        pure
        returns (AntiAlias memory aa)
    {
        aa.value = sampling;
        aa.scale = uint32(1) << aa.value;
        aa.mask = aa.scale - 1;
        return aa;
    }
}

contract TestAntiAliasMethods {
    function create(uint32 sampling)
        external
        pure
        returns (AntiAlias memory aa)
    {
        return AntiAliasMethods.create(sampling);
    }
}