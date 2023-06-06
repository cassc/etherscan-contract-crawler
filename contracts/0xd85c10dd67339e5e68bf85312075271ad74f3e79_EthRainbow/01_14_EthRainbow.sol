// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthRainbow is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 constant MAX_TOKENS = 6000;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        return getColors(tokenId, "FIRST");
    }

    function getSecond(uint256 tokenId) public pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        return getColors(tokenId, "SECOND");
    }

    function getThird(uint256 tokenId) public pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        return getColors(tokenId, "THIRD");
    }

    function getFourth(uint256 tokenId) public pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        return getColors(tokenId, "FOURTH");
    }

    function getFifth(uint256 tokenId) public pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        return getColors(tokenId, "FIFTH");
    }

    function getColors(
        uint256 tokenId,
        string memory keyPrefix
    ) internal pure returns (uint8[3] memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        uint256 rand_red = random(string(abi.encodePacked(keyPrefix, 'red', toString(tokenId))));
        uint256 rand_green = random(string(abi.encodePacked(keyPrefix, 'green', toString(tokenId))));
        uint256 rand_blue = random(string(abi.encodePacked(keyPrefix, 'blue', toString(tokenId))));
        uint8[3] memory output = [uint8(rand_red % 256), uint8(rand_green % 256), uint8(rand_blue % 256)];
        return output;
    }

    function colorString(uint8[3] memory colors) internal pure returns (string memory) {
        string memory red = toString(uint256(colors[0]));
        string memory green = toString(uint256(colors[1]));
        string memory blue = toString(uint256(colors[2]));
        string memory output = string(abi.encodePacked('rgb(', red, ',', green, ',', blue, ')'));
        return output;
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        string[13] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>';
        parts[1] = string(abi.encodePacked('.a {fill:', colorString(getFirst(tokenId)), '}'));
        parts[2] = string(abi.encodePacked('.b {fill:', colorString(getSecond(tokenId)), '}'));
        parts[3] = string(abi.encodePacked('.c {fill:', colorString(getThird(tokenId)), '}'));
        parts[4] = string(abi.encodePacked('.d {fill:', colorString(getFourth(tokenId)), '}'));
        parts[5] = string(abi.encodePacked('.e {fill:', colorString(getFifth(tokenId)), '}'));
        parts[6] = '</style>';
        parts[7] = '<g><rect class="a" width="350" height="70"/></g>';
        parts[8] = '<g><rect y="70" class="b" width="350" height="70"/></g>';
        parts[9] = '<g><rect y="140" class="c" width="350" height="70"/></g>';
        parts[10] = '<g><rect y="210" class="d" width="350" height="70"/></g>';
        parts[11] = '<g><rect y="280" class="e" width="350" height="70"/></g>';
        parts[12] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "EthRainbow #', toString(tokenId),
                        '", "description": "EthRainbow are just colors.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId>0 && tokenId<=MAX_TOKENS, "Out of range");
        _safeMint(_msgSender(), tokenId);
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

    constructor() ERC721("EthRainbow", "RBW") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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