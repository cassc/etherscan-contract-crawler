// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFSushiRestaurant {
    function startWeek() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalAssetsDuring(uint256 week) external view returns (uint256);

    function lastCheckpoint() external view returns (uint256);

    function checkpointedTotalAssets() external returns (uint256);

    function checkpointedTotalAssetsDuring(uint256 week) external returns (uint256);

    function checkpoint() external;
}