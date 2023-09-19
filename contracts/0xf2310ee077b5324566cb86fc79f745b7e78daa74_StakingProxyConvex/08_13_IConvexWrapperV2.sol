// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IConvexWrapperV2{

   struct EarnedData {
        address token;
        uint256 amount;
    }

   struct RewardType {
        address reward_token;
        address reward_pool;
        uint128 reward_integral;
        uint128 reward_remaining;
    }

  function distroContract() external view returns(address distro);
  function collateralVault() external view returns(address vault);
  function convexPoolId() external view returns(uint256 _poolId);
  function curveToken() external view returns(address);
  function convexToken() external view returns(address);
  function rewardRedirect(address _account) external view returns(address);
  function balanceOf(address _account) external view returns(uint256);
  function totalBalanceOf(address _account) external view returns(uint256);
  function deposit(uint256 _amount, address _to) external;
  function stake(uint256 _amount, address _to) external;
  function withdraw(uint256 _amount) external;
  function withdrawAndUnwrap(uint256 _amount) external;
  function getReward(address _account) external;
  function getReward(address _account, address _forwardTo) external;
  function rewardLength() external view returns(uint256);
  function rewards(uint256 _index) external view returns(RewardType memory rewardInfo);
  function earned(address _account) external returns(EarnedData[] memory claimable);
  function earnedView(address _account) external view returns(EarnedData[] memory claimable);
  function setVault(address _vault) external;
  function user_checkpoint(address _account) external returns(bool);
  function setDistributor(address _vault, address _distro) external;
  function sealDistributor() external;
}