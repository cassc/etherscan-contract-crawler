// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface ComptrollerInterface {
    function markets(address) external view returns (bool, uint256);
}