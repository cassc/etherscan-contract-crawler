// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IAdapter {
    /// @notice Executes call with given params
    /// @param assetIn Incoming asset
    /// @param amountIn Incoming amount
    /// @param nativeExtraValue Extra value of native token that can be used by call
    /// @param args Encoded additional arguments for current adapter

    function call(
        address assetIn,
        uint256 amountIn,
        uint256 nativeExtraValue,
        bytes memory args
    ) external payable;
}