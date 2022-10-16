// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract CreationTracked {
    /// will be used when recovering events, to limit search of past events to this specific point in time
    uint256 public immutable CREATION_BLOCK;

    //
    constructor() {
        CREATION_BLOCK = block.number;
    }
}