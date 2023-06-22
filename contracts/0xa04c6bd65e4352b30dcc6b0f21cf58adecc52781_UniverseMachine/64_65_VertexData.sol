// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Command.sol";
import "./Vector2.sol";

struct VertexData {
    Command command;
    Vector2 position;
}