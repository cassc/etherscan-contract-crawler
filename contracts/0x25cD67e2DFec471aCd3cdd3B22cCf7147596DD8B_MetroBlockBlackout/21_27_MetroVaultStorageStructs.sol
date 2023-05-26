// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

struct Stake {
    address owner;
    uint40 timestamp;
    uint16 cityId;
    uint40 extra;
}