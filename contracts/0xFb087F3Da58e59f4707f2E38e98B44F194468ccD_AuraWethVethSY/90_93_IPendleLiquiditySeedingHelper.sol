// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface IPLiquiditySeedingHelper {
    function seedLiquidity(address market, address token, uint256 amount) external payable;
}