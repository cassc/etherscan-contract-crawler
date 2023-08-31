// File: contracts/Structs.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

struct PlaneAttributes {
    uint8 locX;
    uint8 locY;
    uint8 angle;
    uint8 trailCol;
    uint8 level;
    uint8 speed;
    uint8 planeType;
    uint8[] extraParams;
}

struct BaseAttributes {
    uint8 proximity;
    uint8 skyCol;
    uint8 numPlanes;
    uint8 palette;
    PlaneAttributes[] planeAttributes;
    uint8[] extraParams;
}


enum PlaneEP {
    PaintType,
    PaletteIdx,
    ColorIdx,
    ColorIdx2,
    ColorIdx3
}

enum PaintTypes {
    None,
    Solid
}

enum EP {
    NumAngles,
    PaintType,
    PaletteIdx
}

struct PaintData {
    uint8 paintType;
    uint[] pingIds;
    uint[][] extraData; //not used
}