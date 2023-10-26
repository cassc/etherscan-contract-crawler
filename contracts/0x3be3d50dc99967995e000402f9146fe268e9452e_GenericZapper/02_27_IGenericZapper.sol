// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { MultiPoolStrategy as IMultiPoolStrategy } from "../MultiPoolStrategy.sol";

interface IGenericZapper {
    /**
     * @custom:error Thrown when the strategy is paused.
     */
    error StrategyPaused();
    /**
     * @custom:error Thrown when an empty input is encountered.
     */
    error EmptyInput();
    /**
     * @custom:error Thrown when provided address is set to the zero address.
     */
    error ZeroAddress();

    /**
     * @dev Deposits asset into the MultiPoolStrategy contract.
     * @param amount The asset amount user wants to deposit.
     * @param token The deposited asset address (like: USDT address).
     * @param toAmountMin Minimum amount of underlying asset to receive after the swap of the provided asset (please pay attention to decimals).
     * @param receiver The address to receive the shares.
     * @param strategyAddress The address of the MultiPoolStrategy contract to deposit into.
     * @param swapTx containing the transaction data for the swap.
     * @return shares The amount of shares received.
     */
    function deposit(
        uint256 amount,
        address token,
        uint256 toAmountMin,
        address receiver,
        address strategyAddress,
        bytes calldata swapTx
    )
        external
        returns (uint256 shares);

    /**
     * @dev Redeems asset from the MultiPoolStrategy contract.
     * @param sharesAmount The amount of shares to redeem.
     * @param redeemToken The token address redeem.
     * @param toAmountMin Minimum amount of required asset (like: USDT) to recieve after withdraw.
     * @param receiver The address to receive the redeemed asset.
     * @param strategyAddress The address of the MultiPoolStrategy contract to redeem from.
     * @param swapTx containing the transaction data for the swap.
     * @return redeemAmount The redeemed amount.
     */
    function redeem(
        uint256 sharesAmount,
        address redeemToken,
        uint256 toAmountMin,
        address receiver,
        address strategyAddress,
        bytes calldata swapTx
    )
        external
        returns (uint256 redeemAmount);
    /**
     * 1. User sepcifies how many shares they want to redeem (param: sharesAmount)
     *     2. Call redeem on the strategy, swaping shares with USDC
     *     3. Swap USDC with USDT  (Curve reverts if we don't get at least minSwapAmount)
     *     4. Send USDT to user
     */
}