// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @dev Solidity Curve Calc interface because it is written in vyper.
interface ICurveCalc {
    /// @notice Calculate amount of of coin i taken when exchanging for coin j
    /// @param n_coins Number of coins in the pool
    /// @param balances Array with coin balances
    /// @param amp Amplification coefficient
    /// @param fee Pool's fee at 1e10 basis
    /// @param rates Array with rates for "lent out" tokens
    /// @param precisions Precision multipliers to get the coin to 1e18 basis
    /// @param i Index of the changed coin (trade in)
    /// @param j Index of the other changed coin (trade out)
    /// @param dy Amount of coin j (trade out)
    /// @return Amount of coin i (trade in)
    function get_dx(
        int128 n_coins,
        uint256[8] calldata balances,
        uint256 amp,
        uint256 fee,
        uint256[8] calldata rates,
        uint256[8] calldata precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);
}