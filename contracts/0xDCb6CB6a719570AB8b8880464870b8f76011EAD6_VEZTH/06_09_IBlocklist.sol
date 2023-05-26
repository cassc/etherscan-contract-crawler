// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IBlocklist {
    function isBlocked(address addr) external view returns (bool);
}