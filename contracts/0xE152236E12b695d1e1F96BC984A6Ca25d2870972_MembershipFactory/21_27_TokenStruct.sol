//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Token struct
 * 
 * @param tokenId uint256 specific tokenId for the asset
 * @param tokenAddress address of the contract for this asset
 * @param tokenType string representing asset type i.e. ERC721 | ERC20 | ERC1155
 * @param tokensAllocated uint256 number representing how many tokens as a %'s to
 * attach to a given approval or other directive
 */
struct Token {
    uint256 tokenId;
    address tokenAddress;
    string tokenType;
    uint256 tokensAllocated;
}