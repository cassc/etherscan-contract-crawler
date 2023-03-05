// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import './base64.sol';
import "./IApeDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ApeDescriptor is IApeDescriptor {
    struct Color {
        string value;
        string name;
    }
    struct Trait {
        string content;
        string name;
        Color color;
    }
    struct Ape {
        Trait head;
        Trait head2;
        Trait eyes;
        Trait nose;
        Trait mouth;
        Trait mouth2;
    }
    
    using Strings for uint256;

    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
        // uint256[5] memory colors = [seed % 1000000000000000000 / 10000000000000000, seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        // Trait memory ear = getEar(seed / 1000000000000000000, colors[0]);
        // Trait memory eye = getEye(seed / 100000000000000, colors[1]);
        // Trait memory face = getFace(seed % 1000000000000 / 10000000000, colors[2]);
        // Trait memory neck = getNeck(seed % 100000000 / 1000000, colors[3]);
        // Trait memory body = getBody(seed % 10000 / 100, colors[4]);
        string memory colorCount = calculateColorCount(seed);

        Ape memory ape = Ape(
            getHead(seed % 10000000000000000 / 100000000000000, seed % 100000000000000 / 1000000000000),
            getHead2(seed % 10000000000000000 / 100000000000000, seed % 100000000000000 / 1000000000000),
            getEyes(seed % 1000000000000 / 10000000000, seed % 10000000000 / 100000000),
            getNose(seed % 100000000 / 1000000, seed % 1000000 / 10000),
            getMouth(seed % 10000 / 100, seed % 100),
            getMouth2(seed % 10000 / 100, seed % 100)
        );

        string memory rawSvg = generateRawSvg(ape);
        string memory encodedSvg = Base64.encode(bytes(rawSvg));

        Trait[6] memory traits = [ape.head, ape.head2, ape.eyes, ape.nose, ape.mouth, ape.mouth2];

        string memory attributes = generateAttributeString(traits);

        attributes = string(
            abi.encodePacked(attributes, 
                    '{"trait_type": "Colors", "value": ', colorCount, '}',']')
        );

    string memory metadata = generateMetadata(tokenId, encodedSvg, attributes);

    return metadata;
    }

    function generateAttributeString(Trait[6] memory traits) internal pure returns (string memory) {
        string memory attributes;
        string memory traitType;

        attributes = string(
            abi.encodePacked("[")
        );

        for (uint i = 0; i < traits.length; i++) {
            if (i == 0) {
                traitType = "Head";
            } else if (i == 1) {
                traitType = "Eyes";
            } else if (i == 2) {
                traitType = "Nose";
            } else if (i == 3) {
                traitType = "Mouth";
            }
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "', traitType, '", "value": "', traits[i].name, ' (', traits[i].color.name, ')"},'
            )
        );
    }
        return attributes;
    }

    function getInnerSVG(Ape memory ape) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                ape.head.content,
                ape.head2.content,
                ape.eyes.content,
                ape.nose.content,
                ape.mouth.content,
                ape.mouth2.content
            )
        );
    }

    function generateRawSvg(Ape memory ape) internal pure returns (string memory) {
        string memory innerSVG = getInnerSVG(ape);
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="100" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                innerSVG,
                '</text>',
                SVG_END_TAG
            )
        );
    }

    function generateMetadata(uint256 tokenId, string memory encodedSvg, string memory attributes) internal pure returns (string memory) {
        
            return string(
        abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{',
                        '"name":"Ape #', tokenId.toString(), '",',
                        '"description":"', '5555 Apes. All ASCII, all on-chain.', '",',
                        '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                        '"attributes": ', attributes,
                        '}'
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

        return Color('','');
    }

    function getHead(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        
        // Default
        content = "^^^^^";
        name = "Hairy";

        if (seed == 8) {
            content = "0-0-0";
            name = "Textured";
        }
        if (seed == 9) {
            content = "<--->";
            name = "Thin";
        }
        if (seed == 10) {
            content = "{___}";
            name = "Wrinkly";
        }
        if (seed == 11) {
            content = "(___)";
            name = "Bald";
        }
        if (seed == 12) {
            content = "VVVVV";
            name = "Crown";
        }
        if (seed == 13) {
            content = "#___#";
            name = "Pigtails";
        }
        if (seed == 14) {
            content = "!!!!!";
            name = "Spiky";
        }
        if (seed == 15) {
            content = "/////";
            name = "Comb Over";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getHead2(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content2;
        string memory name;
        content2 = '_/.-.-.\\_';

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content2, '</tspan>')), name, color);
    }

    function getEyes(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        
        // Default
        content = "( ( o o ) )";
        name = "Normal";

        if (seed == 8) {
            content = "( ( ~ ~ ) )";
            name = "Surprised";
        }
        if (seed == 9) {
            content = "( ( W W ) )";
            name = "Sleeping";
        }
        if (seed == 10) {
            content = "( ( O o ) )";
            name = "WTF";
        }
        if (seed == 11) {
            content = "( ( L L ) )";
            name = "Sleepy";
        }
        if (seed == 12) {
            content = "( ( x x ) )";
            name = "X eyes";
        }
        if (seed == 13) {
            content = "( ( - - ) )";
            name = "Dissapointed";
        }
        if (seed == 14) {
            content = "( ( O = ) )";
            name = "Winky";
        }
        if (seed == 15) {
            content = "( ( @ @ ) )";
            name = "Dizzy";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getNose(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        
        // Default
        content = "|/  \"  \\|";
        name = "Nostrils";

        if (seed == 7) {
            content = "|/  `  \\|";
            name = "Tiny";
        }
        if (seed == 8) {
            content = "|/  :  \\|";
            name = "Dotted";
        }
        if (seed == 9) {
            content = "|/  =  \\|";
            name = "Equal";
        }
        if (seed == 10) {
            content = "|/  ^  \\|";
            name = "Smol";
        }
        if (seed == 11) {
            content = "|/  *  \\|";
            name = "Round";
        }
        if (seed == 12) {
            content = "|/  -  \\|";
            name = "Dash";
        }
        if (seed == 13) {
            content = "|/  L  \\|";
            name = "Big";
        }
        if (seed == 14) {
            content = "|/  +  \\|";
            name = "Plus";
        }
        if (seed == 15) {
            content = "|/  ^  \\|";
            name = "Pointy";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getMouth(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;

        // Default
        content = "\\ ___ /";
        name = "Flat";
        
        if (seed == 7) {
            content = "\\ ETH /";
            name = "ETH";
        }
        if (seed == 8) {
            content = "\\ |_| /";
            name = "Cringing";
        }
        if (seed == 9) {
            content = "\\ ,_, /";
            name = "Serious";
        }
        if (seed == 10) {
            content = "\\  u  /";
            name = "Cute";
        }
        if (seed == 11) {
            content = "\\ ^^^ /";
            name = "Teeth";
        }
        if (seed == 12) {
            content = "\\ === /";
            name = "Lips";
        }
        if (seed == 13) {
            content = "\\ <+> /";
            name = "Open";
        }
        if (seed == 14) {
            content = "\\ ~~~ /";
            name = "Scared";
        }
        if (seed == 15) {
            content = "\\ {_} /";
            name = "Yelling";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getMouth2(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content2;
        string memory name;
        content2 = '`"""`';

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content2, '</tspan>')), name, color);
    }

    function calculateColorCount(uint256 seed) private pure returns (string memory) {
        uint256[5] memory colors = [seed % 1000000000000000000 / 10000000000000000, seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];

        uint256 count = 0;
        uint256 foundColors = 0;
        uint256 i;
        for (i = 0; i < 5; i++) {
            uint256 j;
            for (j = 0; j < i; j++) {
                if (colors[i] == colors[j]) {
                    foundColors |= (1 << i);
                    break;
                }
            }
            if ((foundColors & (1 << i)) == 0) {
                count += 1;
            }
        }
        return count.toString();
    }
}