// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetPriceOracle {
    function lpPrice() external view returns (uint256);
}