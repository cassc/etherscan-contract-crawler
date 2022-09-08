// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum DisplayType {
    String,
    Number,
    Date,
    BoostPercent,
    BoostNumber
}

// TODO: generalize this, probably uint8s
enum LayerType {
    PORTRAIT,
    BACKGROUND,
    TEXTURE,
    OBJECT,
    OBJECT2,
    BORDER
}