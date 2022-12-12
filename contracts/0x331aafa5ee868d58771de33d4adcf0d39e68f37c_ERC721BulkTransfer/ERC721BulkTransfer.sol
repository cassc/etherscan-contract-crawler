/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC721 Bulk Transfer v0.9.0
//
// https://github.com/bokkypoobah/ERC721BulkTransfer
//
// Deployments Mainnet 0x
//
// NOTES: 
// 1. `dest` must first execute setApprovalForAll(thisContract, true)
// 2. Execute bulkTransfer(...)
// 3. `dest` must first execute setApprovalForAll(thisContract, false) 
//    to prevent unexpected transfers
//
// SPDX-License-Identifier: MIT
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022
// ----------------------------------------------------------------------------

interface IERC721Partial {
    function transferFrom(address from, address to, uint tokenId) external payable;
}

contract ERC721BulkTransfer {
    /// @dev Bulk transfer ERC-721. 
    /// @param src Source account that owns the NFTs
    /// @param dest Destination account the NFTs will be transferred to
    /// @param collection ERC-721 NFT collection
    /// @param tokenIds TokenIds to be transferred
    function bulkTransfer(address src, address dest, IERC721Partial collection, uint[] calldata tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            collection.transferFrom(src, dest, tokenIds[i]);
        }
    }
}