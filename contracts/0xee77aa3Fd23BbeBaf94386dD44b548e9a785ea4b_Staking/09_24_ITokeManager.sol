// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface ITokeManager {
    function getCycleDuration() external view returns (uint256);

    function getCurrentCycle() external view returns (uint256); // named weird, this is start cycle timestamp

    function getCurrentCycleIndex() external view returns (uint256);
}