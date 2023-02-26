// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITreasury {
    function distribute(address _receiver, uint256 _amount) external;

    function distributeToken(address _receiver, address _tokenOut, uint256 _lpAmount, uint256 _minAmountOut) external;
    function swap(address _fromToken, address _toToken, uint256 _amountIn, uint256 _minAmountOut) external;
    function convertToLLP(address _token, uint256 _amount, uint256 _minAmountOut) external;
}