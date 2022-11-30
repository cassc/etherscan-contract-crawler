// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IMigrator {

    function migrate(address lpToken, uint256 amount, uint256 unlockTime, address owner) external;

}
