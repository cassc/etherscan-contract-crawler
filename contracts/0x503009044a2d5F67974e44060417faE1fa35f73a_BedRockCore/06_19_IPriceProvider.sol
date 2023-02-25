// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPriceProvider {
    function setPrice(uint256 price) external;

    function getPrice() external view returns (uint256);
}