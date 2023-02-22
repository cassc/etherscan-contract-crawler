// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IAlphaWhitelist {
    function isWhitelisted(address user) external view returns (bool);
}