// SPDX-License-Identifier: MIT

/// @title Ultra Sound Grid Renderer
/// @author -wizard

/// Inspired by @jackbutcher checks

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./interfaces/IUltraSoundGridRenderer.sol";
import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";
import {Array} from "./libs/Array.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract UltraSoundGridRenderer is IUltraSoundGridRenderer {
    using Strings for *;
    using Array for bytes[];

    /// @notice The contract responsible for holding symbols and pallets
    IUltraSoundParts public parts;

    constructor(IUltraSoundParts _part) {
        parts = _part;
    }

    uint16[80] gx = [
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896
    ];

    uint16[80] gy = [
        30,
        30,
        30,
        30,
        30,
        30,
        30,
        30,
        154,
        154,
        154,
        154,
        154,
        154,
        154,
        154,
        278,
        278,
        278,
        278,
        278,
        278,
        278,
        278,
        402,
        402,
        402,
        402,
        402,
        402,
        402,
        402,
        526,
        526,
        526,
        526,
        526,
        526,
        526,
        526,
        650,
        650,
        650,
        650,
        650,
        650,
        650,
        650,
        774,
        774,
        774,
        774,
        774,
        774,
        774,
        774,
        898,
        898,
        898,
        898,
        898,
        898,
        898,
        898,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146
    ];

    string[4] ss = ["124", "248", "372", "496"];

    string[2] mvbw = ["1050", "2342"];
    string[2] mvbh = ["1300", "2342"];
    string[2] ine = ["0", "646"];
    string[2] inf = ["0", "521"];

    function generateGrid(
        Symbol memory symbol,
        Override[] memory overrides,
        uint256 gradient,
        uint256 edition
    ) public view override returns (string memory) {
        bytes memory symbols;
        bytes[] memory symbolParts = new bytes[](80);
        bytes[] memory bp = abi.decode(
            parts.palettes(symbol.gridPalette),
            (bytes[])
        );
        bytes memory gradients = gradient > 0
            ? _generateGradient(gradient)
            : bytes("");

        if (symbol.id > 0) {
            symbols = abi.encodePacked(symbols, parts.symbols(symbol.id));
            symbolParts = _expandSymbols(symbol);
        }

        if (overrides.length > 0) {
            for (uint16 i = 0; i < overrides.length; i++) {
                Override memory o = overrides[i];
                symbols = abi.encodePacked(symbols, parts.symbols(o.symbols));
                symbolParts[o.positions] = (
                    abi.encodePacked(
                        _generateSymbolSVG(
                            o.symbols,
                            o.positions,
                            false,
                            o.colors,
                            o.size
                        )
                    )
                );
            }
        }

        return
            string.concat(
                "<svg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 ",
                string.concat(
                    mvbw[symbol.gridSize],
                    " ",
                    mvbh[symbol.gridSize],
                    "'>"
                ),
                string(abi.encodePacked(gradients, symbols)),
                "<defs>",
                "<rect id='square' width='124' height='124' ",
                "stroke='",
                string(bp[2]),
                "' />"
                "<filter id='b1' x='0' y='0' width='500' height='500' filterUnits='userSpaceOnUse'><feGaussianBlur stdDeviation='7' /></filter>"
                "<filter id='g1' x='-100%' y='-100%' width='400%' height='400%' filterUnits='objectBoundingBox' primitiveUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur stdDeviation='52 63' x='0%' y='0%' width='100%' height='100%' in='SourceGraphic' result='blur'/></filter><filter id='g2' x='-100%' y='-100%' width='400%' height='400%' filterUnits='objectBoundingBox' primitiveUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur stdDeviation='24 31' x='0%' y='0%' width='100%' height='100%' in='SourceGraphic' result='blur'/></filter>",
                "</defs>",
                // Outer
                string.concat(
                    "<rect width='2342' height='2342' fill='",
                    string(bp[0]),
                    symbol.gridSize == 0 ? "' visibility='hidden' />" : "' />"
                ),
                // Main
                string.concat(
                    "<g transform='matrix(1,0,0,1,",
                    ine[symbol.gridSize],
                    ",",
                    inf[symbol.gridSize],
                    ")'>"
                ),
                // Inner
                string.concat(
                    "<rect width='1050' height='1300' fill='",
                    string(bp[1]),
                    "' />"
                ),
                string.concat("<g id='grid'>", string(_grid()), "</g>"),
                string(
                    abi.encodePacked(
                        "<g id='symbols'>",
                        symbolParts.join(),
                        edition > 0 ? _edition(edition) : bytes(""),
                        "</g>"
                    )
                ),
                "</g>",
                "</svg>"
            );
    }

    function _grid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint256 i = 0; i < 10; i++) {
            for (uint256 j = 0; j < 8; j++) {
                grid = abi.encodePacked(
                    grid,
                    "<use href='#square' x='",
                    uint16(30 + j * 124).toString(),
                    "' y='",
                    uint16(30 + i * 124).toString(),
                    "'/>"
                );
            }
        }
        return grid;
    }

    function _edition(uint256 edition)
        public
        pure
        returns (bytes memory editionBytes)
    {
        editionBytes = abi.encodePacked(
            "<rect x='675' y='1179' width='294' height='51' fill='#1C2234'/><text fill='#9497B3' font-family='Inter, Arial, Helvetica, sans-serif' font-size='38px' font-weight='300' text-anchor='end' x='973' y='1221'>EDITION #",
            edition.toString(),
            "</text>"
        );
    }

    function _expandSymbols(Symbol memory symbol)
        internal
        view
        returns (bytes[] memory)
    {
        uint16 q = parts.quantities(symbol.level);
        bytes[] memory symbolParts = new bytes[](80);
        bytes[] memory symbolColors = abi.decode(
            parts.palettes(symbol.palette),
            (bytes[])
        );

        if (q == 0) return symbolParts;
        if (q == 80) {
            {
                for (uint16 i = 0; i < 80; i++) {
                    symbolParts[i] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            i,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            0
                        )
                    );
                }
            }
        } else if (q == 40) {
            {
                uint16 k = 0;
                bool pad = false;
                for (uint16 i = 0; i < 10; i++) {
                    for (uint16 j = 0; j < 4; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                0
                            )
                        );
                        k = k + 2;
                    }
                    pad = !pad;
                    k = 8 * (i + 1);
                    if (pad == true) k++;
                }
            }
        } else if (q == 20) {
            {
                uint16 k = 0;
                for (uint16 i = 0; i < 5; i++) {
                    for (uint16 j = 0; j < 4; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                1
                            )
                        );
                        k = k + 2;
                    }
                    k = 16 * (i + 1);
                }
            }
        } else if (q == 10) {
            {
                uint16 k = 2;
                for (uint16 i = 1; i < 6; i++) {
                    for (uint256 j = 0; j < 2; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                1
                            )
                        );
                        k = k + 2;
                    }
                    k = 16 * i + 2;
                }
            }
        } else if (q == 5) {
            {
                uint16 k = 3;
                for (uint16 i = 1; i < 6; i++) {
                    symbolParts[k] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            k,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            1
                        )
                    );
                    k = 16 * i + 3;
                }
            }
        } else if (q == 4) {
            {
                for (uint16 i = 32; i < 39; i = i + 2) {
                    symbolParts[i] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            i,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            1
                        )
                    );
                }
            }
        } else {
            {
                symbolParts[35] = abi.encodePacked(
                    _generateSymbolSVG(
                        symbol.id,
                        35,
                        false,
                        string(symbolColors[1 % symbolColors.length]),
                        1
                    )
                );
            }
        }
        return symbolParts;
    }

    function _generateSymbolSVG(
        uint16 symbol,
        uint16 position,
        bool opaque,
        string memory fill,
        uint256 size
    ) internal view returns (string memory) {
        return
            string.concat(
                "<use href='#",
                symbol.toString(),
                "' x='",
                gx[position].toString(),
                "' y='",
                gy[position].toString(),
                "' fill='",
                fill,
                "' opacity='",
                _opacity(opaque ? position : 0),
                "' ",
                string.concat("height='", ss[size], "' width='", ss[size], "'"),
                " />"
            );
    }

    function _generateGradient(uint256 gradient)
        internal
        view
        returns (bytes memory)
    {
        bytes[] memory g = abi.decode(parts.gradients(gradient), (bytes[]));
        return
            abi.encodePacked(
                "<linearGradient id='lg1' gradientUnits='objectBoundingBox' x1='0' y1='0' x2='1' y2='1'><stop offset='0'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[0]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='.5'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[1]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='1'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[2]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><animateTransform attributeName='gradientTransform' type='rotate' from='0 .5 .5' to='360 .5 .5' dur='20s' repeatCount='indefinite'/></linearGradient>",
                "<linearGradient id='lg2' gradientUnits='objectBoundingBox' x1='0' y1='1' x2='1' y2='1'><stop offset='0'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[0]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='1'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[1]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><animateTransform attributeName='gradientTransform' type='rotate' values='360 .5 .5;0 .5 .5' class='ignore' dur='10s' repeatCount='indefinite'/></linearGradient>"
            );
    }

    function _opacity(uint16 p) internal pure returns (string memory) {
        uint16 o = 0;
        if (p == 0) return "1";
        else if (p <= 60) o = uint16(65 - p);
        else if (p <= 71) o = 5;

        if (o > 9) return string.concat("0.", o.toString());
        if (o <= 9) return string.concat("0.0", o.toString());
        return "1";
    }
}