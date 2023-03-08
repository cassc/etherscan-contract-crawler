// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "../interfaces/IArtWork.sol";
import "./Utils.sol";

library TypeBlocksMetadata {

    function tokenURI(uint256 tokenId, bytes1[] memory letters , string memory color, uint256 tokenShuffle, IArtWork artwork) internal pure returns (string memory) {
        bytes memory svg = artwork.generateArt(letters, color);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Type Blocks ', StringsUpgradeable.toString(tokenId), '",',
                '"description": "The Art Of Block, The Blocks Of Artwork.",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    svg,
                    '",',
                '"attributes": [',
                    _attributes(letters, color, tokenId, tokenShuffle),
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

    function _attributes(bytes1[] memory letters, string memory color, uint256 tokenId, uint256 tokenShuffle) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _trait('Letters', string(Utils.join(letters)), ','),
            _trait('Characters', StringsUpgradeable.toString(letters.length), ','),
            _trait('Color', color, ','),
            _trait('Mint Phase', StringsUpgradeable.toString(_getMintPhase(tokenId)), ','),
            _trait('Shuffle', StringsUpgradeable.toString(tokenShuffle), '')
        );
    }

    function _trait(string memory traitType, string memory traitValue, string memory append) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    function _getMintPhase(uint256 tokenId) internal pure returns (uint256 mintPhase) {
        if (tokenId <= 2000) {
            mintPhase = 1;
        } else if (tokenId <= 6000) {
            mintPhase = 2;
        } else {
            mintPhase = 3;
        }
    }
}