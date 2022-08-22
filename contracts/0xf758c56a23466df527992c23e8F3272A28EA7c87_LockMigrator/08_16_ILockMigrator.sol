// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILockMigrator {
    function setMigrationReward(uint256 reward) external;

    function migrateLock(
        uint256 _value,
        uint256 _lockDuration,
        uint256 _tokenId,
        address _owner,
        uint256 _mahaReward,
        uint256 _scallopReward,
        bytes32[] memory proof
    ) external returns (uint256);

    function isLockValid(
        uint256 _value,
        uint256 _lockDuration,
        address _owner,
        uint256 _tokenId,
        uint256 _mahaReward,
        uint256 _scallopReward,
        bytes32[] memory proof
    ) external view returns (bool);

    event MigrationRewardChanged(uint256 oldReward, uint256 newReward);
    event TransferMigrationReward(
        address indexed who,
        address indexed token,
        uint256 amount
    );
}