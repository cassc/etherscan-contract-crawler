// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashSwap {
    function initFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint24 _fee1,
        uint24 _fee2
    ) external;
}