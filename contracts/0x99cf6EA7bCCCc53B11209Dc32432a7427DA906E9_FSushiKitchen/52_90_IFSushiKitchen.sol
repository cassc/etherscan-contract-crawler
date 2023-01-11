// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFSushiKitchen {
    error InvalidPid();

    event AddPool(uint256 indexed pid);
    event UpdateWeight(uint256 indexed pid, uint256 weightPoints, uint256 totalWeightPoints);

    function flashStrategyFactory() external view returns (address);

    function totalWeightPointsLength() external view returns (uint256);

    function weightPointsLength(uint256 pid) external view returns (uint256);

    function totalWeightPoints() external view returns (uint256);

    function weightPoints(uint256 pid) external view returns (uint256);

    function totalWeightPointsAt(uint256 timestamp) external view returns (uint256);

    function weightPointsAt(uint256 pid, uint256 timestamp) external view returns (uint256);

    function relativeWeight(uint256 pid) external view returns (uint256);

    function relativeWeightAt(uint256 pid, uint256 timestamp) external view returns (uint256);

    function addPool(uint256 pid) external;

    function updateWeight(uint256 pid, uint256 points) external;

    function checkpoint(uint256 pid) external;
}