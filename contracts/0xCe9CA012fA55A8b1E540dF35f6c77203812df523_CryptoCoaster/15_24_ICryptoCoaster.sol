// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Settings {
    uint256 seed;
    uint256 biomeIDX;
    string biomeName;
//    uint256 color;
//    string colorHex;
//    string colorName;
    Color color;
    uint256 scale;
    uint256 speed;
    uint256 flip;
    bytes[6] vars;
}

struct Color {
    string name;
    string trackHex;
    string iconHex;
}