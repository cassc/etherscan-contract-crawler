// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "src/token/erc721/LazyMintERC721C.sol";

import "@limitbreak/creator-token-contracts/contracts/access/OwnableInitializable.sol";
import "@limitbreak/creator-token-contracts/contracts/token/erc721/MetadataURI.sol";

abstract contract LazyMintERC721CMetadataInitializable is 
    OwnableInitializable, 
    MetadataURIInitializable, 
    LazyMintERC721CInitializable {
    using Strings for uint256;

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) {
            revert LazyMintERC721Base__TokenDoesNotExist();
        }

        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }
}