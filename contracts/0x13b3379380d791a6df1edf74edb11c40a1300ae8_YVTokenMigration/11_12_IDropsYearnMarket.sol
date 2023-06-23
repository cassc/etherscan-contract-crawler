//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDropsYearnComptroller {
    function enterMarketsFrom(address[] memory cTokens, address from) external returns (uint256);
}

interface IDropsYearnMarket {
    function mintTo(uint256 mintAmount, address to) external returns (uint256);

    function comptroller() external view returns (IDropsYearnComptroller);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint256);
}