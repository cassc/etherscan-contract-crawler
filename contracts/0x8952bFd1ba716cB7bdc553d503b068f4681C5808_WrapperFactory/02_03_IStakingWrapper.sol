// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IStakingWrapper{
    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct RewardType {
        address reward_token;
        uint128 reward_integral;
        uint128 reward_remaining;
    }

    function initialize(uint256 _poolId) external;
    function setExtraReward(address) external;
    function setRewardHook(address) external;
    function rewardHook() external view returns(address _hook);
    function getReward(address) external;
    function getReward(address,address) external;
    function user_checkpoint(address) external;
    function rewardLength() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function rewards(uint256 _rewardIndex) external view returns(RewardType memory);
    function earned(address _account) external returns(EarnedData[] memory claimable);
    function deposit(uint256 _amount, address _to) external returns (uint256);
    function withdraw(uint256 _amount) external returns (uint256);
    function withdraw(uint256 _amount, address _receiver, address ) external returns(uint256 shares);
    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 assets);
    function mint(uint256 _shares, address _to) external returns (uint256);
}