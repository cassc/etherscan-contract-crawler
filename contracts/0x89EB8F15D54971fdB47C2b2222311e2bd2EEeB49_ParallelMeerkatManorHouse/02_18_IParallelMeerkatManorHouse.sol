// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev
 */
interface IParallelMeerkatManorHouse {
    /**
     * Parallel Meerkats can only be transferred (beyond an initial, gratis gift)
     * to addresses with a sanctions-free Parallel Identity (PID) Token.
     *
     * See https://developer.parallelmarkets.com/docs/token
     */
    error TransferToNonPIDTokenHolder();

    /**
     * @dev Mint `quantity` meerkats.
     */
    function ownerMint(uint256 quantity) external;

    /**
     * @dev Transfer, gratis, a contract-owned meerkat to an address. Does not
     # require that the recipient be a PID Token holder.
     */
    function ownerGift(address to, uint256 tokenId) external;

}