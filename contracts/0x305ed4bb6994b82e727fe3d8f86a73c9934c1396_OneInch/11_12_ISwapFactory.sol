// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISwapFactory {
    function isTokenWhitelisted(address token) external view returns (bool);
    function whitelistedTokens() external view returns (address[] memory);
}