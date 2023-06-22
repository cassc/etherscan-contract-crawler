// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct ScanlineSpan {
    int32 x;
    int32 length;
    int32 coverIndex;
}