// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

enum Command {
    Stop,
    MoveTo,
    LineTo,
    Curve3,
    Curve4,
    EndPoly
}