// SPDX-License-Identifier: MIT

/*********************************
*                                *
*            (o.O)               *
*           (^^^^^)              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./IMonstersDecoder.sol";

contract MonstersDecoder is IMonstersDecoder {
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
        uint256[6] memory colors = [seed % 10000000000000000000000 / 100000000000000000000, seed % 1000000000000000000 / 10000000000000000, seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory head = getHead(seed / 10000000000000000000000, colors[0]);
        Trait memory face = getFace(seed % 100000000000000000000 / 1000000000000000000, colors[1]);
        Trait memory mouth = getMouth(seed % 10000000000000000 / 100000000000000, colors[2]);
        Trait memory neck = getNeck(seed % 1000000000000 / 10000000000, colors[3]);
        Trait memory body = getBody(seed % 100000000 / 1000000, colors[4]);
        Trait memory feet = getFeet(seed % 10000 / 100, colors[5]);
        uint256 neckSeed = seed % 1000000000000 / 10000000000;
        bool noNeck = neckSeed == 10 || neckSeed == 11 || neckSeed == 12;
        uint256 neckValue = 0;
        if (noNeck) {
            colors[3] = 0;
            neckValue = 1;
        }
        uint256 colorCount = calculateColorCount(colors) - neckValue;
        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                head.content,
                face.content,
                mouth.content,
                neck.content,
                body.content,
                feet.content,
                '</text>',
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = 'Monsters Club';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"Monster #', tokenId.toString(), '",',
                            '"description":"', description, '",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Head", "value": "', head.name,' (',head.color.name,')', '"},',
                            '{"trait_type": "Face", "value": "', face.name,' (',face.color.name,')', '"},',
                            '{"trait_type": "Body", "value": "', body.name,' (',body.color.name,')', '"},',
                            '{"trait_type": "Mouth", "value": "', mouth.name,' (',mouth.color.name,')', '"},',
                            '{"trait_type": "Neck", "value": "', neck.name,' (',neck.color.name,')', '"},',
                            '{"trait_type": "Feet", "value": "', feet.name,' (',feet.color.name,')', '"},',
                            '{"trait_type": "Colors", "value": ', colorCount.toString(), '}',
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

        return Color('','');
    }

    function getHead(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "'--'";
            name = "Ears";
        }
        if (seed == 11) {
            content = "---";
            name = "Bald";
        }
        if (seed == 12) {
            content = "$___$";
            name = "Pigtails";
        }
        if (seed == 13) {
            content = "///";
            name = "Punk Right";
        }
        if (seed == 14) {
            content = "***";
            name = "Short Hair";
        }
        if (seed == 15) {
            content = "(___)";
            name = "Horns";
        }
        if (seed == 16) {
            content = "~~~";
            name = "Curly Hair";
        }
        if (seed == 17) {
            content = '\\|/';
            name = 'Spikes';
        }
        if (seed == 18) {
            content = '|';
            name = 'Punk Crest';
        }
        if (seed == 19) {
            content = '|||';
            name = 'Standing Spikes';
        }
        if (seed == 20) {
            content = '(((';
            name = 'Left Curve Hair';
        }
        if (seed == 21) {
            content = ')))';
            name = 'Right Curve Hair';
        }
        if (seed == 22) {
            content = '(_^_)';
            name = 'Viking Helmet';
        }
        if (seed == 23) {
            content = '([email protected]_)';
            name = 'Hypnotic Hat';
        }
        if (seed == 24) {
            content = '(_0_)';   
            name = 'Third eye';
        }
        if (seed == 25) {
            content = '(_|_)';
            name = 'Crown';
        }
        if (seed == 26) {
            content = '\\|||/';
            name = 'Crazy Spikes';
        }
        if (seed == 27) {
            content = '|-|-|';
            name = 'Crown of Thorns';
        }
        if (seed == 28) {
            content = '\u00ba\u00ba\u00ba';
            name = 'Small Curly Hair';
        }
        if (seed == 29) {
            content = "\\\\";
            name = "Punk Left";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFace(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "(o.o)";
            name = "Classic";
        }
        if (seed == 11) {
            content = "(-.-)";
            name = "Sleeping";
        }
        if (seed == 12) {
            content = "(o.-)";
            name = "Wink";
        }
        if (seed == 13) {
            content = "(o.O)";
            name = "Suspicious";
        }
        if (seed == 14) {
            content = "(0.0)";
            name = "Wide-eyed";
        }
        if (seed == 15) {
            content = "(o-o)";
            name = "Glasses";
        }
        if (seed == 16) {
            content = "(*.*)";
            name = "Stunned";
        }
        if (seed == 17) {
            content = "()...()";
            name = "Frog Wide Eyes";
        }
        if (seed == 18) {
            content = "(~.~)";
            name = "Dizzy";
        }
        if (seed == 19) {
            content = "(\u00ac.\u00ac)";
            name = "Sarcastic";
        }
        if (seed == 20) {
            content = "0...0";
            name = "Frog";
        }
        if (seed == 21) {
            content = "(@[email protected])";
            name = "Hypno";
        }

        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getMouth(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "\u0028\u221e\u221e\u221e\u221e\u221e\u0029";
            name = "Zipped Lips";
        }
        if (seed == 11) {
            content = "\u0028\u005e\u00b4\u005e\u00b4\u005e\u0029";
            name = "Three Fangs";
        }
        if (seed == 12) {
            content = "\u0028\u00b7\u00b7\u00b7\u00b7\u00b7\u0029";
            name = "Double Teeth";
        }
        if (seed == 13) {
            content = "(\"\"\"\"\")";
            name = "Buck Teeth";
        }
        if (seed == 14) {
            content = "(^^^^^)";
            name = "Upper Fangs";
        }
        if (seed == 15) {
            content = "(=====)";
            name = "Biting";
        }
        if (seed == 16) {
            content = "(vvvvv)";
            name = "Fangs";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getNeck(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 y = 25;
        if (seed == 10 || seed == 11 || seed == 12) {
            return Trait("", "None", Color("None", "None"));
        }
        if (seed == 13) {
            content = "|^|";
            name = "Adam's apple";
        }
        if (seed == 14) {
            content = "| |";
            name = "Classic";
        }
        if (seed == 15) {
            content = "|o|";
            name = "Neck Hole";
        }
        if (seed == 16) {
            content = "|=|";
            name = "Turtleneck";
        }
        if (seed == 17) {
            content = "|.|";
            name = "Mole";
        }

        return Trait(string(abi.encodePacked('<tspan dy="',y.toString(),'" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getBody(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 y = 25;
        if (seed == 10) {
            content = "{'\"'}";
            name = "Suit";
        }
        if (seed == 11) {
            content = "//{\\S/}\\\\";
            name = "Super Monster";
        }
        if (seed == 12) {
            content = "{=|=}";
            name = "Jacket";
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
            name = "Tuxedo";
        }
        if (seed == 17) {
            content = "\u002f\u002d\u0028\u005c\u002a\u002f\u0029\u002d\u005c";
            name = "Small Wings";
        }
        if (seed == 18) {
            content = "\u0028\u005c\u007e\u002f\u0029";
            name = "Classic Tuxedo";
        }

        return Trait(string(abi.encodePacked('<tspan dy="',y.toString(),'" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFeet(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 y;
        if (seed == 10) {
            content = "(\") (\")";
            name = "Sitting";
            y = 30;
        }
        if (seed == 11) {
            content = "^   ^";
            name = "Small Feets";
            y = 30;
        }
        if (seed == 12) {
            content = "(^) (^)";
            name = "Claws";
            y = 30;
        }
        if (seed == 13) {
            content = "\u0028\u00a8\u0029 \u0028\u00a8\u0029";
            name = "Small Claws";
            y = 30;
        }

        return Trait(string(abi.encodePacked('<tspan dy="',y.toString(),'" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function calculateColorCount(uint256[6] memory colors) private pure returns (uint256) {
        uint256 count;

        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = 0; j < 6; j++) {
                if (colors[i] == colors[j]) {
                    count++;
                }
            }       
        }

        if (count == 6) {
            return 6;
        }

        if (count == 8) {
            return 5;
        }

        if (count == 10 || count == 12) {
            return 4;
        }

        if (count == 18 || count == 14) {
            return 3;
        }

        if (count == 26 || count == 20 || count == 18) {
            return 2;
        }

        if (count == 36) {
            return 1;
        }

        return 0;
    }
}