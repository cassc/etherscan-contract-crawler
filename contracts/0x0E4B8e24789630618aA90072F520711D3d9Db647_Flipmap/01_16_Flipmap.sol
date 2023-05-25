// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../blitmaps/contracts/Blitmap.sol";

contract Flipmap is ERC721, ReentrancyGuard {

    uint256 public _tokenId = 1700;

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;
    mapping(address => uint256) private _creators;

    address sara    = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address lambo   = 0xafBDEc0ba91FDFf03A91CbdF07392e6D72d43712;
    address dev     = 0xE424E566BFc3f7aDDFfb17862637DD61e2da3bE2;

    Blitmap blitmap;

    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address _blitAddress) ERC721("Flipmap", "FLIP") {
        _owner = msg.sender;
        blitmap = Blitmap(_blitAddress);
    }

    function transferOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenId - 1700;
    }

    function savePairs(uint256[][] memory pairHashes) public onlyOwner {
        for(uint256 i=0; i<pairHashes.length; i++) {
            bytes32 pairHash = keccak256(abi.encodePacked(pairHashes[i][0], '-', pairHashes[i][1]));
            _tokenPairs[pairHash] = true;
        }
    }

    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public nonReentrant payable {
        require(msg.value == 0.03 ether);
        require(tokenIdA != tokenIdB, "b:08");
        require(blitmap.tokenIsOriginal(tokenIdA) && blitmap.tokenIsOriginal(tokenIdB), "b:10");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");

        uint256 variantTokenId = _tokenId;
        _tokenId++;

        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;

        address creatorA = blitmap.tokenCreatorOf(tokenIdA);
        address creatorB = blitmap.tokenCreatorOf(tokenIdB);

        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);

        _creators[creatorA]     += .0065625 ether;
        _creators[creatorB]     += .0009375 ether;
        _creators[sara]         += .0075 ether;
        _creators[lambo]        += .0075 ether;
        _creators[dev]          += .0075 ether;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _creators[creatorAddress];
    }

    function withdrawAvailableBalance() public nonReentrant {
        uint256 withdrawAmount = _creators[msg.sender];
        _creators[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function getByOwner(address owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(owner));
        uint256 resultIndex = 0;
        for (uint256 t = 0; t < _tokenId; t++) {
            if (_exists(t) && ownerOf(t) == owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function pairIsTaken(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        return _tokenPairs[pairHash];
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenId;
    }

    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        if(tokenId < 1700) {
            return blitmap.tokenIsOriginal(tokenId);
        }
        return false;
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        if (tokenId < 1700) {
            return blitmap.tokenDataOf(tokenId);
        }

        bytes memory tokenParentData;
        if(_exists(tokenId)) {
            tokenParentData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdA);
            bytes memory tokenPaletteData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdB);
            for (uint8 i = 0; i < 12; ++i) {
                // overwrite palette data with parent B's palette data
                tokenParentData[i] = tokenPaletteData[i];
            }
        }

        return tokenParentData;
    }

    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
            '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',

            string(abi.encodePacked(
                '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
            ))
        ));
    }

    function parentSvgDataOf(uint256 tokenIdA, uint256 tokenIdB) public view returns (string memory) {
        bytes memory tokenParentData = blitmap.tokenDataOf(tokenIdA);
        bytes memory tokenPaletteData = blitmap.tokenDataOf(tokenIdB);
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }
        return tokenSvgData(tokenParentData);
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        bytes memory data = tokenDataOf(tokenId);
        return tokenSvgData(data);
    }

    function tokenSvgData(bytes memory data) public pure returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1000 1000"><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32" shape-rendering="crispEdges"><g transform="translate(32, 0) scale(-1,1)">';

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        SVGCursor memory pos;

        string[4] memory colors = [
        string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
        string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
        string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
        string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))
        ];

        string[8] memory p;

        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;

            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</g></svg></svg>"));
        return svgString;
    }

    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }

    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        bytes memory data = tokenDataOf(tokenId);
        BlitmapAnalysis.Colors memory rgb = BlitmapAnalysis.tokenRGBColorsOf(data);

        string[4] memory chars = [unicode"◢", unicode"◣", unicode"◤", unicode"◥"];
        string[4] memory slabs;

        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];

        return slabs;
    }

    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }

    function makeAttributes(uint256 tokenId) public view returns (string memory attributes) {
        string[5] memory traits;

        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        traits[0] = '{"trait_type":"Type","value":"Flipling"}';
        traits[1] = string(abi.encodePacked('{"trait_type":"Composition","value":"', blitmap.tokenNameOf(parentA), ' (#', toString(parentA), ')"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Palette","value":"', blitmap.tokenNameOf(parentB), ' (#', toString(parentB), ')"}'));

        string[3] memory affinity = tokenAffinityOf(tokenId);
        traits[3] = string(abi.encodePacked('{"trait_type":"Affinity","value":"', affinity[0]));
        if(bytes(affinity[1]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[1]));
        }
        if(bytes(affinity[2]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[2]));
        }
        traits[3] = string(abi.encodePacked(traits[3], '"}'));

        string[4] memory slabs = tokenSlabsOf(tokenId);
        traits[4] = string(abi.encodePacked('{"trait_type":"Slabs","value":"', slabs[0], ' ', slabs[1], ' ', slabs[2], ' ', slabs[3], '"}'));

        attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        string memory name = string(abi.encodePacked('#', toString(tokenId), ' - ', blitmap.tokenNameOf(parentA), ' ', blitmap.tokenNameOf(parentB)));
        string memory description = 'Flipmaps are the lost 8,300 Blitmaps, only flipped.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(tokenSvgDataOf(tokenId)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId), ']}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function toString(uint256 value) public pure returns (string memory) {
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
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}