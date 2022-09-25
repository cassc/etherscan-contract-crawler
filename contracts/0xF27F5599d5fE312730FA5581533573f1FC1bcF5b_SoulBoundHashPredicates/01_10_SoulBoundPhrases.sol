// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// SoulBoundHashPredicates Contract
//
//         *..*
//        (====)
//       ( e__e )
//       ^^ ~~ ^^
//
// A Fragments DAO Construction

import { ICollectionNFTEligibilityPredicate } from "../../interfaces/ICollectionNFTEligibilityPredicate.sol";
import { ICollectionNFTTokenURIPredicate } from "../../interfaces/ICollectionNFTTokenURIPredicate.sol";
import { ICollectionNFTMintFeePredicate } from "../../interfaces/ICollectionNFTMintFeePredicate.sol";
import { IHashes } from "../../interfaces/IHashes.sol";
import { Base64 } from "../../lib/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract SoulBoundHashPredicates is ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate, ICollectionNFTTokenURIPredicate {
    
    IHashes public hashes;

    constructor(address _hashes) {
        hashes = IHashes(_hashes);
    }

    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external pure override returns (bool) {

        //Only available for DAO hashes
        if (_hashesTokenId <= 1000) {
            return true;
        }
        else {
            return false;
        }
    }

    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
        return 0;
    }

    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view override returns (string memory) {

        //The colours
        string[4] memory colours = ["midnightblue", "steelblue", "brown", "crimson"];

        //The hash as a string
        string memory stringedHash = toHex(_hashesHash);

        //The soul Owner
        address soulOwnerAddress = hashes.ownerOf(_hashesTokenId);
        
        string memory soulOwnerString = Strings.toHexString(soulOwnerAddress);

        string memory svgHTML = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500">';

        svgHTML = string.concat(svgHTML, '<style>.base { fill: black; font-family: courier; font-size: 10px; text-anchor: middle; }</style>');

        //Background rect
        svgHTML = string.concat(svgHTML, '<rect width="100%" height="100%" fill="');

        svgHTML = string.concat(svgHTML, colours[_tokenId % colours.length]);

        svgHTML = string.concat(svgHTML, '" />');

        //Foreground rect
        svgHTML = string.concat(svgHTML, '<rect x="20" y="20" width="460" height="460" fill="cornsilk" />');

        //Hash text
        svgHTML = string.concat(svgHTML, '<text x="250" y="150" class="base">');

        svgHTML = string.concat(svgHTML, stringedHash);

        svgHTML = string.concat(svgHTML, '</text>');

        //Soulbound to
        svgHTML = string.concat(svgHTML, '<text x="250" y="350" class="base">Soulbound To:</text>');

        //Owner text
        svgHTML = string.concat(svgHTML, '<text x="250" y="370" class="base">');

        svgHTML = string.concat(svgHTML, soulOwnerString);

        svgHTML = string.concat(svgHTML, '</text>');

        //Caps it
        svgHTML = string.concat(svgHTML, '</svg>');        

        svgHTML = string.concat('data:image/svg+xml;base64,', Base64.encode(bytes(svgHTML)));

        //Adds metadata
        svgHTML = string.concat('{"name": "Soulbound Hashes", "description": "The first soulbound Hashes collection built exclusively for DAO Hash holders.", "image": "', svgHTML, '", "attributes": [{ "trait_type": "Hash", "value": "', stringedHash, '"}, {"trait_type": "Soulbound to:", "value": "', soulOwnerString, '"}]}');

        svgHTML = string.concat('data:application/json;base64,', Base64.encode(bytes(svgHTML)));

        return svgHTML;
    }

    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
    }

    function toHex (bytes32 data) public pure returns (string memory) {
        return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
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
}