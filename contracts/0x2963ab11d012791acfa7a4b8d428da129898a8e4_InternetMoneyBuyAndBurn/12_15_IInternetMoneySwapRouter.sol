// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IInternetMoneySwapRouter {
    function fee() external returns(uint256);
    function wNative() external returns(address payable);
    function distributeAll(uint256 amount) external;
    function distribute(uint256 amount) external;
    function swapTokenV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable;
    function swapNativeToV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable;
    function swapToNativeV2(
        uint256 _dexId,
        address payable recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable;
}