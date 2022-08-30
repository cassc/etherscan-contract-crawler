// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGenesisLiquidityPool.sol";


interface IGenesisLiquidityPoolNative is IGenesisLiquidityPool {

    function receiveMigrationNative(uint256 amountGEX, uint256 initMintedAmount) external payable;

    function repayCollateralNative() external payable returns(uint256);
}