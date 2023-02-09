// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface INetworkV2 {
    function enter(uint256 _id) external returns (uint48);

    function exit(uint256 _id) external;

    function migrateShare(uint256 _id, uint48 _unlocks, bool _allowOverwrite) external;

    function pot() external payable;

    function claim(uint256 _id, uint256[] calldata _blockNumbers) external returns (uint256);
}