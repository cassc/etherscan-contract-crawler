//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

struct KeyValuePair {
    string key;
    string value;
}

struct ChainScoutMetadata {
    Accessory accessory;
    BackAccessory backaccessory;
    Background background;
    Clothing clothing;
    Eyes eyes;
    Fur fur;
    Head head;
    Mouth mouth;
    uint24 attack;
    uint24 defense;
    uint24 luck;
    uint24 speed;
    uint24 strength;
    uint24 intelligence;
    uint16 level;
}