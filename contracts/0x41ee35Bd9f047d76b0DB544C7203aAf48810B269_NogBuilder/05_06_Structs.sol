// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library Structs {
     struct Nog {
        address minterAddress;
        uint16[7] colorPalette;
        uint16 nogStyle;
        uint16 backgroundStyle;
        bool hasShadow;
        bool hasAnimation;
    }

    struct NogStyle {
        string name;
        string shape;
        uint8 frameColorLength;
    }

    struct Seed {
        uint256 tokenId;
        address minterAddress;
        uint16[7] colorPalette;
        string[7] colors;
        uint16 nogStyle;
        string nogStyleName;
        string nogShape;
        uint8 frameColorLength;
        uint16 backgroundStyle;
        string backgroundStyleName;
        string shade;
        string shadow;
        string shadowAnimation;
        bool hasAnimation;
    }

    struct NogParts {
        string image;
        string colorMetadata;
        string colorPalette;
    }
}