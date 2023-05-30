// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library Structs {
    struct Nog {
        address minterAddress;
        uint16 zorggleType;
        uint16[7] colorPalette;
        uint16 nogStyle;
    }

    struct NogStyle {
        string name;
        string shape;
        uint8 frameColorLength;
    }

    struct Seed {
        uint256 tokenId;
        address ownerAddress;
        address minterAddress;
        uint16[7] colorPalette;
        string[7] colors;
        uint16 nogStyle;
        string nogStyleName;
        string nogShape;
        uint8 frameColorLength;
        uint16 zorggleType;
        string zorggleTypeName;
        string zorggleTypePath;
    }

    struct NogParts {
        string image;
        string colorMetadata;
        string colorPalette;
    }
}