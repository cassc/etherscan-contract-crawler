// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyMoneyMarket {

    function depositCall(address asset, uint256 amount) external;

    function withdrawCall(address asset, uint256 amount, address to) external;

    function getMoneyMarketToken(address asset) external view returns (address);

    function getBalance(address asset, address account) external view returns (uint256);

    function getSupplyRate(address asset) external view returns (uint256);

}