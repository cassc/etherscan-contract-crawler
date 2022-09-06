// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

interface ICorruptionsMetadata {
    function tokenURI(uint256 tokenId, uint256 amount) external view returns (string memory);
}

interface ICorruptionsDataMapper {
    function valueFor(uint256 mapIndex, uint256 key) external view returns (uint256);
}

interface ICorruptionsDeviationWriter {
    function drawCanvas(uint256 tokenId, uint256 amount) external pure returns (string[32] memory);
}

interface ICorruptionsFont {
    function font() external view returns (string memory);
}

interface ICorruptionsResource {
    function resource() external view returns (string memory);
}

interface ICorruptionsAscension {
    function base() external view returns (string memory);
}

struct DeviationInfo {
    string name;
    address contractAddress;
    uint256 extraData;
}

interface ICorruptionsDeviationRegistry {
    function valueFor(uint256 index) external view returns (DeviationInfo memory);
}

struct InsightMap {
    uint256 savedXP;
    uint256 lastSaveBlock;
}

interface ICorruptions {
    function insightMap(uint256 tokenID) external view returns (InsightMap memory);
    function insight(uint256 tokenID) external view returns (uint256);
    function ownerOf(uint256 tokenID) external view returns (address);
}

contract CorruptionsMetadata is Ownable, ICorruptionsMetadata {
    string public description;
    
    ICorruptionsDataMapper private dataMapper;
    ICorruptionsFont private font;
    ICorruptionsAscension private menes;
    ICorruptions private corruptions;
    ICorruptionsResource private characterResource;

    struct RandParts {
        string border;
        string corruptor;
        string phrase;
        string checker;
        bool omitInsight;
        uint16 reduction;
        bool alternate;
        uint256 r1;
        uint256 r2;
        uint256 r3;
        uint256 r4;
        string[32] colorCanvas;
    }

    constructor() Ownable() {
        description = "Unknown";
        dataMapper = ICorruptionsDataMapper(0x7A96d95a787524a27a4df36b64a96910a2fDCF5B);
        font = ICorruptionsFont(0xdf8A48979F33f12952Ab4cF6f960EA4071fc656b);
        menes = ICorruptionsAscension(0xD5192Ba5Bd9415b5e0d09633657129086a5F36c4);
        corruptions = ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E);
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setFont(address fontAddress) public onlyOwner {
        font = ICorruptionsFont(fontAddress);
    }

    function setCharacterResource(address resourceAddress) public onlyOwner {
        characterResource = ICorruptionsResource(resourceAddress);
    }

    function _blank(string[32] memory canvas, bool whitespace) public pure returns (string[32] memory) {
        if (whitespace) {
            for (uint8 i = 0; i < 32; i++) {
                canvas[i] = "&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;&#x000A0;";
            }
            return canvas;
        }
        for (uint8 i = 0; i < 32; i++) {
            canvas[i] = "&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;";
        }
        return canvas;
    }

    function _insert(bytes memory canvasLine, uint256 offset, bytes memory str, bool singleChar) pure private {
        canvasLine[offset * 9 + 0] = str[0];

        if (singleChar) {
            canvasLine[offset * 9 + 1] = "<";
            canvasLine[offset * 9 + 2] = "!";
            canvasLine[offset * 9 + 3] = "-";
            canvasLine[offset * 9 + 4] = "-";
            canvasLine[offset * 9 + 5] = " ";
            canvasLine[offset * 9 + 6] = "-";
            canvasLine[offset * 9 + 7] = "-";
            canvasLine[offset * 9 + 8] = ">";
        } else {
            canvasLine[offset * 9 + 1] = str[1];
            canvasLine[offset * 9 + 2] = str[2];
            canvasLine[offset * 9 + 3] = str[3];
            canvasLine[offset * 9 + 4] = str[4];
            canvasLine[offset * 9 + 5] = str[5];
            canvasLine[offset * 9 + 6] = str[6];
            canvasLine[offset * 9 + 7] = str[7];
            canvasLine[offset * 9 + 8] = str[8];
        }
    }

    function _box(string[32] memory canvas, string memory char, uint256 x, uint256 y, uint256 w, uint256 h, bool singleChar) public pure returns (string[32] memory) {
        bytes memory str = bytes(char);
        for (uint256 iy = 0; iy < h; iy++) {
            bytes memory canvasLine = bytes(canvas[iy + y]);
            for (uint256 ix = 0; ix < w; ix++) {
                _insert(canvasLine, ix + x, str, singleChar);
            }
        }
        return canvas;
    }

    function _checkeredBox(string[32] memory canvas, string memory char, string memory char2, uint256 x, uint256 y, uint256 w, uint256 h, bool singleChar) public pure returns (string[32] memory) {
        bytes memory str = bytes(char);
        bytes memory str2 = bytes(char2);
        for (uint256 iy = 0; iy < h; iy++) {
            bytes memory canvasLine = bytes(canvas[iy + y]);
            for (uint256 ix = 0; ix < w; ix++) {
                _insert(canvasLine, ix + x, ((iy + y) + (ix + x)) % 2 == 0 ? str : str2, singleChar);
            }
        }
        return canvas;
    }

    function _drawCircle(string[32] memory canvas, string memory char, uint256 xc, uint256 yc, uint256 x, uint256 y, bool singleChar) public pure returns (string[32] memory) { 
        bytes memory str = bytes(char);

        _insert(bytes(canvas[yc + y]), xc + x, str, singleChar);
        _insert(bytes(canvas[yc + y]), xc - x, str, singleChar);
        _insert(bytes(canvas[yc - y]), xc + x, str, singleChar);
        _insert(bytes(canvas[yc - y]), xc - x, str, singleChar);
        _insert(bytes(canvas[yc + x]), xc + y, str, singleChar);
        _insert(bytes(canvas[yc + x]), xc - y, str, singleChar);
        _insert(bytes(canvas[yc - x]), xc + y, str, singleChar);
        _insert(bytes(canvas[yc - x]), xc - y, str, singleChar);

        return canvas;
    }

    function _circle(string[32] memory canvas, string memory char, uint256 xc, uint256 yc, int8 r, bool singleChar) public pure returns (string[32] memory) {
        // https://www.geeksforgeeks.org/bresenhams-circle-drawing-algorithm/

        int256 x = 0;
        int256 y = int256(r);
        int256 d = 3 - 2 * r;
        canvas = _drawCircle(canvas, char, xc, yc, uint256(x), uint256(y), singleChar);
        while (y >= x) {
            x++;

            if (d > 0) {
                y--;
                d = d + 4 * (x - y) + 10;
            } else {
                d = d + 4 * x + 6;
            }
            canvas = _drawCircle(canvas, char, xc, yc, uint256(x), uint256(y), singleChar);
        }

        return canvas;
    }

    function _middleBox(string[32] memory canvas, string memory char, string memory char2, uint256 size, bool singleChar) public pure returns (string[32] memory) {
        canvas = _checkeredBox(canvas, char, char2, 15 - size, 15 - size, size * 2 + 1, size * 2 + 1, singleChar);
        return canvas;
    }

    function _text(string[32] memory canvas, string memory message, uint256 messageLength, uint256 x, uint256 y) public pure returns (string[32] memory) {
        bytes memory canvasLine = bytes(canvas[y]);
        for (uint256 i = 0; i < messageLength; i++) {
            _insert(canvasLine, x + i, abi.encodePacked(bytes(message)[i]), true);
        }

        return canvas;
    }

    function _richText(string[32] memory canvas, string memory message, uint256 messageLength, uint256 x, uint256 y) public pure returns (string[32] memory) {
        bytes memory canvasLine = bytes(canvas[y]);
        for (uint256 i = 0; i < messageLength / 9; i++) {
            bytes memory sequence = abi.encodePacked(abi.encodePacked(
                bytes(message)[i * 9], bytes(message)[i * 9 + 1], bytes(message)[i * 9 + 2], bytes(message)[i * 9 + 3],
                bytes(message)[i * 9 + 4], bytes(message)[i * 9 + 5]), bytes(message)[i * 9 + 6], bytes(message)[i * 9 + 7],
                bytes(message)[i * 9 + 8]
            );
            _insert(canvasLine, x + i, sequence, false);
        }

        return canvas;
    }

    function draw(uint256 tokenId, uint256 amount, string[32] memory oCanvas) public view returns (string memory) {
        string[31] memory lookup = [
            "20",
            "31",
            "42",
            "53",
            "64",
            "75",
            "86",
            "97",
            "108",
            "119",
            "130",
            "141",
            "152",
            "163",
            "174",
            "185",
            "196",
            "207",
            "218",
            "229",
            "240",
            "251",
            "262",
            "273",
            "284",
            "295",
            "306",
            "317",
            "328",
            "339",
            "350"
        ];

        string[40] memory randomStrings = [
            "/",
            "$",
            "|",
            "8",
            "_",
            "?",
            "#",
            "%",
            "^",
            "~",
            ":",

            "#022FB7",
            "#262A36",
            "#A802B7",
            "#3CB702",
            "#B76F02",
            "#B70284",

            "#0D1302",
            "#020A13",
            "#130202",
            "#1A1616",
            "#000000",
            "#040A27",
            
            "GENERATION",
            "INDIVIDUAL",
            "TECHNOLOGY",
            "EVERYTHING",
            "EVERYWHERE",
            "UNDERWORLD",
            "ILLUMINATI",
            "TEMPTATION",
            "REVELATION",
            "CORRUPTION",

            "|",
            "-",
            "=",
            "+",
            "\\",
            ":",
            "~"
        ];

        RandParts memory randParts;

        randParts.border = randomStrings[uint256(keccak256(abi.encodePacked("BORDER", tokenId))) % 11];
        randParts.corruptor = randomStrings[uint256(keccak256(abi.encodePacked("CORRUPTOR", tokenId))) % 11];
        randParts.phrase = randomStrings[23 + uint256(keccak256(abi.encodePacked("PHRASE", tokenId))) % 10];
        randParts.checker = randomStrings[33 + uint256(keccak256(abi.encodePacked("CHECKER", tokenId))) % 7];

        string[32] memory canvas;


        if (bytes(oCanvas[0]).length > 32) {
            canvas = _blank(canvas, false);

            randParts.omitInsight = true;
            randParts.reduction = 64 + uint8(bytes(oCanvas[0])[tokenId % 32]);
            randParts.alternate = true;

            for (uint256 i = 0; i < 32; i++) {
                canvas = _richText(canvas, oCanvas[i], bytes(oCanvas[i]).length, 0, i);
            }

        } else if (bytes(oCanvas[0]).length > 0) {
            canvas = _blank(canvas, false);

            randParts.omitInsight = true;
            randParts.reduction = 64;

            for (uint256 i = 0; i < 32; i++) {
                canvas = _text(canvas, oCanvas[i], bytes(oCanvas[i]).length, 0, i);
            }

        } else {
            canvas = _blank(canvas, false);

            canvas = _box(canvas, randParts.border, 0, 0, 31, 1, true);
            canvas = _box(canvas, randParts.border, 0, 30, 31, 1, true);
            canvas = _box(canvas, randParts.border, 0, 0, 1, 31, true);
            canvas = _box(canvas, randParts.border, 30, 0, 1, 31, true); 

            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[0])), 15, 15, 12, true);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[1])), 15, 15, 11, true);

            if (amount < 20) {
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[2])), 15, 15, 10, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[3])), 15, 15, 9, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[4])), 15, 15, 8, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[5])), 15, 15, 7, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[6])), 15, 15, 6, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[7])), 15, 15, 5, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[8])), 15, 15, 4, true);
                canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[9])), 15, 15, 3, true);
            }
        }

        uint256 iterations = uint256(keccak256(abi.encodePacked("CORRUPTION", tokenId))) % 1024;
        if (randParts.reduction > 0) {
            iterations = iterations % randParts.reduction;
        }
        for (uint256 i = 0; i < iterations; i++) {
            if (randParts.alternate && i % 2 == 0) {
                canvas = _box(canvas, randParts.border, uint256(keccak256(abi.encodePacked("X", i, tokenId))) % 30, uint256(keccak256(abi.encodePacked("Y", i, tokenId))) % 30, 1, 1, true);
            } else {
                canvas = _box(canvas, randParts.corruptor, uint256(keccak256(abi.encodePacked("X", i, tokenId))) % 30, uint256(keccak256(abi.encodePacked("Y", i, tokenId))) % 30, 1, 1, true);
            }
        }

        if (!randParts.omitInsight) {
            uint256 length = 8 + bytes(toString(amount)).length;
            canvas = _text(canvas, string(abi.encodePacked("INSIGHT ", toString(amount))), length, 31 - length, 30);


            for (uint i = 10; i > 0; i--) { 
                if (amount >= i * 2) {
                    canvas = _middleBox(canvas, string(abi.encodePacked(bytes(randParts.phrase)[i - 1])), randParts.checker, i, true);
                }
            }
        }

        string memory output = "";
        randParts.r4 = amount >= 20 && bytes(oCanvas[0]).length == 0 ? 1 : 0;

        string[12] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 820 1460"><style>@font-face { font-family: CorruptionsFont; src: url("';
        if (randParts.r4 > 0) {
            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1640 1460"><style>@font-face { font-family: CorruptionsFont; src: url("';
        }
        parts[1] = font.font();
        parts[2] = '") format("opentype"); } .base { fill: ';
        parts[3] = randomStrings[11 + uint256(keccak256(abi.encodePacked("BGCOLOR", tokenId))) % 6];
        parts[4] = '; font-family: CorruptionsFont; font-size: 10px; }</style><g transform=\"scale(4 4)\"><rect width="205" height="365" fill="';
        if (randParts.r4 > 0) {
            parts[4] = '; font-family: CorruptionsFont; font-size: 10px; }</style><g transform=\"scale(4 4)\"><rect width="410" height="365" fill="';
        }
        parts[5] = amount >= 2 ? randomStrings[17 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6] : randomStrings[27 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6];
        parts[6] = '" />';
        parts[7] = "";
        parts[8] = "";
        parts[9] = "";
        parts[10] = ""; 
        parts[11] = '</g></svg>';

        if (randParts.r4 > 0) {
            randParts.colorCanvas = _blank(randParts.colorCanvas, true);

            iterations = amount / 4;
            for (uint256 i = 0; i < iterations; i++) {
                randParts.r1 = uint256(keccak256(abi.encodePacked("X2", i, tokenId))) % 30;
                randParts.r2 = uint256(keccak256(abi.encodePacked("Y2", i, tokenId))) % 29;
                randParts.colorCanvas = _box(randParts.colorCanvas, i % 2 == 0 ? randParts.border : randParts.corruptor, randParts.r1, randParts.r2, 1, 1, true);
                canvas = _box(canvas, "&#x000A0;", randParts.r1, randParts.r2, 1, 1, false);
            }

            for (uint8 i = 0; i < 30; i++) {
                parts[9] = randomStrings[11 + ((tokenId + i) * i * 41) % 6];
                parts[8] = string(abi.encodePacked(
                    parts[8], '<text x="10" y="', lookup[i], '" class="base" style="fill: ', parts[9], '">', randParts.colorCanvas[i], '</text>'
                ));
            }

            parts[9] = "";

            // randParts.colorCanvas = _blank(randParts.colorCanvas, true);
            randParts.colorCanvas = _box(randParts.colorCanvas, "|", 0, 0, 31, 1, true);
            randParts.colorCanvas = _box(randParts.colorCanvas, "|", 0, 0, 1, 6, true);
            randParts.colorCanvas = _box(randParts.colorCanvas, "|", 30, 0, 1, 6, true);
            randParts.colorCanvas = _box(randParts.colorCanvas, "|", 0, 5, 31, 1, true);
            randParts.colorCanvas = _text(randParts.colorCanvas, " CONCEPTS ", 10, 2, 0);
            randParts.colorCanvas = _text(randParts.colorCanvas, string(abi.encodePacked("+ ", randParts.phrase)), 12, 2, 2);
            randParts.colorCanvas = _text(randParts.colorCanvas, string(abi.encodePacked("+ ", randomStrings[27 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6])), 12, 2, 3);

            for (uint8 i = 0; i < 6; i++) {
                parts[9] = string(abi.encodePacked(
                    parts[9], '<text x="10" y="', lookup[i], '" class="base">', randParts.colorCanvas[i], '</text>'
                ));
            }

            // parts[9] = string(abi.encodePacked(
            //     '<g transform=\"translate(200 0)\">', parts[9], '</g>'
            // ));
        }

        for (uint8 i = 0; i < 31; i++) {
            output = string(abi.encodePacked(
                output, '<text x="10" y="', lookup[i], '" class="base">', canvas[i], '</text>'
            ));
        }

        parts[7] = output;

        if (!randParts.omitInsight && amount >= 20) {
            parts[10] = characterResource.resource();
        }

        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], '<g transform=\"translate(200 0)\">', parts[9], '</g>', parts[10], parts[11]));
        return Base64.encode(bytes(output));
    }

    function tokenURI(uint256 tokenId, uint256 amount) override external view returns (string memory) {
        InsightMap memory insightMap = corruptions.insightMap(tokenId);

        if (insightMap.lastSaveBlock <= 13604851 && tokenId != 3193) {
            amount += 1; // fix early transfer bug
        }
        
        string memory json;
        string[32] memory emptyCanvas;
        
        if (tokenId == 4144) {
            // hard-coding since bidirectional data mapper wasn't used in expected way. expected key 0 to == the token id, but this wasn't explained
            // will explain better next time it's needed (or perhaps just code the inputs into the respective contract directly)
            json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), ' (Menes, Goddess of Kingdoms)", "description": "', description, '", "image": "', menes.base(), '", "attributes": [{"trait_type": "Type", "value": "???"}]}'))));
        } else if (dataMapper.valueFor(0, tokenId) > 0) {
            DeviationInfo memory info = ICorruptionsDeviationRegistry(0x40f7ad19c7F37AcD76958d61Cbc783c77411cd9b).valueFor(dataMapper.valueFor(0, tokenId));
            json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), '", "description": "', description, '", "image": "data:image/svg+xml;base64,', draw(tokenId, amount, ICorruptionsDeviationWriter(info.contractAddress).drawCanvas(tokenId, amount)), '", "attributes": [{"trait_type": "Deviation", "value": "', info.name, '"}]}'))));
        } else {
            json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), '", "description": "', description, '", "image": "data:image/svg+xml;base64,', draw(tokenId, amount, emptyCanvas), '", "attributes": [{"trait_type": "Insight", "value": "', toString(amount), '"}]}'))));
        }
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint i) internal pure returns (string memory) {
        // https://stackoverflow.com/a/69302348/424107
        
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}