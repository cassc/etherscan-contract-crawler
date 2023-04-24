//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Blacklist {
    struct AntiBot {
        mapping(address => bool) _blacklistedUsers;
    }
    AntiBot antiBot;
}