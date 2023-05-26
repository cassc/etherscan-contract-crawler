// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITaxDistributor {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external;
    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address holder) external;
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function setTaxWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}