// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function rewardToken() external view returns (uint256);

    function stakingToken() external view returns (uint256);

    function allStakedBalance() external view returns (uint256);

    function startStakeTimestamp() external view returns (uint256);

    function startWitdrawTimestamp() external view returns (uint256);

    function endStakeTimestamp() external view returns (uint256);

    function endWitdrawTimestamp() external view returns (uint256);

    function duration() external view returns (uint256);

    function StakedReward() external view returns (uint256);

    function allStakedBalances(uint256 index) external view returns (uint256);

    function allRewards(uint256 index) external view returns (uint256);

    function stakers(uint256 index) external view returns (address);

    function stakedTime(address user) external view returns (uint256);

    function stakedBalance(address user) external view returns (uint256);

    function stake(uint256 amount) external;

    function unstake() external;

    function getReward(address user) external view returns (uint256);

    function setReward(uint256 amount) external;

    function addReward(uint256 amount) external;

    function setStake() external;

    function setWitdraw() external;

    function witdrawOwnerLP(uint256 amount) external;

    function witdrawOwnerReward(uint256 amount) external;

    function setDuration(uint256 timestamp) external;

    function topTen()
        external
        view
        returns (address[] memory TopTen, uint256[] memory TopTenAmount);
    
    function findIndex(address sender) external view returns (uint256);

    function _getReward(address user)
        external
        view
        returns (uint256 commingReward, uint256 reward);

    function calculate(uint256 deposited, uint256 Balance)
        external
        pure
        returns (uint256 percentShares);

    function percentageShare(address _sender) external view returns (uint256);

    function getAll(address user)
        external
        view
        returns (
            uint256 percentShares,
            uint256 shares,
            uint256 value,
            uint256 reward
        );





    function isStartedStake() external view returns (bool start);

    function isStartedWitdraw() external view returns (bool start);
}