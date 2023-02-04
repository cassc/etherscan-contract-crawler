// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Grid Renderer
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundGridRenderer {
    struct Symbol {
        uint32 seed;
        uint8 gridPalette;
        uint8 gridSize;
        uint8 id;
        uint8 level;
        uint8 palette;
        bool opaque;
    }

    struct Override {
        uint16 symbols;
        uint16 positions;
        string colors;
        uint16 size;
    }

    function generateGrid(
        Symbol memory symbol,
        Override[] memory overides,
        uint256 gradient,
        uint256 edition
    ) external view returns (string memory);
}