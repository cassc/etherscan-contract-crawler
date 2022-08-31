// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CabinetsSVG {
    using Strings for uint256;

    // There are 7 palettes in total.
    // The first and second palettes have 5 colors, so we pad it with an extra
    // 000000 color. The last color is used for the knobs.
    bytes constant _PALETTES =
        hex"b8ffdeffff9bbffffffccdffd8d2ffe6e6e6000000"
        hex"595959808080404040303030999999000000000000"
        hex"b3b3b3808080cccccce6e6e6d9d9d9bfbfbfffffff"
        hex"00a99d666666c4e9fb29abe2ccccccfccdfff00f00"
        hex"e6e6e6bfffffc4e9fb92d6ff29abe20071bccccccc"
        hex"e6e6e6d8d2ff6f00a4fccdffed1e79ff0000777777"
        hex"e6e6e678ff72b8ffde00a79100a545006837777777"
        hex"00a65100aeefed1c24ee2a7b000000595959ffffff";

    function _read(
        bytes memory b,
        uint256 offset,
        uint256 n
    ) internal pure returns (uint8) {
        require(n > 0 && n <= 8, "Invalid range");
        uint256 bytePos = offset / 8;
        uint256 bitPos = offset % 8;
        uint16 twoBytes;
        if (bytePos + 1 < b.length) {
            twoBytes = (uint16(uint8(b[bytePos])) << 8) | uint8(b[bytePos + 1]);
        } else {
            if (bitPos + n <= 8) {
                twoBytes = uint16(uint8(b[bytePos])) << 8;
            } else {
                revert("Out of bound");
            }
        }
        return uint8(twoBytes >> (16 - bitPos - n)) & uint8((1 << n) - 1);
    }

    function _getRGBColor(uint8 paletteIndex, uint8 colorIndex)
        internal
        pure
        returns (bytes memory)
    {
        // Each color is 3 RBG bytes, each palette is made of 7 colors (3 * 7 =
        // 21 bytes). To select the palette we offset by 21 bytes. To select the
        // color we add the index of the color multiplied by 3.
        uint256 offset = paletteIndex * 21 + colorIndex * 3;

        return
            abi.encodePacked(
                "rgb(",
                uint256(uint8(_PALETTES[offset])).toString(),
                ",",
                uint256(uint8(_PALETTES[offset + 1])).toString(),
                ",",
                uint256(uint8(_PALETTES[offset + 2])).toString(),
                ")"
            );
    }

    function _generateKnob(
        uint256 x,
        uint256 y,
        bytes memory fill
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<circle cx="',
                x.toString(),
                '" cy="',
                y.toString(),
                '" r="35" fill="',
                fill,
                '"/>'
            );
    }

    function _generatePanel(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        uint8 paletteIndex,
        uint8 colorIndex,
        uint8 knobColorIndex,
        uint8 knobType
    ) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            svg,
            '<rect x="',
            x.toString(),
            '" y="',
            y.toString(),
            '" width="',
            width.toString(),
            '" height="',
            height.toString(),
            '" fill="',
            _getRGBColor(paletteIndex, colorIndex),
            '" shape-rendering="crispEdges" />'
        );

        if (knobType == 0) {
            // middle center
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + width / 2,
                    y + height / 2,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 1) {
            // two vertically centered knobs
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + (width * 25) / 100,
                    y + height / 2,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + (width * 75) / 100,
                    y + height / 2,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 2) {
            // top left
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + 121,
                    y + 151,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 3) {
            // top right
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + width - 121,
                    y + 151,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 4) {
            // middle left
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + 121,
                    y + (height / 2),
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 5) {
            // middle right
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + width - 121,
                    y + (height / 2),
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 6) {
            // bottom left
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + 121,
                    y + height - 151,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        } else if (knobType == 7) {
            // bottom right
            svg = abi.encodePacked(
                svg,
                _generateKnob(
                    x + width - 121,
                    y + height - 151,
                    _getRGBColor(paletteIndex, knobColorIndex)
                )
            );
        }
    }

    function _generatePanels(bytes memory dna)
        internal
        pure
        returns (bytes memory svg)
    {
        uint8[4] memory p = [
            _read(dna, 0, 1), // aspect ratio
            _read(dna, 1, 2) + 1, // grid width
            _read(dna, 3, 4) + 1, // grid height
            _read(dna, 7, 3) // paletteIndex
        ];

        uint256 xScale;
        uint256 yScale;

        if (p[0] == 0) {
            xScale = 1680 / p[1];
            yScale = 2520 / p[2];
        } else {
            xScale = 2520 / p[1];
            yScale = 1680 / p[2];
        }

        for (uint256 offset = 10; offset + 20 < dna.length * 8; offset += 21) {
            // uint8 x = _read(dna, offset, 2);
            // uint8 y = _read(dna, offset + 2, 4);
            // uint8 width = _read(dna, offset + 6, 2);
            // uint8 height = _read(dna, offset + 8, 4);
            // uint8 colorIndex = _read(dna, offset + 12, 3);
            // uint8 knobColorIndex = _read(dna, offset + 15, 3);
            // uint8 knobType = _read(dna, offset + 18, 3);

            svg = abi.encodePacked(
                svg,
                _generatePanel(
                    _read(dna, offset, 2) * xScale,
                    _read(dna, offset + 2, 4) * yScale,
                    (_read(dna, offset + 6, 2) + 1) * xScale,
                    (_read(dna, offset + 8, 4) + 1) * yScale,
                    p[3],
                    _read(dna, offset + 12, 3),
                    _read(dna, offset + 15, 3),
                    _read(dna, offset + 18, 3)
                )
            );
        }
    }

    function _generateSVG(bytes memory dna)
        internal
        pure
        returns (bytes memory)
    {
        // Last bit index = 0
        uint8 aspectRatio = _read(dna, 0, 1);

        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
                aspectRatio == 0 ? "1680 2520" : "2520 1680",
                '">',
                _generatePanels(dna),
                "</svg>"
            );
    }

    function _generateJSON(uint256 tokenId, bytes memory dna)
        internal
        pure
        returns (bytes memory)
    {
        string[8] memory names = [
            "Pastel",
            "Dark Grey",
            "Light Grey",
            "Calm",
            "Blueish",
            "Purpleish",
            "Greenish",
            "Bright"
        ];
        uint8 paletteIndex = _read(dna, 7, 3);
        // First 10 bits are for the header. Each panel takes 21 bits.
        uint256 panelCount = (dna.length * 8 - 10) / 21;
        string memory density = "High";

        if (panelCount <= 4) {
            density = "Low";
        } else if (panelCount <= 10) {
            density = "Medium";
        }

        string memory orientation = _read(dna, 0, 1) == 0
            ? "Portrait"
            : "Landscape";

        return
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Cabinet ',
                        tokenId.toString(),
                        '",',
                        unicode'"description":"Cabinets is a collection of 123 fully on–chain generative artworks 🌹 '
                        unicode"Project by Rafaël Rozendaal 2022 🌹 "
                        unicode"SVG code by Reinier Feijen 🌹 "
                        unicode"Smart contract by Alberto Granzotto 🌹 "
                        unicode'License: CC BY-NC-ND 4.0",',
                        abi.encodePacked(
                            '"attributes":[{"trait_type":"Palette","value":"',
                            names[paletteIndex],
                            '"},{"trait_type":"Density","value":"',
                            density,
                            '"},{"trait_type":"Orientation","value":"',
                            orientation,
                            '"}],'
                        ),
                        '"image":"data:image/svg+xml;base64,',
                        Base64.encode(_generateSVG(dna)),
                        '"}'
                    )
                )
            );
    }
}