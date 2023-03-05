// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "./Utils.sol";

library AsciiApesArtMetadata {

    struct Color {
        string value;
        string name;
    }

    struct Trait {
        string content;
        string name;
        Color color;
    }

    function tokenURI(uint256 tokenId, uint256 seed) internal pure returns (string memory) {

        uint256[4] memory colors = [seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory head = getHead(seed / 100000000000000, colors[0]);
        Trait memory face = getFace(seed % 1000000000000 / 10000000000, colors[1]);
        Trait memory body = getBody(seed % 100000000 / 1000000, colors[2]);
        Trait memory mouth = getMouth(seed % 10000 / 100, colors[3]);
        string memory colorCount = calculateColorCount(colors);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" style="width:100%;background:#121212;">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                head.content,
                face.content,
                mouth.content,
                body.content,
                '</text>',
                '</svg>'
            )
        );

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "AsciiApes #', StringsUpgradeable.toString(tokenId), '",',
                '"description": "Ascii Artwork for Apes",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64Upgradeable.encode(bytes(rawSvg)),
                    '",',
                '"attributes": [',
                    _attributes(head, face, body, mouth, colorCount),
                ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64Upgradeable.encode(metadata)
            )
        );
    }

    function _attributes(Trait memory head, Trait memory face, Trait memory body, Trait memory mouth, string memory colorCount) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _trait('Head', head, ','),
            _trait('Face', face, ','),
            _trait('Mouth', mouth, ','),
            _trait('Body', body, ','),
            '{"trait_type": "Colors", "value": ', colorCount, '}'
        );
    }

    function _trait(string memory traitType, Trait memory traitValue, string memory append) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue.name,' (',traitValue.color.name,')', '"'
            '}',
            append
        ));
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

        return Color('','');
    }

    function getHead(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "\\\\\\";
            name = "Head 1";
        }
        if (seed == 11) {
            content = "---";
            name = "Head 2";
        }
        if (seed == 12) {
            content = "/~s\\";
            name = "Head 3";
        }
        if (seed == 13) {
            content = "////";
            name = "Head 4";
        }
        if (seed == 14) {
            content = "***";
            name = "Head 5";
        }
        if (seed == 15) {
            content = "\\--\\";
            name = "Head 6";
        }
        if (seed == 16) {
            content = "~~~";
            name = "Head 7";
        }
        if (seed == 17) {
            content = ">>>";
            name = "Head 8";
        }
        if (seed == 18) {
            content = "<<<";
            name = "Head 9";
        }
        if (seed == 19) {
            content = "/~:\\";
            name = "Head 10";
        }
        if (seed == 20) {
            content = "==++=";
            name = "Head 11";
        }
        
        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFace(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "C oo)";
            name = "Face 1";
        }
        if (seed == 11) {
            content = "C --)";
            name = "Face 2";
        }
        if (seed == 12) {
            content = "C 33)";
            name = "Face 3";
        }
        if (seed == 13) {
            content = "C Oo)";
            name = "Face 4";
        }
        if (seed == 14) {
            content = "C 00)";
            name = "Face 5";
        }
        if (seed == 15) {
            content = "C o-o)";
            name = "Face 6";
        }
        if (seed == 16) {
            content = "C ++)";
            name = "Face 7";
        }
        if (seed == 17) {
            content = "C ||)";
            name = "Face 8";
        }
        if (seed == 18) {
            content = "C 66)";
            name = "Face 9";
        }
        if (seed == 19) {
            content = "C @@)";
            name = "Face 10";
        }

        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getBody(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "/1 -w}";
            name = "Body 1";
        }
        if (seed == 11) {
            content = "/1 ==}";
            name = "Body 2";
        }
        if (seed == 12) {
            content = "/1 ,,}";
            name = "Body 3";
        }
        if (seed == 13) {
            content = "/1 ++}";
            name = "Body 4";
        }
        if (seed == 14) {
            content = "/1 :z}";
            name = "Body 5";
        }
        if (seed == 15) {
            content = "/ \\:/}";
            name = "Body 6";
        }
        if (seed == 16) {
            content = "/ \\~/}";
            name = "Body 7";
        }
        if (seed == 17) {
            content = "/ \\+/}";
            name = "Body 8";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getMouth(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "_( ~)";
            name = "Mouth 1";
        }
        if (seed == 11) {
            content = "_( ^)";
            name = "Mouth 2";
        }
        if (seed == 12) {
            content = "_( .)";
            name = "Mouth 3";
        }
        if (seed == 13) {
            content = "_( -)";
            name = "Mouth 4";
        }
        if (seed == 14) {
            content = "_( \")";
            name = "Mouth 5";
        }
        if (seed == 15) {
            content = "_( v)";
            name = "Mouth 6";
        }
        
        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
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