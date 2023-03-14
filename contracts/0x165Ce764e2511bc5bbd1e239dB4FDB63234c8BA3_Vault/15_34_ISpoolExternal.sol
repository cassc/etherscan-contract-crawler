// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../ISwapData.sol";

interface ISpoolExternal {
    /* ========== FUNCTIONS ========== */

    function deposit(address strategy, uint128 amount, uint256 index) external;

    function withdraw(address strategy, uint256 vaultProportion, uint256 index) external;

    function fastWithdrawStrat(address strat, address underlying, uint256 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external returns(uint128);

    function redeem(address strat, uint256 index) external returns (uint128, uint128);

    function redeemUnderlying(uint128 amount) external;

    function redeemReallocation(address[] calldata vaultStrategies, uint256 depositProportions, uint256 index) external;

    function removeShares(address[] calldata vaultStrategies, uint256 vaultProportion) external returns(uint128[] memory);
}