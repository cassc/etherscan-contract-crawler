// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

/**
 * @dev Interface for minting fungible tokens.
 */
interface IMintableToken {
    /**
     * @dev Mints the specified `amount` of tokens for `to`.
     */
    function mint(address to, uint256 amount) external;
}