// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IExchangeAdapter {
    function swapExactInputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _poolFee
    ) external payable returns (uint256);

    function swapExactInput(
        address _tokenIn,
        address[] memory _viaPath,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24[] memory _poolFees
    ) external payable returns (uint256);

    function exactOutputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24 _poolFee
    ) external payable returns (uint256 amountIn);

    function exactOutput(
        address _tokenIn,
        address[] memory _viaPath,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24[] memory _poolFees
    ) external payable returns (uint256 amountIn);
}