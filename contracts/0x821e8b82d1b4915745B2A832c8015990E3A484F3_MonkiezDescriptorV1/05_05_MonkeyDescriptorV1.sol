// SPDX-License-Identifier: MIT

/*********************************
 *                                *
 *               0,0              *
 *                                *
 *********************************/

pragma solidity ^0.8.13;

import "./lib/base64.sol";
import "./IMonkeyDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MonkiezDescriptorV1 is IMonkeyDescriptor {
    struct Color {
        string value;
        string name;
    }
    struct Trait {
        string content;
        string name;
        Color color;
    }
    using Strings for uint256;

    string private constant SVG_END_TAG = "</svg>";

    function tokenURI(uint256 tokenId, uint256 seed)
        external
        pure
        override
        returns (string memory)
    {
        uint256[3] memory colors = [seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory head = getHead(seed % 1000000000000 / 10000000000, colors[0]);
        Trait memory face = getFace(seed % 100000000 / 1000000, colors[1]);
        Trait memory body = getBody(seed % 10000 / 100, colors[2]);
        string memory colorCount = calculateColorCount(colors);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Helvetica,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                head.content,
                face.content,
                body.content,
                "</text>",
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = "Eeee";

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name":"Monkiez #',
                                tokenId.toString(),
                                '",',
                                '"description":"',
                                description,
                                '",',
                                '"image": "',
                                "data:image/svg+xml;base64,",
                                encodedSvg,
                                '",',
                                '"attributes": [{"trait_type": "Head", "value": "',
                                head.name,
                                " (",
                                head.color.name,
                                ")",
                                '"},',
                                '{"trait_type": "Face", "value": "',
                                face.name,
                                " (",
                                face.color.name,
                                ")",
                                '"},',
                                '{"trait_type": "Body", "value": "',
                                body.name,
                                " (",
                                body.color.name,
                                ")",
                                '"},',
                                '{"trait_type": "Colors", "value": ',
                                colorCount,
                                "}",
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function getColor(uint256 seed) private pure returns (Color memory) {
        if (seed == 10) {
            return Color("#e60049", "UA Red");
        }
        if (seed == 11) {
            return Color("#82b6b9", "Pewter Blue");
        }
        if (seed == 12) {
            return Color("#b3d4ff", "Pale Blue");
        }
        if (seed == 13) {
            return Color("#00ffff", "Aqua");
        }
        if (seed == 14) {
            return Color("#0bb4ff", "Blue Bolt");
        }
        if (seed == 15) {
            return Color("#1853ff", "Blue RYB");
        }
        if (seed == 16) {
            return Color("#35d435", "Lime Green");
        }
        if (seed == 17) {
            return Color("#61ff75", "Screamin Green");
        }
        if (seed == 18) {
            return Color("#00bfa0", "Aqua");
        }
        if (seed == 19) {
            return Color("#ffa300", "Orange");
        }
        if (seed == 20) {
            return Color("#fd7f6f", "Coral Reef");
        }
        if (seed == 21) {
            return Color("#d0f400", "Volt");
        }
        if (seed == 22) {
            return Color("#9b19f5", "Purple X11");
        }
        if (seed == 23) {
            return Color("#dc0ab4", "Deep Magenta");
        }
        if (seed == 24) {
            return Color("#f46a9b", "Cyclamen");
        }
        if (seed == 25) {
            return Color("#bd7ebe", "African Violet");
        }
        if (seed == 26) {
            return Color("#fdcce5", "Classic Rose");
        }
        if (seed == 27) {
            return Color("#FCE74C", "Gargoyle Gas");
        }
        if (seed == 28) {
            return Color("#eeeeee", "Bright Gray");
        }
        if (seed == 29) {
            return Color("#7f766d", "Sonic Silver");
        }

        return Color("", "");
    }

    function getHead(uint256 seed, uint256 colorSeed)
        private
        pure
        returns (Trait memory)
    {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "'=\\\\=//='";
            name = "Crown";
        }
        if (seed == 11) {
            content = "xXx";
            name = "Sunglasses";
        }
        if (seed == 12) {
            content = "'^^^'";
            name = "Fluffy Hair";
        }
        if (seed == 13) {
            content = "~~~";
            name = "Curly hair";
        }
        if (seed == 14) {
            content = "(---)";
            name = "Green Beret";
        }
        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan fill="',
                        color.value,
                        '">',
                        content,
                        "</tspan>"
                    )
                ),
                name,
                color
            );
    }

    function getFace(uint256 seed, uint256 colorSeed)
        private
        pure
        returns (Trait memory)
    {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;

        if (seed == 10) {
            content = unicode"c(o . o)ɔ";
            name = "Round";
        }
        if (seed == 11) {
            content = unicode"c(= . =)ɔ";
            name = "Angry";
        }
        if (seed == 12) {
            content = unicode"c(o . x)ɔ";
            name = "Cheerful";
        }
        if (seed == 13) {
            content = unicode"c(o ^ o)ɔ";
            name = "Excited";
        }
        if (seed == 14) {
            content = unicode"c(- . -)ɔ";
            name = "Bored";
        }
        if (seed == 15) {
            content = unicode"c(u . u)ɔ";
            name = "Cute";
        }

        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan dy="20" x="160" font-size="20" fill="',
                        color.value,
                        '">',
                        content,
                        "</tspan>"
                    )
                ),
                name,
                color
            );
    }

    function getBody(uint256 seed, uint256 colorSeed)
        private
        pure
        returns (Trait memory)
    {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "{\\./}";
            name = "Tuxedo";
        }
        if (seed == 11) {
            content = "{ u }";
            name = "Potbelly";
        }
        if (seed == 12) {
            content = "{\\s/}";
            name = "SuperMonkiez";
        }
        if (seed == 13) {
            content = "{=|=}";
            name = "Muscular";
        }
        if (seed == 14) {
            content = "{\\+/}";
            name = "Gentle";
        }
        if (seed == 15) {
            content = "{\\:/}";
            name = "Suit";
        }
        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan dy="24" x="160" font-size="24" fill="',
                        color.value,
                        '">',
                        content,
                        "</tspan>"
                    )
                ),
                name,
                color
            );
    }

    function calculateColorCount(uint256[3] memory colors)
        private
        pure
        returns (string memory)
    {
        uint256 count;
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                if (colors[i] == colors[j]) {
                    count++;
                }
            }
        }

        if (count == 6) {
            return "3";
        }
        if (count == 8 || count == 10) {
            return "2";
        }
        if (count == 16) {
            return "1";
        }

        return "0";
    }
}