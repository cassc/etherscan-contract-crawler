//The code below is taken from https://eips.ethereum.org/EIPS/eip-4906
//and adapted to be used with ERC721A

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906A is IERC721A {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}