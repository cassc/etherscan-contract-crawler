//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface Blacklistable {
    function addRobotToBlacklist(address) external;
    function removeRobotFromBlacklist(address) external;
    function inRobotBlacklist(address) external view returns (bool);
}