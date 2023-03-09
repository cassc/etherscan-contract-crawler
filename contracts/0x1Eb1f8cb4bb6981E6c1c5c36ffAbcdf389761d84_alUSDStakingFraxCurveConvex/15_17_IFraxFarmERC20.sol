//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraxFarmERC20 {
    function lockedLiquidityOf(address account) external view returns (uint256);
}