// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IConeGauge {
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }

    function deposit(uint256, uint256) external;

    function withdraw(uint256) external;

    function withdrawToken(uint256, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function lastEarn(address, address) external view returns (uint256);

    function rewardPerTokenCheckpoints(address, uint256)
        external
        view
        returns (RewardPerTokenCheckpoint memory);

    function getPriorBalanceIndex(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function numCheckpoints(address) external view returns (uint256);

    function tokenIds(address) external view returns (uint256);
}