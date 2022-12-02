// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IXENTorrent {
    event BulkClaimRank(address indexed user, uint256 users, uint256 term);
    event BulkClaimMintReward(address indexed user, uint256 users);
    event BulkClaimMintRewardIndex(
        address indexed,
        uint256 _userIndex,
        uint256 _userEnd
    );

    function bulkClaimRank(uint256 users, uint256 term) external;

    function bulkClaimMintReward(uint256 users) external;

    function bulkClaimMintRewardIndex(
        uint256 _userIndex,
        uint256 _userEnd
    ) external;
}