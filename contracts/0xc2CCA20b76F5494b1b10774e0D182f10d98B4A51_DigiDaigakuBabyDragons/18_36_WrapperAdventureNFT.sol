// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../adventures/AdventureNFT.sol";
import "../utils/tokens/WrapperERC721.sol";

/**
 * @title WrapperAdventureNFT
 * @author Limit Break, Inc.
 * @notice Extends AdventureNFT, adding token rental mechanisms.
 */
abstract contract WrapperAdventureNFT is WrapperERC721, AdventureNFT {
    using Strings for uint256;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, WrapperERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override(AdventureNFT, ERC721) returns (string memory) {
        if(!_exists(tokenId)) {
            revert NonexistentToken();
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function _beforeTokenTransfer(address /*from*/, address /*to*/, uint256 tokenId) internal virtual override(AdventureERC721, ERC721) {
        if(blockingQuestCounts[tokenId] > 0) {
            revert AnActiveQuestIsPreventingTransfers();
        }
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI() internal view virtual override(AdventureNFT, ERC721) returns (string memory) {
        return baseTokenURI;
    }
}