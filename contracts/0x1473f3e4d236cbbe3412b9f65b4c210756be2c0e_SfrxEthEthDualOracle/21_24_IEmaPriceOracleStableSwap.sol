// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

interface IEmaPriceOracleStableSwap {
    function price_oracle() external view returns (uint256);
}