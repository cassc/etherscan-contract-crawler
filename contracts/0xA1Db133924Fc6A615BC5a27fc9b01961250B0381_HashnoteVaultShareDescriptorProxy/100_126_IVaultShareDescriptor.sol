// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Describes Option NFT
interface IVaultShareDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}