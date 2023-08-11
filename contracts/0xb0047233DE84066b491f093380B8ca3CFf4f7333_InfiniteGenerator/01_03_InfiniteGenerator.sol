// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InfiniteBags.sol";
import "./Utilities.sol";

/**
@title  InfiniteGenerator
@author VisualizeValue
@notice Gathers the data to render Infinity visuals.
*/
library InfiniteGenerator {

    /// @dev 16 distinct colors + void.
    uint8 public constant ELEMENTS = 17;

    /// @dev Number of shades for each color.
    uint8 public constant SHADES = 4;

    /// @dev Collect relevant rendering data for easy access across functions.
    function tokenData(uint tokenId) public pure returns (Token memory data) {
        data.seed        = tokenId;
        data.light       = tokenId % 4096 == 0 ? true : false;
        data.background  = data.light == true ? '#FFFFFF' : '#111111';
        data.gridColor   = data.light == true ? '#F5F5F5' : '#19181B';
        data.grid        = getGrid(data);
        data.count       = data.grid ** 2;
        data.alloy       = getAlloy(data);
        data.band        = getBand(data);
        data.continuous  = getContinuous(data);
        data.gradient    = getGradient(data);
        data.mapColors   = getColorMap(data);
        data.symbols     = getSymbols(data);
    }

    /// @dev Define the grid for a token.
    function getGrid(Token memory data) public pure returns (uint8) {
        if (data.seed == 0) return 1; // Genesis token override.

        uint n = Utilities.random(data.seed, 'grid', 160);

        return n <  1 ? 1
             : n <  8 ? 2
             : n < 32 ? 4
                      : 8;
    }

    /// @dev Define the color band size for a token.
    function getBand(Token memory data) public pure returns (uint8) {
        // Four times the number of used elements, min 1.
        return Utilities.max(data.alloy * SHADES, 1);
    }

    /// @dev Whether to map symbols to colors.
    function getColorMap(Token memory data) public pure returns (bool) {
        // 20% for gradients; 8% for skittles.
        return data.gradient > 0
            ? Utilities.random(data.seed, 'color_map', 100) < 20
            : Utilities.random(data.seed, 'color_map', 100) < 8;
    }

    /// @dev Whether color banding is continuous or random. 50/50.
    function getContinuous(Token memory data) public pure returns (bool) {
        return Utilities.random(data.seed, 'continuous', 2) < 1;
    }

    /// @dev Get the number of distinct elements used. 0 for Isolates.
    function getAlloy(Token memory data) public pure returns (uint8) {
        if (data.grid == 1) return 0;

        uint8 n = uint8(Utilities.random(data.seed, 'alloy', 100));

        return n >= 56 ? 4 + n % (ELEMENTS - 4) // Complete
             : n >= 24 ? 2                     // Compound
             : n >=  4 ? 1                    // Composite
                       : 0;                  // Isolate
    }

    /// @dev Choose a gradient for the token.
    function getGradient(Token memory data) public pure returns (uint8) {
        if (data.grid == 1 || data.alloy == 0) return 0; // No gradients for 1x1 or isolate tokens
        if (Utilities.random(data.seed, 'gradient', 10) < 8) return 0; // 80% have no gradient

        uint8 options = data.grid == 2 ? 2 : 7;
        uint8[7] memory GRADIENTS = data.grid == 2 ? [1, 2, 0, 0, 0, 0, 0]
                                  : data.grid == 4 ? [1, 2, 3, 4, 5, 8, 10]
                                                   : [1, 2, 4, 7, 8, 9, 16];

        return GRADIENTS[Utilities.random(data.seed, 'select_gradient', options)];
    }

    /// @dev Get the symbols for all slots on the grid.
    function getSymbols(Token memory data) public pure returns (Symbol[64] memory symbols) {
        uint8[7] memory forms          = [1, 2, 3, 4, 5, 8, 9]; // Seven distinct symbols.
        uint8[7] memory rotationCounts = [2, 4, 4, 2, 2, 0, 0]; // How often we rotate.

        (uint[64] memory colorIndexes, Color[64] memory colors) = getColors(data);
        uint[64] memory formColorMap;

        for (uint i = 0; i < data.count; i++) {
            symbols[i].colorIdx = colorIndexes[i];
            symbols[i].color = colors[i];

            uint formIdx = getFormIdx(data, i);
            uint form = forms[formIdx];
            if (data.mapColors) {
                (formColorMap, form) = setGetMap(formColorMap, symbols[i].colorIdx, form);
            }
            symbols[i].form = form;

            symbols[i].isInfinity = symbols[i].form % 2 == 0;
            symbols[i].formWidth = symbols[i].isInfinity ? 400 : 200;

            uint rotationIncrement = symbols[i].isInfinity ? 45 : 90;
            uint rotations = rotationCounts[formIdx] > 0
                ? Utilities.random(
                    data.seed,
                    string.concat('rotation', str(i)),
                    rotationCounts[formIdx]
                )
                : 0;
            symbols[i].rotation = str(rotations * rotationIncrement);
        }
    }

    /// @dev Get shape of a given symbol of a token.
    function getFormIdx(Token memory data, uint i) public pure returns (uint) {
        if (data.seed == 0) return 5; // Genesis token is an infinity flower.

        uint random = Utilities.random(data.seed, string.concat('form', str(i)), 10);
        if (random == 0) return 0; // 10% Single Loops

        uint8[3] memory common = [1, 3, 5]; // Infinities
        uint8[3] memory uncommon = [2, 4, 6]; // Loops

        uint idx = Utilities.random(data.seed, string.concat('form-idx', str(i)), 3);
        return random < 8 ? common[idx] : uncommon[idx];
    }

    /// @dev Get all colors available to choose from.
    function allColors() public pure returns (Color[68] memory colors) {
        // One "Void" color with 4 shades.
        uint8[4] memory voidLums = [16, 32, 80, 96];
        for (uint i = 0; i < SHADES; i++) {
            colors[i].h = 270;
            colors[i].s = 8;
            colors[i].l = voidLums[i];
        }

        // 16 distinct colors with 4 shades each.
        uint8 count = 4*4;
        uint16 startHue = 256;
        uint8[4] memory lums = [56, 60, 64, 72];
        for (uint8 i = 0; i < 16; i++) {
            uint16 hue = (startHue + 360 * i / count) % 360;

            for(uint8 e = 0; e < 4; e++) {
                uint8 idx = 4+i*4+e;
                colors[idx].h = hue;
                colors[idx].s = 88;
                colors[idx].l = lums[e];
            }
        }
    }

    /// @dev Get the color variations for a specific token. Compute gradients / skittles.
    function getColors(Token memory data) public pure returns (
        uint[64] memory colorIndexes,
        Color[64] memory colors
    ) {
        Color[68] memory all = allColors();
        uint[68] memory options = getColorOptions(data);
        bool reverse = Utilities.random(data.seed, 'reverse', 2) > 0;

        for (uint i = 0; i < data.count; i++) {
            colorIndexes[i] = (
                data.gradient > 0
                    ? getGradientColor(data, i)
                    : getRandomColor(data, i)
            ) % 68;

            uint idx = reverse ? data.count - 1 - i : i;

            colors[idx] = all[options[colorIndexes[i]]];

            // Paradoxical, i know. Opepen your eyes. All one. Common fate.
            if (data.light) colors[idx].rendered = '#080808';
        }
    }

    /// @dev Get the colors to choose from for a given token.
    function getColorOptions(Token memory data) public pure returns (uint[68] memory options) {
        uint count = Utilities.max(1, data.alloy);
        for (uint element = 0; element < count; element++) {
            uint idx = element * SHADES;

            uint chosen = data.continuous && element > 0
                // Increment previous by one for a continuous band.
                ? (options[idx - 1] / SHADES + 1) % ELEMENTS
                // Random selection for hard shifts in color.
                : Utilities.random(data.seed, string.concat('element', str(element)), ELEMENTS);

            uint chosenIdx = chosen * SHADES;

            for (uint shade = 0; shade < SHADES; shade++) {
                options[idx + shade] = chosenIdx + shade;
            }
        }
    }

    /// @dev Compute the gradient colors for a gradient token.
    function getGradientColor(Token memory data, uint i) public pure returns (uint) {
        uint offset;
        if (data.gradient == 3 || data.gradient == 7) {
            // Fix angled gradient y-shift.
            offset = data.grid + 1;
        }

        return ((offset + i) * data.gradient * data.band / data.count) % data.band;
    }

    /// @dev Compute colors for a skittle tokens.
    function getRandomColor(Token memory data, uint i) public pure returns (uint) {
        uint8 max = Utilities.max(SHADES, data.band);
        string memory key = data.alloy == 0 ? '0' : str(i);
        return Utilities.random(data.seed, string.concat('random_color_', key), max);
    }

    /// @dev Helper to keep track of a key value store in memory.
    function setGetMap(
        uint[64] memory map, uint key, uint value
    ) public pure returns (uint[64] memory, uint) {
        uint k = key % 64;

        if (map[k] == 0) {
            map[k] = value;
        }

        return (map, map[k]);
    }

    /// @dev Uint to string helper.
    function str(uint n) public pure returns (string memory) {
        return Utilities.uint2str(n);
    }
}