// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev This is the interface for NFT extension mutableURI
/// @author Simon Fremaux (@dievardump)
interface IERC721WithMutableURI {
    function mutableURI(uint256 tokenId) external view returns (string memory);
}