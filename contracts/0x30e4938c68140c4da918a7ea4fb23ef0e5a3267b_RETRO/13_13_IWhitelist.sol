// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWhitelist {
    function isWhitelisted(address user) external view returns (bool);
}