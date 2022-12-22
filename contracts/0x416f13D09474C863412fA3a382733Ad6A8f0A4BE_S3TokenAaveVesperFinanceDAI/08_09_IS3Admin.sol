// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IS3Admin {
    function interestTokens(uint8 _strategyIndex) external view returns (address);
    function whitelistedAaveBorrowPercAmounts(uint8 _amount) external view returns (bool);
    function aave() external view returns (address);
    function aaveEth() external view returns (address);
    function aavePriceOracle() external view returns (address);
    function aWETH() external view returns (address);
}