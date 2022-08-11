// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import { AccessManager } from "../lib/AccessManager.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStake } from "../interfaces/IStake.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFeeReceiver } from "../interfaces/IFeeReceiver.sol";

/**
 * @title EmissionManager
 * @dev Acts as emission manager and rewards vault for the Stake contract.
 * It can be used as emission manager for several stake contracts. If this contracts is also used as
 * rewards vault, managers should call approve() for each asset to give allowance to each stake contracts to pull rewards.
 */
contract EmissionManager is AccessManager, IFeeReceiver {
  using SafeERC20 for IERC20;

  struct StakeAssetConfig {
    uint256 distributionDuration; // distribution duration in seconds
    bool lockRewards;
    uint256 lockStartBlockDelay;
  }

  // Slasher roles
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  // stake => reward asset config
  mapping(address => mapping(address => StakeAssetConfig)) public rewardsConfig;

  /**
   * @dev Initializes the main admin role
   * @param admin the address of the main admin role
   */
  constructor(address admin) AccessManager(admin) {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Configures the distribution of a list of rewards assets on a stake contract
   * @param stake the stake contract address
   * @param newConfigs The list of configurations to apply
   **/
  function configureAssets(IStake stake, IStake.AssetConfigInput[] calldata newConfigs)
    external
    onlyAdminOrRole(MANAGER_ROLE)
  {
    stake.configureAssets(newConfigs);
  }

  /**
   * @dev Sets a reward asset config for a stake contract to be used for incoming fee distributions
   * @param stake the stake contract address
   * @param asset the reward asset address
   * @param config the reward asset config
   **/
  function setRewardAsset(
    address stake,
    address asset,
    StakeAssetConfig calldata config
  ) external onlyAdminOrRole(MANAGER_ROLE) {
    rewardsConfig[stake][asset] = config;
  }

  /**
   * @dev Called by FeeManager. Configures the distribution of fees received on a stake contract
   * @param stake the stake contract address
   * @param asset the reward asset address
   * @param amount the amount of tokens to be distributed
   */
  function onFeesReceived(
    address stake,
    address asset,
    uint256 amount
  ) external override onlyAdminOrRole(MANAGER_ROLE) {
    StakeAssetConfig memory config = rewardsConfig[stake][asset];
    require(config.distributionDuration != 0, "asset not configured");

    IStake.AssetConfig memory currentAssetConfig = IStake(stake).getAssetConfig(asset);
    uint256 amountToDistribute = amount;

    if (currentAssetConfig.distributionEnd > block.timestamp) {
      uint256 remainingSeconds = currentAssetConfig.distributionEnd - block.timestamp;
      uint256 leftover = remainingSeconds * currentAssetConfig.emissionPerSecond;
      amountToDistribute = amount + leftover;
    }

    uint256 newEmissionPerSecond = amountToDistribute / config.distributionDuration;

    IStake.AssetConfigInput[] memory newConfig = new IStake.AssetConfigInput[](1);
    newConfig[0] = IStake.AssetConfigInput(
      uint128(newEmissionPerSecond),
      asset,
      config.distributionDuration,
      config.lockRewards,
      config.lockStartBlockDelay
    );
    IStake(stake).configureAssets(newConfig);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` for `token`
   * @param token the address of the token contract
   * @param spender The address of the spender
   * @param amount The amount of tokens to be allowed
   * @return a boolean value indicating whether the operation succeeded
   */
  function approve(
    IERC20 token,
    address spender,
    uint256 amount
  ) external onlyAdminOrRole(MANAGER_ROLE) returns (bool) {
    return token.approve(spender, amount);
  }

  /**
   * @dev Moves `amount` tokens to `recipient`
   * @param token the address of the token contract
   * @param recipient The address of the recipient
   * @param amount The amount of tokens to be transferred
   */
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyAdminOrRole(MANAGER_ROLE) {
    token.safeTransfer(recipient, amount);
  }
}