// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);
}