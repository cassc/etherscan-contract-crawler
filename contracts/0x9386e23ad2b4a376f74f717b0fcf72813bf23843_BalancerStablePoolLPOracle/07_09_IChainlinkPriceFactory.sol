//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkPriceFactory {
    function getUSDPrice(address asset) external view returns (int256);

    function getETHPrice(address asset) external view returns (int256);
}