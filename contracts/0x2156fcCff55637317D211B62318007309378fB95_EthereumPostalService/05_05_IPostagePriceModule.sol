// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPostagePriceModule {
    function getPostageWei() external view returns (uint256);
}