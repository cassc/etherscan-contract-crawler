// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(
        uint256 nftId,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    function checkpointToken() external;

    function checkpointTotalSupply() external;

    function claim(uint256 nftId) external returns (uint256);

    function claimMany(uint256[] memory nftIds) external returns (bool);

    function claimWithPendingRewards(
        uint256 id,
        uint256 _reward,
        bytes32[] memory _proof
    ) external returns (uint256);
}