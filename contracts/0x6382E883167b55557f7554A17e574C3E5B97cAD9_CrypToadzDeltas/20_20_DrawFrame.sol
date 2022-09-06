// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

struct DrawFrame {
    bytes buffer;
    uint position;
    GIFFrame frame;
    uint32[] colors;
    uint8 ox;
    uint8 oy;
    bool blend;
}