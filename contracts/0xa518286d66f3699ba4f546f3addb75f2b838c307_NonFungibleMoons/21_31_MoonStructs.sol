// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Colors describing the moon image.
struct MoonImageColors {
    string moon;
    uint16 moonHue;
    string border;
    uint8 borderSaturation;
    string background;
    uint8 backgroundLightness;
    string backgroundGradientColor;
}

// Config describing the complete moon image, with colors, positioning, and sizing.
struct MoonImageConfig {
    MoonImageColors colors;
    uint16 moonRadius;
    uint16 xOffset;
    uint16 yOffset;
    uint16 viewWidth;
    uint16 viewHeight;
    uint16 borderRadius;
    uint16 borderWidth;
    string borderType;
}