// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IStake {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    address rewardAsset;
    uint256 rewardsDuration;
    bool lockRewards;
    uint256 lockStartBlockDelay;
  }

  struct AssetConfig {
    uint128 emissionPerSecond;
    uint256 distributionEnd;
    bool lockRewards;
    uint256 lockStartBlockDelay;
  }

  function setCooldownPause(bool paused) external;

  function slash(address destination, uint256 amount) external;

  function setPendingAdmin(uint256 role, address newPendingAdmin) external;

  function claimRoleAdmin(uint256 role) external;

  // solhint-disable-next-line func-name-mixedcase
  function STAKED_TOKEN() external view returns (address);

  function getMaxSlashablePercentage() external view returns (uint256);

  function configureAssets(AssetConfigInput[] calldata newConfigs) external;

  function getAssetConfig(address asset) external view returns (AssetConfig memory);
}