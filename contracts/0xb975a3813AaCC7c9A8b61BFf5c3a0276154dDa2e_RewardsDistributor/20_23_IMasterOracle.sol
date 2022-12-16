// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function quoteTokenToUsd(address _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function quoteUsdToToken(address _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function quote(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}