// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface DropEvents {
    /**
     * @dev An event with details of an access pass mint.
     *
     * @param minter The minter.
     * @param partnerContract The partner contract used for access
     * @param quantity The number of tokens minted.
     * @param value  The amount paid for each token.
     */
    event AccessMint(
        address indexed minter,
        address indexed partnerContract,
        uint256 quantity,
        uint256 value
    );

    /**
     * @dev An event with details of a mint.
     *
     * @param minter The minter.
     * @param quantity The number of tokens minted.
     * @param value  The amount paid for each token.
     */
    event PublicMint(address indexed minter, uint256 quantity, uint256 value);
}