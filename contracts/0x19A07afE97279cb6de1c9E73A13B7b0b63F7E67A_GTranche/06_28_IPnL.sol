// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// @title IPnL
/// @notice PnL interface for a dsitribution module with two tranches
interface IPnL {
    function distributeAssets(
        bool _loss,
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external returns (int256[2] memory amounts);

    function distributeLoss(int256 _amount, int256[2] calldata _trancheBalances)
        external
        view
        returns (int256[2] memory loss);

    function distributeProfit(
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external view returns (int256[2] memory profit);
}