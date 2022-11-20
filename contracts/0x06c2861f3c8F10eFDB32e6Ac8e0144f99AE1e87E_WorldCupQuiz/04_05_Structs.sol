// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

struct Game {
    uint256 id;
    uint256 buyIn;
    uint256 timestamp;
    uint256 entryCount;
    bool started;
    bool ended;
    uint256 prize;
    address winner;
    mapping(address => bool) entries;
    mapping(address => bool) kicked;
    bool _exists;
}

struct Authorization {
    bytes32 r;
    bytes32 s;
    uint8 v;
}