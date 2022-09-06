// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IStakedFuzzyFighters {
    function whitelistMint(address, uint256, uint256) external;
    function whitelistBurn(address, uint256, uint256) external;
}