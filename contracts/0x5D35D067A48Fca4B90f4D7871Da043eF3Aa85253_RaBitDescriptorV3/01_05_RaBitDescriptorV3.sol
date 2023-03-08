// SPDX-License-Identifier: MIT

/*********************************
*                                *
*            (\_/)               *
*                                *
 *********************************/

// rabits.xyz
// twitter.com/rabitsxyz

pragma solidity ^0.8.13;

import './base64.sol';
import "./IRaBitDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RaBitDescriptorV3 is IRaBitDescriptor {
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

    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
        uint256[4] memory colors = [seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory head = getHead(seed / 100000000000000, colors[0]);
        Trait memory face = getFace(seed % 1000000000000 / 10000000000, colors[1]);
        Trait memory body = getBody(seed % 100000000 / 1000000, colors[2]);
        Trait memory feet = getFeet(seed % 10000 / 100, colors[3]);
        string memory colorCount = calculateColorCount(colors);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#2c2c2c"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                head.content,
                face.content,
                body.content,
                feet.content,
                '</text>',
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = 'RBT';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"RaBit #', tokenId.toString(), '",',
                            '"description":"', description, '",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Head", "value": "', head.name,' (',head.color.name,')', '"},',
                            '{"trait_type": "Face", "value": "', face.name,' (',face.color.name,')', '"},',
                            '{"trait_type": "Body", "value": "', body.name,' (',body.color.name,')', '"},',
                            '{"trait_type": "Feet", "value": "', feet.name,' (',feet.color.name,')', '"},',
                            '{"trait_type": "Colors", "value": ', colorCount, '}',
                            ']',
                            '}')
                    )
                )
            )
        );
    }

    function getColor(uint256 seed) private pure returns (Color memory) {
        if (seed == 10) {
            return Color("#ff5733", "Mango Orange");
        }
        if (seed == 11) {
            return Color("#7a8ccc", "Slate Blue");
        }
        if (seed == 12) {
            return Color("#ffebcd", "Blanched Almond");
        }
        if (seed == 13) {
            return Color("#03c6fc", "Electric Blue");
        }
        if (seed == 14) {
            return Color("#ff0080", "Fuchsia");
        }
        if (seed == 15) {
            return Color("#ffea00", "Yellow");
        }
        if (seed == 16) {
            return Color("#33cc33", "Forest Green");
        }
        if (seed == 17) {
            return Color("#ff6666", "Coral Pink");
        }
        if (seed == 18) {
            return Color("#00ffcc", "Turquoise");
        }
        if (seed == 19) {
            return Color("#ffb347", "Dark Salmon");
        }
        if (seed == 20) {
            return Color("#ff6b6b", "Indian Red");
        }
        if (seed == 21) {
            return Color("#bf00ff", "Purple");
        }
        if (seed == 22) {
            return Color("#ffa07a", "Light Salmon");
        }
        if (seed == 23) {
            return Color("#4d4dff", "Cornflower Blue");
        }
        if (seed == 24) {
            return Color("#ffcccc", "Cotton Candy");
        }
        if (seed == 25) {
            return Color("#7f00ff", "Electric Purple");
        }
        if (seed == 26) {
            return Color("#00e6e6", "Caribbean Green");
        }
        if (seed == 27) {
            return Color("#ffb6c1", "Light Pink");
        }
        if (seed == 28) {
            return Color("#666699", "Slate Gray");
        }
        if (seed == 29) {
            return Color("#00ccff", "Sky Blue");
        }

        return Color('','');
    }

    function getHead(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "/)_/)";
            name = "Slanted Curved";
        }
        if (seed == 11) {
            content = "//_//";
            name = "Slanted";
        }
        if (seed == 12) {
            content = "||_||";
            name = "Vertical";
        }
        if (seed == 13) {
            content = "()_()";
            name = "Rounded";
        }
        if (seed == 14) {
            content = "(\\_/)";
            name = "Outward Curved";
        }
        if (seed == 15) {
            content = "//_\\\\";
            name = "Inward Straight";
        }
        if (seed == 16) {
            content = "( Y )";
            name = "Wide";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFace(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "(`x`)";
            name = "Angry";
        }
        if (seed == 11) {
            content = "('x')";
            name = "Content";
        }
        if (seed == 12) {
            content = "('x-)";
            name = "Wink";
        }
        if (seed == 13) {
            content = "(`x')";
            name = "Suspicious";
        }
        if (seed == 14) {
            content = "(;.;)";
            name = "Crying";
        }
        if (seed == 15) {
            content = "(*.*)";
            name = "Starry-Eyed";
        }
        if (seed == 15) {
            content = "(^x^)";
            name = "Happy";
        }
        if (seed == 16) {
            content = "(-x-)";
            name = "Sleeping";
        }
        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getBody(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "/ > &lt;3";
            name = "Love";
        }
        if (seed == 11) {
            content = "/ > $";
            name = "Money";
        }
        if (seed == 12) {
            content = "/ > o";
            name = "Cookie";
        }
        if (seed == 13) {
            content = "(\\+/)";
            name = "Priest";
        }
        if (seed == 14) {
            content = "{ :~}";
            name = "Shirt";
        }
        if (seed == 15) {
            content = "{\\:/}";
            name = "Suit";
        }
        if (seed == 16) {
            content = "{\\~/}";
            name = "Tux";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFeet(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 y;
        if (seed == 10) {
            content = "(=)(=)";
            name = "Thick Paws";
            y = 25;
        }
        if (seed == 11) {
            content = "o(\")(\")";
            name = "Tail";
            y = 25;
        }
        if (seed == 12) {
            content = "c(\"\")(\"\")";
            name = "Big Paws Small Tail";
            y = 25;
        }
        if (seed == 13) {
            content = "(^)(^)";
            name = "Sharp Paws";
            y = 25;
        }
        if (seed == 14) {
            content = "o_U..U";
            name = "Small Paws Small Tail";
            y = 25;
        }
        if (seed == 15) {
            content = "UU";
            name = "Standing";
            y = 22;
        }

        return Trait(string(abi.encodePacked('<tspan dy="',y.toString(),'" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function calculateColorCount(uint256[4] memory colors) private pure returns (string memory) {
        uint256 count;
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 4; j++) {
                if (colors[i] == colors[j]) {
                    count++;
                }
            }
        }

        if (count == 4) {
            return '4';
        }
        if (count == 6) {
            return '3';
        }
        if (count == 8 || count == 10) {
            return '2';
        }
        if (count == 16) {
            return '1';
        }

        return '0';
    }
}