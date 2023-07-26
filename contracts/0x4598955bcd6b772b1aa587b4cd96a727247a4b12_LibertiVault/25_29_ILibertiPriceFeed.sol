//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ILibertiPriceFeed {
    function getPrice(address token) external view returns (uint256);
}