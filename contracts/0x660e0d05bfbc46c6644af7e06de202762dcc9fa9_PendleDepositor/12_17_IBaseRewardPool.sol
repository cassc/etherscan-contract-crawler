// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IRewards.sol";

interface IBaseRewardPool is IRewards {
    function setParams(
        uint256 _pid,
        address _stakingToken,
        address _rewardToken
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256) external;

    function stakeAll() external;

    function stakeFor(address, uint256) external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function donate(address, uint256) external payable;

    function earned(address, address) external view returns (uint256);

    function getUserAmountTime(address) external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function getRewardTokensLength() external view returns (uint256);

    function getReward(address) external;

    function withdrawFor(address _account, uint256 _amount) external;

    event BoosterUpdated(address _booster);
    event RewardTokenAdded(address indexed _rewardToken);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event EmergencyWithdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _reward
    );
}