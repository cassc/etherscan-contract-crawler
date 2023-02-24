// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

struct EarnedData {
    address token;
    uint256 amount;
}

//solhint-disable
interface IConvexBaseRewardPool {
    function balanceOf(address account) external view returns (uint256);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

interface IConvexBaseRewardPoolSideChain {
    function getReward(address) external;

    function rewardLength() external view returns (uint256);

    function earnedView(address _account) external view returns (EarnedData[] memory claimable);

    function earned(address _account) external returns (EarnedData[] memory claimable);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;
}