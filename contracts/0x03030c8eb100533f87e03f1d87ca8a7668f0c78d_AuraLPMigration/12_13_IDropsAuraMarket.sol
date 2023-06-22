//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDropsAuraComptroller {
    function enterMarketsFrom(address[] memory cTokens, address from) external returns (uint256);
}

interface IDropsAuraMarket {
    function mintTo(uint256 mintAmount, address to) external returns (uint256);

    function comptroller() external view returns (IDropsAuraComptroller);
}