// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               0,0              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import './base64.sol';
import "./IPepeDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PepeDescriptorV1 is IPepeDescriptor {
    struct Color {
        string value;
        string name;
    }
    struct Trait {
        string content;
        string name;
        Color color;
    }
    struct Pepe {
        Trait ear;
        Trait eye;
        Trait face;
        Trait neck;
        Trait body;
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

        Pepe memory pepe = Pepe(
                         
            getEar(seed / 1000000000000000000, seed % 1000000000000000000 / 10000000000000000),
            getEye(seed % 10000000000000000 / 100000000000000, seed % 100000000000000 / 1000000000000),
            getFace(seed % 1000000000000 / 10000000000, seed % 10000000000 / 100000000),
            getNeck(seed % 100000000 / 1000000, seed % 1000000 / 10000),
            getBody(seed % 10000 / 100, seed % 100)
        );

        string memory rawSvg = generateRawSvg(pepe);
        string memory encodedSvg = Base64.encode(bytes(rawSvg));

        Trait[5] memory traits = [pepe.ear, pepe.eye, pepe.face, pepe.neck, pepe.body];

        string memory attributes = generateAttributeString(traits);

        attributes = string(
            abi.encodePacked(attributes, 
                    '{"trait_type": "Colors", "value": ', colorCount, '}',']')
        );

    string memory metadata = generateMetadata(tokenId, encodedSvg, attributes);

    return metadata;
    }

    function generateAttributeString(Trait[5] memory traits) internal pure returns (string memory) {
        string memory attributes;
        string memory traitType;

        attributes = string(
            abi.encodePacked("[")
        );

        for (uint i = 0; i < traits.length; i++) {
            if (i == 0) {
                traitType = "Head";
            } else if (i == 1) {
                traitType = "Eye";
            } else if (i == 2) {
                traitType = "Face";
            } else if (i == 3) {
                traitType = "Neck";
            } else if (i == 4) {
                traitType = "Body";
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

    function generateRawSvg(Pepe memory pepe) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                pepe.ear.content,
                pepe.eye.content,
                pepe.face.content,
                pepe.neck.content,
                pepe.body.content,
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
                    '"name":"Neon Pepe #', tokenId.toString(), '",',
                    '"description":"', 'Pepe', '",',
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

    function getEar(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "|&#92;_&#47;|";
            name = "Normal";
        }
        if (seed == 11) {
            content = "=&#92&#92_&#47;&#47;=";
            name = "Samurai";
        }
        if (seed == 12) {
            content = "|&gt;_&lt;|";
            name = "Shy";
        }
        if (seed == 13) {
            content = "0&#92;_&#47;o";
            name = "Naughty";
        }
        if (seed == 14) {
            content = "-&#92;_&#47;-";
            name = "Sleepy";
        }
        if (seed == 15) {
            content = "~&#92;_&#47;~";
            name = "Fluffy";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getEye(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "'&#47; @ @ &#92'";
            name = "Dizzy";
        }
        if (seed == 11) {
            content = "&#47; &gt; &lt; &#92;";
            name = "Sad";
        }
        if (seed == 12) {
            content = "&#47; 0 - &#92;";
            name = "Wink";
        }
        if (seed == 13) {
            content = "{ ? ? }";
            name = "Wut";
        }
        if (seed == 14) {
            content = "{ $ $ }";
            name = "$$$";
        }
        if (seed == 15) {
            content = "{ | | }";
            name = "Cry";
        }
        if (seed == 16) {
            content = "{ P P }";
            name = "Sneaky";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160"  fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getFace(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "( + - + )";
            name = "Shy";
        }
        if (seed == 11) {
            content = "( &gt; - &lt; )";
            name = "Close";
        }
        if (seed == 12) {
            content = "( &gt; 3 &lt; )";
            name = "Love";
        }
        if (seed == 13) {
            content = "( &gt; ^ &lt; )";
            name = "Sad";
        }
        if (seed == 14) {
            content = "( = B = )";
            name = "Eating";
        }
        if (seed == 15) {
            content = "( o - o )";
            name = "Flattered";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getNeck(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint256 x;
        
        if (seed == 10) {
            content = "`&gt;&gt;x&lt;&lt;`";
            name = "bell";
            x = 160;
        }
        if (seed == 11) {
            content = "&#92;=&#47; `     ` &#92;=&#47;";
            name = "SuperPepe";
            x = 160;

        }
        if (seed == 12) {
            content = "`o ~ o`~~~";
            name = "Pepe Cape";
            x = 180;

        }
        if (seed == 13) {
            content = "`~^~`";
            name = "Tie";
            x = 160;

        }
        if (seed == 14) {
            content = "`$G$`";
            name = "GoldChain";
            x = 160;

        }
        if (seed == 15) {
            content = "`^ w ^`";
            name = "Suit";
            x = 160;
        }


        return Trait(string(abi.encodePacked('<tspan dy="25" x="', x.toString(),'" fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function getBody(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "&#47; PEPE  &#92;";
            name = "Pepe Tattoo";
        }
        if (seed == 11) {
            content = "&#47;  O  &#92;";
            name = "Normal";
        }
        if (seed == 12) {
            content = "&#47; BTC  &#92;";
            name = "BTC";
        }
        if (seed == 13) {
            content = "&#47; ETH  &#92;";
            name = "ETH";
        }
        if (seed == 14) {
            content = "&#47;  O  &#92;";
            name = "Normal";
        }
        if (seed == 15) {
            content = "&#47;  O  &#92;";
            name = "Normal";
        }
        if (seed == 16) {
            content = "&#47;  O  &#92;";
            name = "Normal";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color);
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