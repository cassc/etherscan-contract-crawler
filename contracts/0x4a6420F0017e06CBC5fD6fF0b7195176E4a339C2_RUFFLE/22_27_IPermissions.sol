// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPermissions {
    function isWhitelisted(address user) external view returns (bool);

    function buyLimit(address user) external view returns (uint256);
}