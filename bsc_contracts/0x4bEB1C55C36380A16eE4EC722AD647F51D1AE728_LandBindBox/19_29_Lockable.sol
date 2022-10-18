// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lockable {
    uint8 internal locked = 0;
    modifier lock {
        require(0 == locked, "locked");
        locked = 1;
        _;
        locked = 0;
    }
}