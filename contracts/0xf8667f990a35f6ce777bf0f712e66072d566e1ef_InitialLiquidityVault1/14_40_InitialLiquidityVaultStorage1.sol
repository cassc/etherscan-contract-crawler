//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract InitialLiquidityVaultStorage1{

    uint256 public startTime;
    int24 acceptTickChangeInterval;
    int24 acceptSlippagePrice;
    uint32 TWAP_PERIOD;

}