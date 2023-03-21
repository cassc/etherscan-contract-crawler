// SPDX-License-Identifier: MIT

/********************************
 *                               *
 *            [ o_0 ]            *
 *                               *
 ********************************/

pragma solidity ^0.8.13;

import "./lib/base64.sol";
import "./IRoBitDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoBitDescriptor is IRoBitDescriptor {
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

    function tokenURI(
        uint256 tokenId,
        uint256 seed
    ) external pure override returns (string memory) {
        uint256[4] memory colors = [
            (seed % 100000000000000) / 1000000000000,
            (seed % 10000000000) / 100000000,
            (seed % 1000000) / 10000,
            seed % 100
        ];
        Trait memory head = getHead(seed / 100000000000000, colors[0]);
        Trait memory face = getFace(
            (seed % 1000000000000) / 10000000000,
            colors[1]
        );
        Trait memory body = getBody((seed % 100000000) / 1000000, colors[2]);
        Trait memory feet = getFeet((seed % 10000) / 100, colors[3]);
        string memory colorCount = calculateColorCount(colors);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                "<defs>",
                "<style>",
                "@font-face {",
                'font-family: "Consolas_RoBits";',
                ' src: url(data:application/octet-stream;base64,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);',
                "}",
                "</style>",
                "</defs>",
                '<rect width="100%" height="100%" fill="#1d1d1b"/>',
                '<text x="160" y="128.7269" font-family="Consolas_RoBits" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="0">',
                head.content,
                face.content,
                body.content,
                feet.content,
                "</text>",
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = "R0B0";

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name":"RoBit #',
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
                                '{"trait_type": "Feet", "value": "',
                                feet.name,
                                " (",
                                feet.color.name,
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
            return Color("#960018", "Carmine");
        }
        if (seed == 11) {
            return Color("#56A0D3", "Carolina Blue");
        }
        if (seed == 12) {
            return Color("#B9D9EB", "Columbia Blue");
        }
        if (seed == 13) {
            return Color("#6BCAE2", "AquaMarine Blue");
        }
        if (seed == 14) {
            return Color("#FF2800", "Ferrari");
        }
        if (seed == 15) {
            return Color("#eec007", "Saffron");
        }
        if (seed == 16) {
            return Color("#B0BF1A", "Acid Green");
        }
        if (seed == 17) {
            return Color("#9EFD38", "French Lime");
        }
        if (seed == 18) {
            return Color("#52B2BF", "Sapphire");
        }
        if (seed == 19) {
            return Color("#ED872D", "Cadmium Orange");
        }
        if (seed == 20) {
            return Color("#00bff5", "Raff");
        }
        if (seed == 21) {
            return Color("#CEFF00", "Volt");
        }
        if (seed == 22) {
            return Color("#A45EE5", "Amethyst");
        }
        if (seed == 23) {
            return Color("#A1045A", "Strong Magenta");
        }
        if (seed == 24) {
            return Color("#A020F0", "Veronica");
        }
        if (seed == 25) {
            return Color("#FF00FF", "Fuchsia");
        }
        if (seed == 26) {
            return Color("#E68FAC", "Charm Pink");
        }
        if (seed == 27) {
            return Color("#ffe980", "Digital Yellow");
        }
        if (seed == 28) {
            return Color("#ACACAC", "Silver Chalice");
        }
        if (seed == 29) {
            return Color("#FFF8E7", "Cosmic Latte");
        }

        return Color("", "");
    }

    function getHead(
        uint256 seed,
        uint256 colorSeed
    ) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "_!~!_";
            name = "Voltage";
        }
        if (seed == 11) {
            content = "_!!!_";
            name = "Mohawk";
        }
        if (seed == 12) {
            content = "_\\ /_";
            name = "Bent";
        }
        if (seed == 13) {
            content = "_? ?_";
            name = "Antenna";
        }
        if (seed == 14) {
            content = "_| |_";
            name = "Top Hat";
        }
        if (seed == 15) {
            content = "_ ! _";
            name = "Mark";
        }
        if (seed == 16) {
            content = "_{ }_";
            name = "Samurai";
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

    function getFace(
        uint256 seed,
        uint256 colorSeed
    ) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "[ o_0 ]";
            name = "Pirate";
        }
        if (seed == 11) {
            content = "[ o_o ]";
            name = "Lorem";
        }
        if (seed == 12) {
            content = "[ ^_^ ]";
            name = "Happy";
        }
        if (seed == 13) {
            content = "[ === ]";
            name = "Laser";
        }
        if (seed == 14) {
            content = "[ :_: ]";
            name = "Spider";
        }
        if (seed == 15) {
            content = "[ *_* ]";
            name = "Star";
        }
        if (seed == 16) {
            content = "[ &#242;_&#243; ]";
            name = "Angry";
        }
        if (seed == 17) {
            content = "[ &#186;_&#186; ]";
            name = "Masculine";
        }
        if (seed == 18) {
            content = "[ &#8226;_&#183; ]";
            name = "Bullet";
        }

        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan dy="23" x="160" fill="',
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

    function getBody(
        uint256 seed,
        uint256 colorSeed
    ) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "/ [_#_] \\";
            name = "SquareSlash";
        }
        if (seed == 11) {
            content = "/ (_#_) \\";
            name = "RoundSlash";
        }
        if (seed == 12) {
            content = "/ {_#_} \\";
            name = "BracketSlash";
        }
        if (seed == 13) {
            content = ". (_#_) .";
            name = "RoundDot";
        }
        if (seed == 14) {
            content = ". [_#_] .";
            name = "SquareDot";
        }
        if (seed == 15) {
            content = "&gt; [_#_] &lt;";
            name = "SquareClamp";
        }
        if (seed == 16) {
            content = "&gt; {_#_} &lt;";
            name = "BracketClamp";
        }
        if (seed == 17) {
            content = "&#166; [_#_] &#166;";
            name = "SquareBrokenBar";
        }
        if (seed == 18) {
            content = "&#166; {_#_} &#166;";
            name = "BracketBrokenBar";
        }


        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan dy="25" x="160" fill="',
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

    function getFeet(
        uint256 seed,
        uint256 colorSeed
    ) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "_( )_";
            name = "Crooked";
        }
        if (seed == 11) {
            content = "(o)";
            name = "Unicycle";
        }
        if (seed == 12) {
            content = "_===_";
            name = "Print";
        }
        if (seed == 13) {
            content = "_] [_";
            name = "Straight";
        }
        if (seed == 14) {
            content = "(o) (o)";
            name = "Wheels";
        }
        if (seed == 15) {
            content = "(=) (=)";
            name = "Tracks";
        }

        return
            Trait(
                string(
                    abi.encodePacked(
                        '<tspan dy="25" x="160" fill="',
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

    function calculateColorCount(
        uint256[4] memory colors
    ) private pure returns (string memory) {
        uint256 count;
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 4; j++) {
                if (colors[i] == colors[j]) {
                    count++;
                }
            }
        }

        if (count == 4) {
            return "4";
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