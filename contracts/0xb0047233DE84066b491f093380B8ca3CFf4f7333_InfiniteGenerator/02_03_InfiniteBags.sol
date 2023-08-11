// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
@title  InfiniteBags
@author VisualizeValue
@notice Bags to hold infinity token data. Imo pretty funny...
*/

/// @dev Bag holding computed token data.
struct Token {
    uint seed;
    string background;
    string gridColor;
    uint8 alloy;
    uint8 grid;
    uint8 count;
    uint8 band;
    uint8 gradient;
    bool continuous;
    bool mapColors;
    bool light;
    Symbol[64] symbols;
}

/// @dev Bag holding computed symbol data.
struct Symbol {
    uint form;
    uint16 formWidth;
    bool isInfinity;
    string rotation;
    string stroke;
    string center;
    string scale;
    string width;
    string x;
    string y;
    uint colorIdx;
    Color color;
}

/// @dev Bag holding color data.
struct Color {
    uint16 h;
    uint16 s;
    uint16 l;
    string rendered;
}