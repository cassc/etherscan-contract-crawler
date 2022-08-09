// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface WETHInterface {
    function withdraw(uint256 wad) external;
}

/**
 * @title   EthereumFeeCollectorInterface
 * @author  OpenSea Protocol Team
 * @notice  EthereumFeeCollectorInterface contains all external function
 *          interfaces for the fee collector implementation.
 */
interface EthereumFeeCollectorInterface {
    /**
     * @notice Unwraps and withdraws the given amount of WETH tokens from the
     *         provided contract address. Requires the caller to have the
     *         operator role, and the withdrawal wallet to be in the
     *         allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The WETH token address to be unwrapped.
     * @param amount           The amount of tokens to be withdrawn.
     */
    function unwrapAndWithdraw(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external;

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external pure returns (string memory);
}