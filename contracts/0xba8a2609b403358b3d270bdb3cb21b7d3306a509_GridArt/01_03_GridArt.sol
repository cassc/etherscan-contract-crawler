//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IHoneycombs.sol";
import "./Utilities.sol";

/**
@title  GridArt
@notice Generates the grid for a given Honeycomb.
*/
library GridArt {
    enum HEXAGON_TYPE { FLAT, POINTY } // prettier-ignore
    enum SHAPE { TRIANGLE, DIAMOND, HEXAGON, RANDOM } // prettier-ignore

    /// @dev The paths for a 72x72 px hexagon.
    function getHexagonPath(uint8 pathType) public pure returns (string memory path) {
        if (pathType == uint8(HEXAGON_TYPE.FLAT)) {
            return "M22.2472 7.32309L4.82457 37.5C3.93141 39.047 3.93141 40.953 4.82457 42.5L22.2472 72.6769C23.1404 74.2239 24.791 75.1769 26.5774 75.1769H61.4226C63.209 75.1769 64.8596 74.2239 65.7528 72.6769L83.1754 42.5C84.0686 40.953 84.0686 39.047 83.1754 37.5L65.7528 7.32309C64.8596 5.77608 63.209 4.82309 61.4226 4.82309H26.5774C24.791 4.82309 23.1404 5.77608 22.2472 7.32309Z"; // prettier-ignore
        } else if (pathType == uint8(HEXAGON_TYPE.POINTY)) {
            return "M72.6769 22.2472L42.5 4.82457C40.953 3.93141 39.047 3.93141 37.5 4.82457L7.32309 22.2472C5.77608 23.1404 4.82309 24.791 4.82309 26.5774V61.4226C4.82309 63.209 5.77608 64.8596 7.32309 65.7528L37.5 83.1754C39.047 84.0686 40.953 84.0686 42.5 83.1754L72.6769 65.7528C74.2239 64.8596 75.1769 63.209 75.1769 61.4226V26.5774C75.1769 24.791 74.2239 23.1404 72.6769 22.2472Z"; // prettier-ignore
        }
    }

        /// @dev Get hexagon from given grid and hexagon properties.
    /// @param grid The grid metadata.
    /// @param xIndex The x index in the grid.
    /// @param yIndex The y index in the grid.
    /// @param gradientId The gradient id for the hexagon.
    function getUpdatedHexagonsSvg(
        IHoneycombs.Grid memory grid,
        uint16 xIndex,
        uint16 yIndex,
        uint16 gradientId
    ) public pure returns (bytes memory) {
        uint16 x = grid.gridX + xIndex * grid.columnDistance;
        uint16 y = grid.gridY + yIndex * grid.rowDistance;

        // prettier-ignore
        return abi.encodePacked(grid.hexagonsSvg, abi.encodePacked(
            '<use href="#hexagon" stroke="url(#gradient', Utilities.uint2str(gradientId), ')" ',
                'x="', Utilities.uint2str(x), '" y="', Utilities.uint2str(y), '"',
            '/>'
        ));
    }

    /// @dev Add positioning to the grid (for centering on canvas).
    /// @dev Note this function appends attributes to grid object, so returned object has original grid + positioning.
    /// @param honeycomb The honeycomb data used for rendering.
    /// @param grid The grid metadata.
    function addGridPositioning(
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Grid memory grid
    ) public pure returns (IHoneycombs.Grid memory) {
        // Compute grid properties.
        grid.rowDistance = ((3 * honeycomb.canvas.hexagonSize) / 4) + 7; // 7 is a relatively arbitrary buffer
        grid.columnDistance = honeycomb.canvas.hexagonSize / 2 - 1;
        uint16 gridHeight = honeycomb.canvas.hexagonSize + 7 + ((grid.rows - 1) * grid.rowDistance);
        uint16 gridWidth = grid.longestRowCount * (honeycomb.canvas.hexagonSize - 2);

        /**
         * Swap variables if it is a flat top hexagon (this math assumes pointy top as default). Rotating a flat top
         * hexagon 90 degrees clockwise results in a pointy top hexagon. This effectively swaps the x and y axis.
         */
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            (grid.rowDistance, grid.columnDistance) = Utilities.swap(grid.rowDistance, grid.columnDistance);
            (gridWidth, gridHeight) = Utilities.swap(gridWidth, gridHeight);
        }

        // Compute grid positioning.
        grid.gridX = (honeycomb.canvas.size - gridWidth) / 2;
        grid.gridY = (honeycomb.canvas.size - gridHeight) / 2;

        return grid;
    }

    /// @dev Get the honeycomb grid for a random shape.
    /// @dev Note: can only be called for pointy tops (flat tops are not supported as they would be redundant).
    /// @param honeycomb The honeycomb data used for rendering.
    function getRandomGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 1 to honeycomb.canvas.maxHexagonsPerline.
        grid.rows = uint8(Utilities.random(honeycomb.seed, "rows", honeycomb.canvas.maxHexagonsPerLine) + 1);

        // Get random hexagons in each row from 1 to honeycomb.canvas.maxHexagonsPerLine - 1.
        uint8[] memory hexagonsInRow = new uint8[](grid.rows);
        for (uint8 i; i < grid.rows; ) {
            hexagonsInRow[i] =
                uint8(Utilities.random(
                    honeycomb.seed,
                    abi.encodePacked("hexagonsInRow", Utilities.uint2str(i)),
                    honeycomb.canvas.maxHexagonsPerLine - 1
                ) + 1); // prettier-ignore
            grid.longestRowCount = Utilities.max(hexagonsInRow[i], grid.longestRowCount);

            unchecked {
                ++i;
            }
        }

        // Determine positioning of entire grid, which is based on the longest row.
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        int8 lastRowEvenOdd = -1; // Helps avoid overlapping hexagons: -1 = unset, 0 = even, 1 = odd
        // Create random grid. Only working with pointy tops for simplicity.
        for (uint8 i; i < grid.rows; ) {
            uint8 firstX = grid.longestRowCount - hexagonsInRow[i];

            // Increment firstX if last row's evenness/oddness is same as this rows and update with current.
            if (lastRowEvenOdd == int8(firstX % 2)) ++firstX;
            lastRowEvenOdd = int8(firstX % 2);

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow[i]; ) {
                uint8 xIndex = firstX + (j * 2);
                grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        grid.totalGradients = grid.rows;
        return grid;
    }

    /// @dev Get the honeycomb grid for a hexagon shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getHexagonGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 3 to honeycomb.canvas.maxHexagonsPerLine, only odd.
        grid.rows = uint8(
            Utilities.random(honeycomb.seed, "rows", (honeycomb.canvas.maxHexagonsPerLine / 2) - 1) * 2 + 3
        );

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
            grid.totalGradients = grid.rows;

            for (uint8 i; i < grid.rows; ) {
                // Compute hexagons in row.
                uint8 hexagonsInRow = grid.rows - Utilities.absDiff(grid.rows / 2, i);

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (grid.rows - hexagonsInRow) + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;
            uint8 halfRows = grid.rows / 2;

            for (uint8 i; i < flatTopRows; ) {
                // Determine hexagons in row.
                uint8 hexagonsInRow;
                if (i <= grid.rows / 2) {
                    // ascending, i.e. rows = 1 2 3 4 5 when rows = 5
                    hexagonsInRow = i + 1;
                } else if (i < flatTopRows - halfRows - 1) {
                    // alternate between rows / 2 + 1 and rows / 2 every other row
                    hexagonsInRow = (halfRows + i) % 2 == 0 ? halfRows + 1 : halfRows;
                } else {
                    // descending, i.e. rows = 5, 4, 3, 2, 1 when rows = 5
                    hexagonsInRow = flatTopRows - i;
                }

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (grid.rows - hexagonsInRow) - halfRows + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        return grid;
    }

    /// @dev Get the honeycomb grid for a diamond shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getDiamondGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 3 to honeycomb.canvas.maxHexagonsPerLine, only odd.
        grid.rows = uint8(
            Utilities.random(honeycomb.seed, "rows", (honeycomb.canvas.maxHexagonsPerLine / 2) - 1) * 2 + 3
        );

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows / 2 + 1;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create diamond grid. Both flat top and pointy top result in the same grid, so no need to check hexagon type.
        for (uint8 i; i < grid.rows; ) {
            // Determine hexagons in row. Pattern is ascending/descending sequence, i.e 1 2 3 2 1 when rows = 5.
            uint8 hexagonsInRow = i < grid.rows / 2 ? i + 1 : grid.rows - i;
            uint8 firstXInRow = i < grid.rows / 2 ? grid.rows / 2 - i : i - grid.rows / 2;

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow; ) {
                uint8 xIndex = firstXInRow + (j * 2);
                grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        grid.totalGradients = grid.rows;
        return grid;
    }

    /// @dev Get the honeycomb grid for a triangle shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getTriangleGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 2 to honeycomb.canvas.maxHexagonsPerLine.
        grid.rows = uint8(Utilities.random(honeycomb.seed, "rows", honeycomb.canvas.maxHexagonsPerLine - 1) + 2);

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
            grid.totalGradients = grid.rows;

            // Iterate through rows - will only be north/south facing (design).
            for (uint8 i; i < grid.rows; ) {
                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < i + 1; ) {
                    uint8 xIndex = grid.rows - 1 - i + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;

            // Iterate through rows - will only be west/east facing (design).
            for (uint8 i; i < flatTopRows; ) {
                // Determine hexagons in row. First half is ascending. Second half is descending.
                uint8 hexagonsInRow;
                if (i <= flatTopRows / 2) {
                    // ascending with peak, i.e. rows = 1 1 2 2 3 when rows = 5
                    hexagonsInRow = i / 2 + 1;
                } else {
                    // descending with peak, i.e. rows = 2 2 1 1 when rows = 5
                    hexagonsInRow = ((flatTopRows - i - 1) / 2) + 1;
                }

                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (i % 2) + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        return grid;
    }

    /// @dev Generate the overall honeycomb grid, including the final svg.
    /// @dev Using double coordinates: https://www.redblobgames.com/grids/hexagons/#coordinates-doubled
    /// @param honeycomb The honeycomb data used for rendering.
    /// @return (bytes, uint8, uint8) The svg, totalGradients, and rows.
    function generateGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory, uint8, uint8) {
        // Partial grid object used to store supportive variables
        IHoneycombs.Grid memory gridData;

        // Get grid data based on shape.
        if (honeycomb.grid.shape == uint8(SHAPE.TRIANGLE)) {
            gridData = getTriangleGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.DIAMOND)) {
            gridData = getDiamondGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.HEXAGON)) {
            gridData = getHexagonGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.RANDOM)) {
            gridData = getRandomGrid(honeycomb);
        }

        // Generate grid svg.
        // prettier-ignore
        bytes memory svg = abi.encodePacked(
            '<g transform="scale(1) rotate(', 
                    Utilities.uint2str(honeycomb.grid.rotation) ,',', 
                    Utilities.uint2str(honeycomb.canvas.size / 2) ,',', 
                    Utilities.uint2str(honeycomb.canvas.size / 2), ')">',
                gridData.hexagonsSvg,
            '</g>'
        );

        return (svg, gridData.totalGradients, gridData.rows);
    }
}