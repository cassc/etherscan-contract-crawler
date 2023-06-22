// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./ScanlineStatus.sol";
import "./ScanlineSpan.sol";
import "./AntiAlias.sol";

struct ScanlineData {
    int32[] gamma;
    int32 scanY;
    int32 startX;
    int32 startY;
    ScanlineStatus status;
    int32 coverIndex;
    uint8[] covers;
    int32 spanIndex;
    ScanlineSpan[] spans;
    int32 current;
    int32 lastX;
    int32 y;
}

library ScanlineDataMethods {
    function create(AntiAlias memory aa)
        internal
        pure
        returns (ScanlineData memory scanlineData)
    {
        scanlineData.startX = 0;
        scanlineData.startY = 0;
        scanlineData.status = ScanlineStatus.Initial;
        scanlineData.gamma = new int32[](aa.scale);
        for (uint32 i = 0; i < aa.scale; i++) {
            scanlineData.gamma[i] = int32(i);
        }
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.covers = new uint8[](1000);
        scanlineData.spans = new ScanlineSpan[](1000);
    }
}