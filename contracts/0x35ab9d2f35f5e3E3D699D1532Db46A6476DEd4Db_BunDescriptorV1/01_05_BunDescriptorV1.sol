// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./base64.sol";
import "./IBunDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BunDescriptorV1 is IBunDescriptor {
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
                '<rect width="100%" height="100%" fill="#121212"/>',
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
        string memory description = 'Hop Hop';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"Bun #', tokenId.toString(), '",',
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
            return Color("#9b111e", "Ruby Red");
        }
        if (seed == 11) {
            return Color("#ec5578", "Fruit Punch");
        }
        if (seed == 12) {
            return Color("#2b65ec", "Ocean Blue");
        }
        if (seed == 13) {
            return Color("#00A36C", "Jade");
        }
        if (seed == 14) {
            return Color("#fe5bac", "Bubble Gum");
        }
        if (seed == 15) {
            return Color("#afdcec", "Coral Blue");
        }
        if (seed == 16) {
            return Color("#98fb98", "Mint");
        }
        if (seed == 17) {
            return Color("#2cfa1f", "Radioactive");
        }
        if (seed == 18) {
            return Color("#ffffff", "White Void");
        }
        if (seed == 19) {
            return Color("#cf6600", "Tangerine");
        }
        if (seed == 20) {
            return Color("#d4af37", "Metallic Gold");
        }
        if (seed == 21) {
            return Color("#4682b4", "Blue Steel");
        }
        if (seed == 22) {
            return Color("#00ffff", "Aqua Blue");
        }
        if (seed == 23) {
            return Color("#ff0090", "Bright Magenta");
        }
        if (seed == 24) {
            return Color("#ffff00", "Neon Yellow");
        }
        if (seed == 25) {
            return Color("#9d00ff", "Electric Purple");
        }
        if (seed == 26) {
            return Color("#ff0800", "Candy Apple");
        }
        if (seed == 27) {
            return Color("#f5bae1", "Pink Rose");
        }
        if (seed == 28) {
            return Color("#bebdb8", "Smokey Gray");
        }
        if (seed == 29) {
            return Color("#4b4e53", "Stainless Steel");
        }

        return Color('','');
    }

    function getHead(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "(\\_/)";
            name = "Pointy Ears";
        }
        if (seed == 11) {
            content = "|\\^/|";
            name = "Crown";
        }
        if (seed == 12) {
            content = "(`)(`)";
            name = "Flappy Ears";
        }
        if (seed == 13) {
            content = "/*\\";
            name = "Party Hat";
        }
        if (seed == 14) {
            content = "*===*";
            name = "Halo";
        }
        if (seed == 15) {
            content = ",-*-,";
            name = "Beanie";
        }
        if (seed == 16) {
            content = "_|``|_";
            name = "Top Hat";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFace(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "=(O.O)=";
            name = "Suprised";
        }
        if (seed == 11) {
            content = "=(o.-)=";
            name = "Wink";
        }
        if (seed == 12) {
            content = "=(-.-)=";
            name = "Sleepy";
        }
        if (seed == 13) {
            content = "d(o.o)b";
            name = "Headphones";
        }
        if (seed == 14) {
            content = "=(^.^)=";
            name = "Happy";
        }
        if (seed == 15) {
            content = "=(~.~)=";
            name = "Dizzy";
        }
        if (seed == 16) {
            content = "=(0-0)=";
            name = "Sunglasses";
        }

        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getBody(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "(>  )>";
            name = "Hopping";
        }
        if (seed == 11) {
            content = "(`*`)";
            name = "Necklace";
        }
        if (seed == 12) {
            content = "(;;;)";
            name = "Furry";
        }
        if (seed == 13) {
            content = "[*\\*]";
            name = "Bunny Commander";
        }
        if (seed == 14) {
            content = "(':')";
            name = "Shirt";
        }
        if (seed == 15) {
            content = "(\\!/)";
            name = "Suit and Tie";
        }
        if (seed == 16) {
            content = "((:))";
            name = "Puffy Jacket";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFeet(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 y;
        if (seed == 10) {
            content = "_c(')(')_";
            name = "Sitting";
            y = 22;
        }
        if (seed == 11) {
            content = "c(,)(,)";
            name = "Standing";
            y = 25;
        }

        return Trait(string(abi.encodePacked('<tspan dy="',y.toString(),'" x="155" fill="', color.value, '">', content, '</tspan>')), name, color);
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