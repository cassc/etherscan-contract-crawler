// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title MerkleLeaves
 * @author @NiftyMike, NFT Culture
 * @dev Merkle Leaves for Merkle Trees - This is a companion contract to NFTC Labs' MerkleClaimList.sol library.
 * It provides leaf generation functions for both indexed and non-indexed merkle trees.
 * It also provides wrapper methods to expose the leaf generation functions to off-chain callers.
 *
 * Off-chain access is useful, because both the contract and the caller need to be able to generate the
 * leaves in a perfectly identical manner, so the generators are exposed to make it easier.
 */
abstract contract MerkleLeaves {
    /**
     * @notice External: generate a leaf for a wallet.
     *
     * @param wallet Address to hash.
     */
    function getLeafFor(address wallet) external pure returns (bytes32) {
        return _generateLeaf(wallet);
    }

    /**
     * @notice External: generate a leaf for a wallet and an embedded index value.
     *
     * @param wallet Address to hash.
     * @param index integer index to assign the leaf.
     */
    function getIndexedLeafFor(address wallet, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return _generateIndexedLeaf(wallet, index);
    }

    /**
     * @dev Generate a merkle leaf based only on a wallet address. This is useful when all users
     * represented in the tree are eligible for the exact same thing, such as one free mint.
     *
     * A tiered system can be supported by this approach, by making seperate merkle trees and
     * mint functions per tier, but that approach will become ungainly if you have to support more
     * than a few tiers.
     */
    function _generateLeaf(address wallet) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(wallet));
    }

    /**
     * @dev Generate a merkle leaf based on a wallet address and an index. This is useful when all
     * users represented in the tree are eligible for different amounts of something.
     */
    function _generateIndexedLeaf(address wallet, uint256 index)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, "_", index));
    }
}