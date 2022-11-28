pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "./libraries/Property.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

//import "../lib/forge-std/src/console.sol";

contract BattleRoyaleNFTProperty is IBattleRoyaleNFTRenderer {

    using Strings for uint;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    bytes private constant _characterData = hex"18180000000000005b3532a33733a47979e8cfbf29377900000000000004924000000000000129248800000000000a4db4910000000000535238da20000000029249b71a44000000029249291a44000000029249a4924400000002926ab515440000000056d6ed6520000000000db6db6a20000000000cb6db5100000000000196db31240000000009ca38db68900000005a49b6db6db20000131a6db6db6db24000d92249b6db72db0800c92249b6db965b610019264db6b4b24b48001b32d96dacd65b48001b66db6da556db48001936db6da4d6c948001573db6db6d24a88001d6edb6dadb6db8800196ecaedadb2da88";

    bytes private constant _gunData = hex"20160000000c0c0d2e30344f4f5964647100000000000000000000120000000000000000004000a6492492492492492492c805a6d24db6e372391b6db6d005a6d24db6dc6e46e36db6d005a6d24db6dc8dc6e46db6d004929225249249249249249000929249244924924924924800125248905100a20000000000125248904900100000000000125248a00800100000000000129244924924900000000000929244924924900000000000929224000000000000000000929224000000000000000004949224000000000000000024a49224000000000000000024a49120000000000000000025249120000000000000000004a491000000000000000000009291000000000000000000009249000000000000000000000248000000000000000000";

    bytes private constant _bombData = hex"1818000000e6a8a0dd452afbbf03885e4305050718161bf6efef0000000000000000000000000000000000000000000000000080000000000000000520000000000000004924080000000000004db4400000000000248db680000000b6db0dcdb28000016ddadd2f28a400000bb5d6ddb6201000005bb6daddb7e0000002dbb6db6b6ea00000035bb6db6ff6d4000016ddb5db6ffeb40000175bb6db6df6b4000016dbb6d76db6b4000016dbb5db6df6a00000035b76db6db6a0000002eb6edb6db5000000005b6edb6db5000000000b6dbaed6800000000016db6eb40000000000005b6d000000000000000000000000000";

    bytes private constant _armorData = hex"181800000000000082796cb8b8b81718185d5f5f403c389c9c9c0000000000000000000002492492492490000014dcb97ef697420000b7d47b6daf9ea84000bf676f499ff15a40067a7fedf7dbf4aa4805c33f6fffdb7e494806293b6fb7db7e4448064d2bfff7fffe6848064dafedb6ff5b48480092676db6fff2124000004a6db6dba4800000004dffb7fda4800000004eabffd5a4800000004ed6ff6dc4800000000cdb25b4840000000009d36da4240000000063724922c4800000005bfbb7f7b8800000005fbdfeff50800000007bd21322d0800000004b9ad574c48000000009249249240000000000000000000000";

    bytes private constant _ringData = hex"1818000000010100744912d8a841e3cd8d6b8acb402908264da100000000000000000000000124924000000000000a71d7892000000000739248f62000000002a491b7ffe48000001ce48dafedbc900000e71b6d7f6cb7900000e6f249ff6db5e2400725b649ffedbebc40052589c97ffdfebc4007244029b7fff237880524402936e48dc6c80524402738db8dc88807258800e59252490800e488001c9b6e48c800e48800139a724908009cb10000726dc88800039624000e6db4400002725892766dbc4000004e4925b16da240000001d96d92691000000001276c564b1000000000009249248000000000000000000000";

    bytes private constant _foodData = hex"181800000008010199772ae0701c8f200eeebc4d1b843f00000000000000000000000000000124924920000000000949c69a840000000255adb6dda8900000155d75baebaea20000a76badb76b6ed44000db6d76daebb6ba40055b5db5db6db5da8806db6db6daed76db48055b6db6db6db6d68805576db6db6db5bd8800abb576b6db6b2a4000c996cb6daedb584004c9325adb75b93908063726d76db6da37080648dd923ae46ec8c806c694b6d92491b90806d32496a8a3721ac8065b524925124ad70800ab6db6db6dadb8400012adb6b75b6e1200000049b6badb848000000001249249200000000000000000000000";

    bytes private constant _bootsData = hex"1818000000010101251f1d3f3a3671756f56545096a49c00000000000000000000000000000000920000000000000000944004800000004904b84125100000005329488a31220000000dcdd692d9a440000001d6b494d1a44000000172d68cd1264000000032d48bd5324000000032b441d5a2000000003634419122000000002eb44175320000000171b442b5220000000a92a44171320000004c92b44259b4000012f44db493b9a20000b934a9244bb1344005591a2492415ab2400092490000015746400000000000017b4a880000000000012f4648000000000000051200000000000000049000000000000000000000";

    function _getColorString(uint red, uint green, uint blue) private pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        buffer[1] = _HEX_SYMBOLS[red & 0xf];
        buffer[0] = _HEX_SYMBOLS[(red >> 4) & 0xf];

        buffer[3] = _HEX_SYMBOLS[green & 0xf];
        buffer[2] = _HEX_SYMBOLS[(green >> 4) & 0xf];

        buffer[5] = _HEX_SYMBOLS[blue & 0xf];
        buffer[4] = _HEX_SYMBOLS[(blue >> 4) & 0xf];
        return string(buffer);
    }


    function _renderImage(bytes memory data) private pure returns (string memory r) {
        uint width = uint8(data[0]);
        uint height = uint8(data[1]);

        require(width * height % 8 == 0, "invalid size");
        
        string[8] memory colors;
        for(uint i = 1; i < 8; i++) {
            colors[i] = _getColorString(uint(uint8(data[2 + i * 3])), uint(uint8(data[2 + i * 3 + 1])), uint(uint8(data[2 + i * 3 + 2])));
        }
        uint index = 0;
        r = "";
        uint offsetX = (32 - width) / 2;
        uint offsetY = 36 - height;

        for (uint i = 26; i < data.length; i += 3) {
            uint24 tempUint;
            assembly {
                tempUint := mload(add(add(data, 3), i))
            }
            uint pixels = tempUint;
            for (uint j = 0; j < 8; j++) {
                uint x = index % width;
                uint y = index / width;
                uint d = (pixels >> (3 * (7 - j))) & 7;
                index += 1;
                if (d > 0) {
                    r = string(abi.encodePacked(r, '<rect fill="#', colors[d], '" x="', (x + offsetX).toString(), '" y="', (y + offsetY).toString(), '" width="1" height="1" />'));
                }
            }
        }
    }

    function _characterTextProperties(uint property) private pure returns (string[] memory r) {
        (uint hp, uint maxHP, uint bagCapacity) = Property.decodeCharacterProperty(property);
        r = new string[](6);
        r[0] = "HP";
        r[1] = hp.toString();

        r[2] = "Max HP";
        r[3] = maxHP.toString();

        r[4] = "Bag Capacity";
        r[5] = bagCapacity.toString();

    }

    function _gunTextProperties(uint property) private pure returns (string[] memory r) {
        (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) = Property.decodeGunProperty(property);
        r = new string[](8);
        r[0] = "Bullet Count";
        r[1] = bulletCount.toString();

        r[2] = "Shoot Range";
        r[3] = shootRange.toString();

        r[4] = "Bullet Damage";
        r[5] = bulletDamage.toString();

        r[6] = "Triple Damage Chance";
        r[7] = string(abi.encodePacked(tripleDamageChance.toString(), "%"));

    }

    function _bombTextProperties(uint property) private pure returns (string[] memory r) {
        (uint throwRange, uint explosionRange, uint damage) = Property.decodeBombProperty(property);
        r = new string[](6);
        r[0] = "Throw Range";
        r[1] = throwRange.toString();

        r[2] = "Explosion Range";
        r[3] = explosionRange.toString();

        r[4] = "Bomb Damage";
        r[5] = damage.toString();
    }

    function _armorTextProperties(uint property) private pure returns (string[] memory r) {
        (uint defense) = Property.decodeArmorProperty(property);
        r = new string[](2);
        r[0] = "Defense";
        r[1] = defense.toString();
    }

    function _ringTextProperties(uint property) private pure returns (string[] memory r) {
        (uint dodgeCount, uint dodgeChance) = Property.decodeRingProperty(property);
        r = new string[](4);
        r[0] = "Dodge Count";
        r[1] = dodgeCount.toString();

        r[2] = "Dodge Chance";
        r[3] = string(abi.encodePacked(dodgeChance.toString(), "%"));
    }

    function _foodTextProperties(uint property) private pure returns (string[] memory r) {
        (uint heal) = Property.decodeFoodProperty(property);
        r = new string[](2);
        r[0] = "Heal HP";
        r[1] = heal.toString();
    }

    function _bootsTextProperties(uint property) private pure returns (string[] memory r) {
        (uint usageCount, uint moveMaxSteps) = Property.decodeBootsProperty(property);
        r = new string[](4);
        r[0] = "Usage Count";
        r[1] = usageCount.toString();

        r[2] = "Max Move Distance";
        r[3] = moveMaxSteps.toString();
    }

    function _renderTextProperties(string[] memory properties, string memory name) private pure returns (bytes memory r) {
        r = abi.encodePacked('<text x="31" y="6" class="title">', name, '</text>');
        for (uint i = 0; i < properties.length; i += 2) {
            uint strlen = bytes(properties[i]).length + bytes(properties[i+1]).length + 1;
            strlen = strlen * 85;
            strlen = strlen % 100 == 0 ? strlen / 100 : strlen / 100 + 1;
            strlen += 2;
            r = abi.encodePacked(r, '<g style="transform:translate(1px, ', ((i / 2) * 3 + 1).toString(), 'px)"><rect width="', strlen.toString(), '" class="text-back" /><text x="1" y="1.4" class="base">', properties[i], ':',  '<tspan class="value">', properties[i+1], '</tspan></text></g>');
        }
    }

    struct MetaDataParams {
        string name;
        uint tokenId;
        string description;
        string[] textProperties;
        bytes renderData;
        string color1;
        string color2;
    }
    function _genMetadata(MetaDataParams memory p) private pure returns (string memory) {
        bytes memory svg = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 36"><style>.base { fill: rgba(255,255,255,0.6); font-family: "Courier New", monospace; font-size: 1.4px; font-weight: 600;  } .title{ fill: black; font-family: "Courier New", monospace; font-size: 2.5px; text-anchor: end;font-weight: 700 } .hint { fill: black; font-family: "Courier New", monospace; font-size: 1px; font-weight: 600; text-anchor: end; }.value{fill: white;} .text-back{ height: 2px; rx: 1px; ry:1 px; fill: rgba(0,0,0,0.6);} </style><defs><radialGradient id="RadialGradient1"><stop offset="5%" stop-color="', p.color1, '"/><stop offset="75%" stop-color="',p.color2, '" /></radialGradient></defs><circle r="32" cx="16" cy="16" fill="url(#RadialGradient1)"/><text x="31" y="2" class="hint">play at battle-royale.xyz</text>');

        svg = abi.encodePacked(svg, _renderTextProperties(p.textProperties, p.name), _renderImage(p.renderData), '</svg>');

        //console.log("svg", string(svg));
        
        bytes memory attributes = "[";
        for (uint i = 0; i < p.textProperties.length; i += 2) {
            attributes = abi.encodePacked(attributes, i == 0 ? '' : ',', '{"trait_type":"', p.textProperties[i], '","value":"', p.textProperties[i+1], '"}');
        }
        attributes = abi.encodePacked(attributes, ']');

        bytes memory d = abi.encodePacked('{"name":"', p.name, ' #', p.tokenId.toString(), '","description":"', p.description, '","image": "data:image/svg+xml;base64,', Base64.encode(svg), '","attributes":', attributes, '}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(d)));
    }

    function tokenURI(uint tokenId, uint property) external pure returns (string memory) {
        uint nftType = Property.decodeType(property);
        if (nftType == Property.NFT_TYPE_CHARACTER) {
            return _genMetadata(MetaDataParams({
                name: "Character",
                tokenId: tokenId,
                description: "Must have one Character NFT to play game",
                textProperties: _characterTextProperties(property),
                renderData: _characterData,
                color1: "#48f5ff",
                color2: "#17aabb"
            }));
        } else if (nftType == Property.NFT_TYPE_GUN) {
            return _genMetadata(MetaDataParams({
                name: "Gun",
                tokenId: tokenId,
                description: "Shoot others with the gun",
                textProperties: _gunTextProperties(property),
                renderData: _gunData,
                color1: "#f25680",
                color2: "#a43957"
            }));
        } else if (nftType == Property.NFT_TYPE_BOMB) {
            return _genMetadata(MetaDataParams({
                name: "Bomb",
                tokenId: tokenId,
                description: "Throw the bomb to kill more people",
                textProperties: _bombTextProperties(property),
                renderData: _bombData,
                color1: "#ffe557",
                color2: "#ccb745"
            }));
        } else if (nftType == Property.NFT_TYPE_ARMOR) {
            return _genMetadata(MetaDataParams({
                name: "Armor",
                tokenId: tokenId,
                description: "Wear the armor to defend",
                textProperties: _armorTextProperties(property),
                renderData: _armorData,
                color1: "#bffada",
                color2: "#98c6ad"
            }));
        } else if (nftType == Property.NFT_TYPE_RING) {
            return _genMetadata(MetaDataParams({
                name: "Ring",
                tokenId: tokenId,
                description: "Wear the ring to dodge bullets",
                textProperties: _ringTextProperties(property),
                renderData: _ringData,
                color1: "#0ec2ff",
                color2: "#087499"
            }));
        } else if (nftType == Property.NFT_TYPE_FOOD) {
            return _genMetadata(MetaDataParams({
                name: "Food",
                tokenId: tokenId,
                description: "Eat food to heal (+HP)",
                textProperties: _foodTextProperties(property),
                renderData: _foodData,
                color1: "#14b598",
                color2: "#0e826d"
            }));
        } else if (nftType == Property.NFT_TYPE_BOOTS) {
            return _genMetadata(MetaDataParams({
                name: "Boots",
                tokenId: tokenId,
                description: "Wear the boots to move further",
                textProperties: _bootsTextProperties(property),
                renderData: _bootsData,
                color1: "#f77825",
                color2: "#ab531a"
            }));
        } else {
            revert("Unknown nft type");
        }
    }

    function characterProperty(uint property) public pure returns(uint hp, uint maxHP, uint bagCapacity) {
        return Property.decodeCharacterProperty(property);
    }

    function gunProperty(uint property) public pure returns(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        return Property.decodeGunProperty(property);
    }

    function bombProperty(uint property) public pure returns(uint throwRange, uint explosionRange, uint damage) {
        return Property.decodeBombProperty(property);
    }

    function armorProperty(uint property) public pure returns(uint defense) {
        return Property.decodeArmorProperty(property);
    }

    function ringProperty(uint property) public pure returns(uint dodgeCount, uint dodgeChance) {
        return Property.decodeRingProperty(property);
    }

    function foodProperty(uint property) public pure returns(uint heal) {
        return Property.decodeFoodProperty(property);
    }

    function bootsProperty(uint property) public pure returns(uint usageCount, uint moveMaxSteps) {
        return Property.decodeBootsProperty(property);
    }
}