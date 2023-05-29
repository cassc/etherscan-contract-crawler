// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAPWineRouter {
    function swapExactAmountIn(
        address,
        uint256[] calldata,
        uint256[] calldata,
        uint256,
        uint256,
        address,
        uint256,
        address
    ) external returns (uint256);
}