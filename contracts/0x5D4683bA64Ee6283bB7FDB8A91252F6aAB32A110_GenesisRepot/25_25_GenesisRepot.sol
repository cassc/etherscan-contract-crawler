//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../VarietyRepot.sol';
import '../../Randomize.sol';

/// @title Genesis
/// @author Simon Fremaux (@dievardump)
contract GenesisRepot is VarietyRepot {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    using Randomize for Randomize.Random;

    enum ColorTypes {
        AUTO,
        BLACK_WHITE,
        FULL
    }

    struct Grid {
        uint8 cols;
        uint8 rows;
        uint16 cellSize;
        uint16 offset;
        uint16 shapes;
        uint16 minContentSize;
        uint16 maxContentSize;
        bool shadowed;
        bool degen;
        bool dark;
        bool full;
        ColorTypes colorType;
        uint256 tokenId;
        uint256 baseSeed;
        string[5] palette;
    }

    struct CellData {
        uint16 x;
        uint16 y;
        uint16 cx;
        uint16 cy;
        uint16 index;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    /// @param oldContract_ the oldContract for migration
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_,
        address oldContract_
    )
        VarietyRepot(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            sower_,
            oldContract_
        )
    {}

    /// @dev internal function to get the name. Should be overrode by actual Variety contract
    /// @param tokenId the token to get the name of
    /// @return seedlingName the token name
    function _getName(uint256 tokenId)
        internal
        view
        override
        returns (string memory seedlingName)
    {
        seedlingName = names[tokenId];
        if (bytes(seedlingName).length == 0) {
            seedlingName = string(
                abi.encodePacked('Genesis.sol #', tokenId.toString())
            );
        }
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function _render(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        Randomize.Random memory random = Randomize.Random({
            seed: uint256(seed),
            offsetBit: 0
        });

        uint256 result = random.next(0, 100);

        Grid memory grid = Grid({
            cols: 8,
            rows: 8,
            cellSize: 140,
            offset: 40,
            shapes: 0,
            minContentSize: 0,
            maxContentSize: 0,
            colorType: result <= 80 // auto 80%, 10% B&W, 10% FULL Color
                ? ColorTypes.AUTO
                : (result <= 90 ? ColorTypes.BLACK_WHITE : ColorTypes.FULL),
            dark: random.next(0, 100) < 10, // 10% dark mode
            degen: random.next(0, 100) < 10, // 10% degen (grid offseted)
            shadowed: random.next(0, 100) < 3, // 3% with shadow
            full: random.next(0, 100) < 1, // 1% full genesis
            palette: _getPalette(random),
            tokenId: tokenId,
            baseSeed: uint256(seed)
        });

        // shadowed + full black white is not pleasing to the eye with the wrong first color
        if (grid.shadowed && grid.colorType == ColorTypes.BLACK_WHITE) {
            grid.palette[0] = '#99B898';
        }

        result = random.next(0, 16);
        if (result < 1) {
            grid.cols = 3;
            grid.rows = 3;
            grid.cellSize = 146;
            grid.offset = 381;
        } else if (result < 3) {
            grid.cols = 4;
            grid.rows = 4;
            grid.offset = 320;
        } else if (result < 7) {
            grid.cols = 6;
            grid.rows = 6;
            grid.offset = 180;
        } else if (result < 11) {
            grid.cols = 7;
            grid.rows = 7;
            grid.cellSize = 146;
            grid.offset = 89;
        }

        grid.minContentSize = (grid.cellSize * 2) / 10;
        grid.maxContentSize = (grid.cellSize * 6) / 10;

        bytes memory svg = abi.encodePacked(
            'data:application/json;utf8,{"name":"',
            _getName(tokenId),
            '","image":"data:image/svg+xml;utf8,',
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1200 1200' width='1200' height='1200'>",
            _renderGrid(grid, random),
            _renderCells(grid, random)
        );

        svg = abi.encodePacked(
            svg,
            "<text style='font: bold 11px sans-serif;' text-anchor='end' x='",
            (1200 - grid.offset).toString(),
            "' y='",
            (1220 - grid.offset).toString(),
            "'",
            grid.dark ? " fill='#fff'" : '',
            '>#',
            tokenId.toString(),
            '</text>',
            '</svg>"'
        );

        svg = abi.encodePacked(
            svg,
            ',"license":"Full ownership with unlimited commercial rights.","creator":"@dievardump"',
            ',"description":"Genesis: A seed, some love, that',
            "'s",
            'all it takes.\\n\\nGenesis is the first of the [sol]Seedlings, an experiment of art and collectible NFTs 100% generated with Solidity.\\nby @dievardump\\n\\nLicense: Full ownership with unlimited commercial rights.\\n\\nMore info at https://solSeedlings.art"'
        );

        return
            string(
                abi.encodePacked(
                    svg,
                    ',"properties":{"Colors":"',
                    grid.colorType == ColorTypes.AUTO
                        ? 'Auto'
                        : (
                            grid.colorType == ColorTypes.BLACK_WHITE
                                ? 'Black & White'
                                : 'Full color'
                        ),
                    '","Grid":"',
                    grid.degen ? 'Degen' : 'Normal',
                    '","Mode":"',
                    grid.dark ? 'Dark' : 'Light',
                    '","Rendering":"',
                    grid.shadowed ? 'Ghost' : 'Normal',
                    '","Size":"',
                    abi.encodePacked(
                        grid.cols.toString(),
                        '*',
                        grid.rows.toString()
                    ),
                    '"',
                    grid.shapes == grid.rows * grid.cols
                        ? ',"Bonus":"Full Board"'
                        : '',
                    '}}'
                )
            );
    }

    function _renderGrid(Grid memory grid, Randomize.Random memory random)
        internal
        pure
        returns (bytes memory svg)
    {
        uint256 offsetMore = grid.degen ? grid.cellSize / 2 : 0;
        svg = abi.encodePacked(
            "<defs><pattern id='genesis-grid-",
            grid.baseSeed.toString(),
            "' x='",
            (grid.offset + offsetMore).toString(),
            "' y='",
            (grid.offset + offsetMore).toString(),
            "' width='",
            grid.cellSize.toString(),
            "' height='",
            grid.cellSize.toString(),
            "' patternUnits='userSpaceOnUse'>"
        );

        svg = abi.encodePacked(
            svg,
            "<path d='M ",
            grid.cellSize.toString(),
            ' 0 L 0 0 0 ',
            grid.cellSize.toString(),
            "' fill='none' stroke='",
            grid.dark ? '#fff' : '#000',
            "' stroke-width='4'/></pattern>"
        );

        if (!grid.dark) {
            svg = abi.encodePacked(
                svg,
                "<linearGradient id='genesis-gradient-",
                grid.baseSeed.toString(),
                "' gradientTransform='rotate(",
                random.next(0, 360).toString(),
                ")'><stop offset='0%' stop-color='",
                _randomHSLA(random.next(10, 45), random),
                "'/><stop offset='100%' stop-color='",
                _randomHSLA(random.next(10, 45), random),
                "' /></linearGradient>"
            );
        }

        svg = abi.encodePacked(
            svg,
            "</defs><rect width='100%' height='100%' fill='#fff' />",
            grid.dark
                ? "<rect width='100%' height='100%' fill='#000' />"
                : string(
                    abi.encodePacked(
                        "<rect width='100%' height='100%' fill='url(#genesis-gradient-",
                        grid.baseSeed.toString(),
                        ")' />"
                    )
                ),
            "<rect x='",
            grid.offset.toString(),
            "' y='",
            grid.offset.toString(),
            "' width='",
            (1200 - grid.offset * 2).toString(),
            "' height='",
            (1200 - grid.offset * 2).toString(),
            "' fill='url(#genesis-grid-",
            grid.baseSeed.toString(),
            ")' stroke='",
            grid.dark ? '#fff' : '#000',
            "' stroke-width='4' />"
        );
    }

    function _getCellData(
        uint16 x,
        uint16 y,
        Grid memory grid
    ) internal pure returns (CellData memory) {
        uint16 left = x * grid.cellSize;
        uint16 top = y * grid.cellSize;
        return
            CellData({
                index: y * grid.cols + x,
                x: left,
                y: top,
                cx: left + grid.cellSize / 2,
                cy: top + grid.cellSize / 2
            });
    }

    function _renderCells(Grid memory grid, Randomize.Random memory random)
        internal
        pure
        returns (bytes memory)
    {
        uint256 result;
        CellData memory cellData;
        bytes memory cells = abi.encodePacked(
            '<g ',
            grid.shadowed
                ? string(
                    abi.encodePacked(
                        "style='filter: drop-shadow(16px 16px 20px ",
                        grid.palette[0],
                        ") invert(80%);'"
                    )
                )
                : '',
            " stroke-width='4' stroke-linecap='round' transform='translate(",
            grid.offset.toString(),
            ',',
            grid.offset.toString(),
            ")'>"
        );

        for (uint16 y; y < grid.rows; y++) {
            for (uint16 x; x < grid.cols; x++) {
                cellData = _getCellData(x, y, grid);
                result = random.next(0, grid.full ? 10 : 16);
                if (result <= 1) {
                    // 0 & 1
                    cells = abi.encodePacked(
                        cells,
                        _getCircle(
                            result != 0,
                            random.next(
                                grid.minContentSize / 2,
                                grid.maxContentSize / 2
                            ),
                            cellData,
                            grid,
                            random
                        )
                    );
                    grid.shapes++;
                } else if (result <= 3) {
                    // 2 & 3
                    uint256 size = random.next(
                        grid.minContentSize,
                        grid.maxContentSize
                    );

                    cells = abi.encodePacked(
                        cells,
                        _getSquare(result != 5, size, cellData, grid, random)
                    );
                    grid.shapes++;
                } else if (result == 4) {
                    // 4
                    cells = abi.encodePacked(
                        cells,
                        _getSquare(
                            true,
                            grid.minContentSize,
                            cellData,
                            grid,
                            random
                        ),
                        _getSquare(
                            false,
                            grid.maxContentSize,
                            cellData,
                            grid,
                            random
                        )
                    );
                    grid.shapes++;
                } else if (result == 5) {
                    uint256 half = grid.maxContentSize / 2;
                    bytes memory color = _getColor(false, random, grid);
                    cells = abi.encodePacked(
                        cells,
                        _getLine(
                            cellData.cx - half,
                            cellData.cy - half,
                            cellData.cx + half,
                            cellData.cy + half,
                            color,
                            false
                        )
                    );
                    grid.shapes++;
                } else if (result <= 8) {
                    uint256 half = result >= 7
                        ? grid.minContentSize / 2
                        : grid.maxContentSize / 2;
                    bool strong = result >= 7;
                    bytes memory color = _getColor(false, random, grid);
                    bytes memory square;
                    if (result == 8) {
                        square = _getSquare(
                            false,
                            grid.maxContentSize,
                            cellData,
                            grid,
                            random
                        );
                    }
                    cells = abi.encodePacked(
                        cells,
                        square,
                        _getLine(
                            cellData.cx - half,
                            cellData.cy - half,
                            cellData.cx + half,
                            cellData.cy + half,
                            color,
                            strong
                        ),
                        _getLine(
                            cellData.cx + half,
                            cellData.cy - half,
                            cellData.cx - half,
                            cellData.cy + half,
                            color,
                            strong
                        )
                    );
                    grid.shapes++;
                } else if (result < 10) {
                    cells = abi.encodePacked(
                        cells,
                        _getCircle(
                            result == 8,
                            grid.maxContentSize / 2,
                            cellData,
                            grid,
                            random
                        ),
                        _getCircle(
                            true,
                            grid.minContentSize / 2,
                            cellData,
                            grid,
                            random
                        )
                    );
                    grid.shapes++;
                }
            }
        }

        return abi.encodePacked(cells, '</g>');
    }

    function _getPalette(Randomize.Random memory random)
        internal
        pure
        returns (string[5] memory)
    {
        uint256 randPalette = random.next(0, 6);
        if (randPalette == 0) {
            return ['#F8B195', '#F67280', '#C06C84', '#6C5B7B', '#355C7D'];
        } else if (randPalette == 1) {
            return ['#173F5F', '#20639B', '#3CAEA3', '#F6D55C', '#ED553B'];
        } else if (randPalette == 2) {
            return ['#A7226E', '#EC2049', '#F26B38', '#F7DB4F', '#2F9599'];
        } else if (randPalette == 3) {
            return ['#99B898', '#FECEAB', '#FF847C', '#E84A5F', '#2A363B'];
        } else if (randPalette == 4) {
            return ['#FFADAD', '#FDFFB6', '#9BF6FF', '#BDB2FF', '#FFC6FF'];
        } else {
            return ['#EA698B', '#C05299', '#973AA8', '#6D23B6', '#571089'];
        }
    }

    function _getColor(
        bool fill,
        Randomize.Random memory random,
        Grid memory grid
    ) internal pure returns (bytes memory) {
        string memory color = grid.dark ? '#fff' : '#000';

        if (
            // if not full black & white
            ColorTypes.BLACK_WHITE != grid.colorType &&
            // and if either full color OR 1 out of 5, colorize
            (ColorTypes.FULL == grid.colorType || random.next(0, 5) < 1)
        ) {
            color = grid.palette[random.next(0, grid.palette.length)];
        }

        if (!fill) {
            return abi.encodePacked(" stroke='", color, "' fill='none' ");
        }
        return abi.encodePacked(" fill='", color, "' stroke='none' ");
    }

    function _randomHSLA(uint256 maxOpacity, Randomize.Random memory random)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                'hsla(',
                random.next(0, 255).toString(),
                ',',
                random.next(0, 100).toString(),
                '%,',
                random.next(40, 100).toString(),
                '%,0.',
                maxOpacity < 10 ? '0' : '',
                maxOpacity.toString(),
                ')'
            );
    }

    function _getCircle(
        bool fill,
        uint256 size,
        CellData memory cellData,
        Grid memory grid,
        Randomize.Random memory random
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<circle cx='",
                cellData.cx.toString(),
                "' cy='",
                cellData.cy.toString(),
                "' r='",
                size.toString(),
                "'",
                _getColor(fill, random, grid),
                '/>'
            );
    }

    function _getSquare(
        bool fill,
        uint256 size,
        CellData memory cellData,
        Grid memory grid,
        Randomize.Random memory random
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect x='",
                (cellData.cx - size / 2).toString(),
                "' y='",
                (cellData.cy - size / 2).toString(),
                "' width='",
                size.toString(),
                "' height='",
                size.toString(),
                "'",
                _getColor(fill, random, grid),
                '/>'
            );
    }

    function _getLine(
        uint256 x0,
        uint256 y0,
        uint256 x1,
        uint256 y1,
        bytes memory color,
        bool strong
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<path d='M ",
                x0.toString(),
                ' ',
                y0.toString(),
                ' L ',
                x1.toString(),
                ' ',
                y1.toString(),
                "'",
                color,
                '',
                strong ? "stroke-width='8'" : '',
                '/>'
            );
    }
}