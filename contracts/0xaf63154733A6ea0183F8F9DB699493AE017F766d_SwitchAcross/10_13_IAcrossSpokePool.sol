// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Contains common data structures and functions used by all SpokePool implementations.
 */
interface IAcrossSpokePool {
    function deposit(
        address recipient, // Recipient address
        address originToken, // Address of the token
        uint256 amount, // Token amount
        uint256 destinationChainId, // ⛓ id
        uint64 relayerFeePct, // see #Fees Calculation
        uint32 quoteTimestamp // Timestamp for the quote creation
    ) external payable;

    function wrappedNativeToken() external view returns (address);
}