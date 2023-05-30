// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;


/// @dev Data struct that will be passed to the rendering contract
struct TokenData {
    uint256 mintTimestamp;
    uint96 generation;
    address originalOwner;
    bytes[] data;
}