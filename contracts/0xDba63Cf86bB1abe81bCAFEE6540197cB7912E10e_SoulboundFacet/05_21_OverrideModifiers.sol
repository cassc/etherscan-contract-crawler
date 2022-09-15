// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OverrideModifiers {
    modifier isOverride() {
        require(
            msg.sender == address(this),
            "Override functions can only be called internally"
        );
        _;
    }
}