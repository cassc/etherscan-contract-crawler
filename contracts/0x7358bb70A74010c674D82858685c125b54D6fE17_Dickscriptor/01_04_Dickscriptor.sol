// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              8==D              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import './base64.sol';
import "./IDickscriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Dickscriptor is IDickscriptor {
    struct Color {
        string value;
        string name;
    }
    struct Trait {
        string content;
        string name;
        Color color;
        uint64 inches;
    }
    using Strings for uint256;

    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
        uint256[4] memory colors = [seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory line1 = getLine1(seed / 100000000000000, colors[0]);
        Trait memory line2 = getLine2(seed % 1000000000000 / 10000000000, colors[1]);
        Trait memory line3 = getLine3(seed % 100000000 / 1000000, colors[2]);
        Trait memory line4 = getLine4(seed % 1000 / 5, colors[3]);

        string memory colorCount = calculateColorCount(colors);
        string memory inchCount = calculateInches([line1.inches, line2.inches, line3.inches, line4.inches]);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                line1.content,
                line2.content,
                line3.content,
                line4.content,
                '</text>',
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"Onchain Dicks #', tokenId.toString(), '",',
                            '"description":"Cock",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Head", "value": "', line1.name,' (',line1.color.name,')', '"},',
                            '{"trait_type": "Shaft", "value": "', line2.name,' (',line2.color.name,')', '"},',
                            '{"trait_type": "Balls", "value": "', line3.name,' (',line3.color.name,')', '"},',
                            '{"trait_type": "Slang", "value": "', line4.name,' (',line4.color.name,')', '"},',
                            '{"trait_type": "Inches", "value": ', inchCount, '},',
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

        return Color("#ffffff", "Plain White");
    }

    function getLine1(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "8==D";
            name = "2 Inch";
            inches = 2;
        }
        else if (seed == 11) {
            content = "8===D";
            name = "3 Inch";
            inches = 3;
        }
        else if (seed == 12) {
            content = "8====D";
            name = "4 Inch";
            inches = 4;
        }
        else if (seed == 13) {
            content = "8=====D";
            name = "5 Inch";
            inches = 5;
        }
        else if (seed == 14) {
            content = "8======D";
            name = "6 Inch";
            inches = 6;
        }
        else if (seed == 15) {
            content = "8============D";
            name = "Wow";
            inches = 12;
        }
        else if (seed == 16) {
            content = "8-D";
            name = "Micro";
            inches = 1;
        }
        else if (seed == 17) {
            content = "8----D";
            name = "Thin";
            inches = 4;
        }
        else if (seed == 18) {
            content = "8=-=-=D";
            name = "Weird";
            inches = 5;
        }
        else if (seed == 19) {
            content = "8";
            name = "Balls";
            inches = 0;
        }
        else if (seed == 20) {
            content = "\u15E1-D";
            name = "Double Ended Thin";
            inches = 1;
        } else {
            content = "";
            name = "None";
            inches = 0;
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine2(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "\u15E1==8";
            name = "Reversed 2 Inch";
            inches = 2;
        }
        else if (seed == 11) {
            content = "\u15E1===8";
            name = "Reversed 3 Inch";
            inches = 3;
        }
        else if (seed == 12) {
            content = "\u15E1====8";
            name = "Reversed 4 Inch";
            inches = 4;
        }
        else if (seed == 13) {
            content = "\u15E1=====8";
            name = "Reversed 5 Inch";
            inches = 5;
        }
        else if (seed == 14) {
            content = "\u15E1============8";
            name = "Reversed Hung";
            inches = 12;
        }
        else if (seed == 15) {
            content = "\u15E1-8";
            name = "Reversed Thin";
            inches = 1;
        }
        else if (seed == 16) {
            content = "\u15E1-D";
            name = "Double Ended";
            inches = 1;
        } else {
            content = "";
            name = "None";
            inches = 0;
        }

        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine3(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "8=D 8=D 8=D";
            name = "3 * 2 Inch";
            inches = 6;
        }
        else if (seed == 11) {
            content = "8===D 8===D";
            name = "2 * 3 Inch";
            inches = 6;
        }
        else if (seed == 12) {
            content = "8=D \u15E1=8";
            name = "Touch Tips";
            inches = 2;
        }
        else if (seed == 13) {
            content = "8====D (|)";
            name = "Lucky";
            inches = 4;
        }
        else if (seed == 14) {
            content = "8=D (|) \u15E1=8";
            name = "Double Trouble";
            inches = 2;
        }
        else if (seed == 15) {
            content = "8D (|)";
            name = "Performance Anxiety";
            inches = 0;
        }
        else if (seed == 16) {
            content = "8====D (*)";
            name = "Backdoor";
            inches = 4;
        } else {
            content = "";
            name = "None";
            inches = 0;
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine4(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "Cock";
            name = "Cock";
        }
        else if (seed == 11) {
            content = "Dick";
            name = "Dick";
        }
        else if (seed == 12) {
            content = "Johnson";
            name = "Johnson";
        }
        else if (seed == 13) {
            content = "Pecker";
            name = "Pecker";
        }
        else if (seed == 14) {
            content = "Manhood";
            name = "Manhood";
        }
        else if (seed == 15) {
            content = "Rooster";
            name = "Rooster";
        }
        else if (seed == 16) {
            content = "Wang";
            name = "Wang";
        }
        else if (seed ==  17) {
            content = "Willy";
            name = "Willy";
        } else {
            content = "Penis";
            name = "Penis";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, 0);
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

    function calculateInches(uint64[4] memory inches) private pure returns (string memory) {
        uint64 count;
        
        for (uint64 i = 0; i < 4; i++) {
            count += inches[i];
        }

        return Strings.toString(count);
    }
}