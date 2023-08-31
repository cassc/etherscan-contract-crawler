// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


struct PingAtts {
    uint8 numX;
    uint8 numY;
    uint8 paletteIndex;
    bool hasTexture;
    bool openShape;
    uint8 lineColorIdx;
    uint8 paintIdx;
    uint8 shapeColorIdx;
    uint8 emitColorIdx;
    uint8 shadowColorIdx;
    uint8 nShadColIdx;
    uint8 shapeSizesDensity;
    uint8 lineThickness;
    uint8 emitRate;
    uint8 wiggleSpeedIdx;
    uint8 wiggleStrengthIdx;
    uint8 paint2Idx;

    uint8[] extraParams;
}