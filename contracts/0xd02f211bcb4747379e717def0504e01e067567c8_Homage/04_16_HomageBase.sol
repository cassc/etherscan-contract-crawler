// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract HomageBase {
    using Strings for uint256;

    string constant ANIMATE_START = '<animate attributeName="';
    string[][] private RECT_ATTRIBUTES = [
        [
            "100", // width = height
            "0", // x
            "0", // y
            ".34 .36 .67 .69", // keySplines
            "71.4", // width, height to
            "14.3", // x to
            "21.45" // y to
        ],
        [
            "71.4", // width = height
            "14.3", // x
            "21.45", // y
            ".34 .37 .68 .7", // keySplines
            "46.52", // width, height to
            "26.74", // x to
            "40.11" // y to
        ],
        [
            "46.52", // width = height
            "26.74", // x
            "40.11", // y
            ".35 .38 .68 .71", // keySplines
            "25.48", // width, height to
            "37.26", // x to
            "55.89" // y to
        ],
        [
            "25.48", // width = height
            "37.26", // x
            "55.89", // y
            ".36 .41 .69 .75", // keySplines
            "9.07", // width, height to
            "45.46", // x to
            "68.2" // y to
        ]
    ];
    string constant ANIMATE_END =
        '" dur="3.71s" repeatCount="indefinite" calcMode="spline" />';

    function _interpolateColor(
        int256 from,
        int256 to,
        int256 ratio
    ) internal pure returns (int256) {
        // Ratio is 1e18
        int256 r = ((to >> 16) - (from >> 16)) * ratio + (from >> 16) * 1e18;
        if ((r / 1e17) % 10 >= 5) {
            r = r / 1e18 + 1;
        } else {
            r = r / 1e18;
        }
        int256 g = (((to >> 8) & 255) - ((from >> 8) & 255)) *
            ratio +
            ((from >> 8) & 255) *
            1e18;
        if ((g / 1e17) % 10 >= 5) {
            g = g / 1e18 + 1;
        } else {
            g = g / 1e18;
        }
        int256 b = ((to & 255) - (from & 255)) * ratio + (from & 255) * 1e18;
        if ((b / 1e17) % 10 >= 5) {
            b = b / 1e18 + 1;
        } else {
            b = b / 1e18;
        }
        return int256((r << 16) + (g << 8) + b);
    }

    function _renderRect(
        uint256 i,
        string memory c0,
        string memory c1
    ) internal view returns (bytes memory) {
        // <animate attributeName="fill" values="#6f00a4; #463fa1" keyTimes="0; 1" dur="3.71s" repeatCount="indefinite" />
        bytes memory last = i == 3
            ? bytes("")
            : abi.encodePacked(
                ANIMATE_START,
                'fill" values="#',
                c0,
                i == 2 ? abi.encodePacked("; #", c1) : bytes(""),
                "; #",
                c1,
                '" keyTimes="0;',
                i == 2 ? ".69;" : "",
                '1" dur="3.71s" repeatCount="indefinite" />'
            );
        return
            abi.encodePacked(
                // parent rect
                abi.encodePacked(
                    '<rect width="',
                    RECT_ATTRIBUTES[i][0],
                    '%" height="',
                    RECT_ATTRIBUTES[i][0],
                    '%" x="',
                    RECT_ATTRIBUTES[i][1],
                    '%" y="',
                    RECT_ATTRIBUTES[i][2],
                    '%" fill="#',
                    c0,
                    '">'
                ),
                //'<animate attributeName="width" to="71.4%" keySplines=".34 .36 .67 .69" dur="3.71s" repeatCount="indefinite" calcMode="spline" />',
                abi.encodePacked(
                    ANIMATE_START,
                    "width",
                    '" to="',
                    RECT_ATTRIBUTES[i][4],
                    '%" keySplines="',
                    RECT_ATTRIBUTES[i][3],
                    ANIMATE_END
                ),
                //'<animate attributeName="height" to="71.4%" keySplines=".34 .36 .67 .69" dur="3.71s" repeatCount="indefinite" calcMode="spline" />',
                abi.encodePacked(
                    ANIMATE_START,
                    "height",
                    '" to="',
                    RECT_ATTRIBUTES[i][4],
                    '%" keySplines="',
                    RECT_ATTRIBUTES[i][3],
                    ANIMATE_END
                ),
                // <animate attributeName="x" to="14.3%" keySplines=".34 .36 .67 .69" dur="3.71s" repeatCount="indefinite" calcMode="spline" />
                abi.encodePacked(
                    ANIMATE_START,
                    "x",
                    '" to="',
                    RECT_ATTRIBUTES[i][5],
                    '%" keySplines="',
                    RECT_ATTRIBUTES[i][3],
                    ANIMATE_END
                ),
                // <animate attributeName="y" to="21.45%" keySplines=".34 .36 .67 .69" dur="3.71s" repeatCount="indefinite" calcMode="spline" />
                abi.encodePacked(
                    ANIMATE_START,
                    "y",
                    '" to="',
                    RECT_ATTRIBUTES[i][6],
                    '%" keySplines="',
                    RECT_ATTRIBUTES[i][3],
                    ANIMATE_END
                ),
                last,
                // close parent rect
                "</rect>"
            );
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    uint24[] private _COLORS = [
        0x29abe2,
        0x006400,
        0xed1e79,
        0x000077,
        0xff6200,
        0xfcabed,
        0x6f00a4,
        0xff0000,
        0xc4e9fb,
        0x00a99d,
        0xffff9b
    ];

    string[] private _NAMES = [
        "blue",
        "forest",
        "magenta",
        "navy",
        "orange",
        "pink",
        "purple",
        "red",
        "sky",
        "teal",
        "yellow"
    ];

    function toHexString(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 6; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function _renderSVG(uint256 c0, uint256 c1)
        internal
        view
        returns (bytes memory)
    {
        uint256 ic0 = uint256(
            _interpolateColor(int256(c0), int256(c1), 371e15)
        );
        uint256 ic1 = uint256(
            _interpolateColor(int256(c0), int256(c1), 742e15)
        );
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">'
                '<rect fill="#',
                toHexString(c0),
                '" width="100%" height="100%" />',
                _renderRect(0, toHexString(c0), toHexString(ic0)),
                _renderRect(1, toHexString(ic0), toHexString(ic1)),
                _renderRect(2, toHexString(ic1), toHexString(c1)),
                _renderRect(3, toHexString(c1), toHexString(c1)),
                "</svg>"
            );
    }

    function _colorsToTokenId(uint24 outer, uint24 inner)
        internal
        view
        returns (uint256)
    {
        uint256 o = 0;
        for (; o < 11; ) {
            if (outer == _COLORS[o]) {
                break;
            }
            if (o == 10) {
                revert("Homage: unknown color");
            }
            unchecked {
                o++;
            }
        }
        uint256 i = 0;
        for (; i < 11; ) {
            if (inner == _COLORS[i]) {
                break;
            }
            if (i == 10) {
                revert("Homage: unknown color");
            }
            unchecked {
                i++;
            }
        }
        if (o == i) {
            revert("Homage: same color");
        }
        if (o > i) {
            o--;
        }
        return i * 10 + o + 1;
    }

    function _tokenJSON(uint256 tokenId) internal view returns (bytes memory) {
        uint256 inner = (tokenId - 1) / 10;
        uint256 outer = (tokenId - 1) % 10;
        if (outer >= inner) {
            outer++;
        }
        return
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Homage ',
                        tokenId.toString(),
                        '",',
                        unicode'"description":"Homage is a collection of 110 on-chain animations 🌹 '
                        unicode"project by Rafaël Rozendaal 2022 🌹 "
                        unicode"svg code by Reinier Feijen 🌹 "
                        unicode"smart contract by Alberto Granzotto 🌹 "
                        unicode"based on the work of Josef Albers 🌹 "
                        unicode'License: CC BY-NC-ND 4.0",',
                        '"attributes":[{"trait_type":"Inner Color","value":"',
                        _NAMES[inner],
                        '"},{"trait_type":"Outer Color","value":"',
                        _NAMES[outer],
                        '"}],',
                        '"image":"data:image/svg+xml;base64,',
                        Base64.encode(
                            _renderSVG(_COLORS[outer], _COLORS[inner])
                        ),
                        '"}'
                    )
                )
            );
    }
}