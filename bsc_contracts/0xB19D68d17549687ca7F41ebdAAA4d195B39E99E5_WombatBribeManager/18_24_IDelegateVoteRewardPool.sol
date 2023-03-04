// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegateVoteRewardPool {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function DENOMINATOR() external view returns (uint256);

    function __DelegateVotePool_init_(address _bribeManager) external;

    function balanceOf(address _account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function castVotes() external;

    function harvestAll() external;

    function deletePool(address lp) external;

    function donateRewards(uint256 _amountReward, address _rewardToken) external;

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function feeCollector() external view returns (address);

    function getPendingRewards(address user)
        external
        view
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getPoolsLength() external view returns (uint256 length);

    function getReward(address _for)
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getRewardLength() external view returns (uint256);

    function getRewardUser()
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getStakingDecimals() external view returns (uint256);

    function harvestAndGetRewards() external;

    function isRewardToken(address) external view returns (bool);

    function isVoter(address) external view returns (bool);

    function isvotePool(address) external view returns (bool);

    function owner() external view returns (address);

    function protocolFee() external view returns (uint256);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external;

    function renounceOwnership() external;

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function setProtocolFee(uint256 fee) external;

    function setProtocolFeeCollector(address collector) external;

    function setVoterStatus(address voter, bool _isVoter) external;

    function setVotingLock(uint256 _startTime, uint256 _totalTime) external;

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function startTime() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unlockTime() external view returns (uint256);

    function updateFor(address _account) external;

    function updateWeight(address lp, uint256 weight) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function votePools(uint256) external view returns (address);

    function votingWeights(address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool _claim
    ) external returns (bool);
}