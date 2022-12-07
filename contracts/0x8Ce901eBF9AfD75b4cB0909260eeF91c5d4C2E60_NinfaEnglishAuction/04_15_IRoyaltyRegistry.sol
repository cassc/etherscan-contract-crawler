// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @author: manifold.xyz

/**
 * @dev Royalty registry interface. Modified to include only used functions, in this case only used by marketplace in order to getRoyaltyLookupAddress.
 */
interface IRoyaltyRegistry {
    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress)
        external
        view
        returns (address);
}