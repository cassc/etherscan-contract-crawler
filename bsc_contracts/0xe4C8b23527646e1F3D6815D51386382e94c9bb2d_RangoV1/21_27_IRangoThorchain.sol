// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Interface to interact with RangoThorchain contract.
/// @author Thinking Particle
interface IRangoThorchain {
    /// @notice Defines parameters used for swapIn functionality on thorchain router.
    /// @param token The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function swapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable;

}