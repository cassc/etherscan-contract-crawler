// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Events} from "../IButtonswapERC20/IButtonswapERC20Events.sol";

interface IButtonswapPairEvents is IButtonswapERC20Events {
    /**
     * @notice Emitted when a {IButtonswapPair-mint} is performed.
     * Some `token0` and `token1` are deposited in exchange for liquidity tokens representing a claim on them.
     * @param from The account that supplied the tokens for the mint
     * @param amount0 The amount of `token0` that was deposited
     * @param amount1 The amount of `token1` that was deposited
     * @param amountOut The amount of liquidity tokens that were minted
     * @param to The account that received the tokens from the mint
     */
    event Mint(address indexed from, uint256 amount0, uint256 amount1, uint256 amountOut, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-burn} is performed.
     * Liquidity tokens are redeemed for underlying `token0` and `token1`.
     * @param from The account that supplied the tokens for the burn
     * @param amountIn The amount of liquidity tokens that were burned
     * @param amount0 The amount of `token0` that was received
     * @param amount1 The amount of `token1` that was received
     * @param to The account that received the tokens from the burn
     */
    event Burn(address indexed from, uint256 amountIn, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-swap} is performed.
     * @param from The account that supplied the tokens for the swap
     * @param amount0In The amount of `token0` that went into the swap
     * @param amount1In The amount of `token1` that went into the swap
     * @param amount0Out The amount of `token0` that came out of the swap
     * @param amount1Out The amount of `token1` that came out of the swap
     * @param to The account that received the tokens from the swap
     */
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Emitted when the movingAverageWindow parameter for the pair has been updated.
     * @param newMovingAverageWindow The new movingAverageWindow value
     */
    event MovingAverageWindowUpdated(uint32 newMovingAverageWindow);

    /**
     * @notice Emitted when the maxVolatilityBps parameter for the pair has been updated.
     * @param newMaxVolatilityBps The new maxVolatilityBps value
     */
    event MaxVolatilityBpsUpdated(uint16 newMaxVolatilityBps);

    /**
     * @notice Emitted when the minTimelockDuration parameter for the pair has been updated.
     * @param newMinTimelockDuration The new minTimelockDuration value
     */
    event MinTimelockDurationUpdated(uint32 newMinTimelockDuration);

    /**
     * @notice Emitted when the maxTimelockDuration parameter for the pair has been updated.
     * @param newMaxTimelockDuration The new maxTimelockDuration value
     */
    event MaxTimelockDurationUpdated(uint32 newMaxTimelockDuration);

    /**
     * @notice Emitted when the maxSwappableReservoirLimitBps parameter for the pair has been updated.
     * @param newMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps value
     */
    event MaxSwappableReservoirLimitBpsUpdated(uint16 newMaxSwappableReservoirLimitBps);

    /**
     * @notice Emitted when the swappableReservoirGrowthWindow parameter for the pair has been updated.
     * @param newSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow value
     */
    event SwappableReservoirGrowthWindowUpdated(uint32 newSwappableReservoirGrowthWindow);
}