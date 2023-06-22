// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

enum ScanlineStatus {
    Initial,
    MoveTo,
    LineTo,
    Closed
}