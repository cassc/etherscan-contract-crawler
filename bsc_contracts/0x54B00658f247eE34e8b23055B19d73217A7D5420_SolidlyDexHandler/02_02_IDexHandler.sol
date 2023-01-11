// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IDexHandler {
    function getAmountOut(
        address _dex,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (address pair, uint256 amountOut);
}