// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AlloyxConfig.sol";
import "./interfaces/IAlloyxWhitelist.sol";
import "./interfaces/IMintBurnableERC20.sol";
import "./interfaces/ISortedGoldfinchTranches.sol";
import "./interfaces/IAlloyxStakeInfo.sol";
import "./interfaces/IAlloyxTreasury.sol";
import "./interfaces/IAlloyxExchange.sol";
import "./interfaces/IGoldfinchDesk.sol";
import "./interfaces/IStakeDesk.sol";
import "./interfaces/IBackerRewards.sol";
import "./interfaces/IStableCoinDesk.sol";
import "../goldfinch/interfaces/ISeniorPool.sol";
import "../goldfinch/interfaces/IPoolTokens.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the AlloyxConfig contract
 * @author AlloyX
 */

library ConfigHelper {
  function treasuryAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Treasury));
  }

  function exchangeAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Exchange));
  }

  function configAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Config));
  }

  function goldfinchDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchDesk));
  }

  function stableCoinDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StableCoinDesk));
  }

  function stakeDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StakeDesk));
  }

  function whitelistAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Whitelist));
  }

  function alloyxStakeInfoAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.AlloyxStakeInfo));
  }

  function poolTokensAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function seniorPoolAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPool));
  }

  function sortedGoldfinchTranchesAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SortedGoldfinchTranches));
  }

  function fiduAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FIDU));
  }

  function gfiAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GFI));
  }

  function usdcAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function duraAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.DURA));
  }

  function crwnAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CRWN));
  }

  function backerRewardsAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackerRewards));
  }

  function getWhitelist(AlloyxConfig config) internal view returns (IAlloyxWhitelist) {
    return IAlloyxWhitelist(whitelistAddress(config));
  }

  function getTreasury(AlloyxConfig config) internal view returns (IAlloyxTreasury) {
    return IAlloyxTreasury(treasuryAddress(config));
  }

  function getExchange(AlloyxConfig config) internal view returns (IAlloyxExchange) {
    return IAlloyxExchange(exchangeAddress(config));
  }

  function getConfig(AlloyxConfig config) internal view returns (IAlloyxConfig) {
    return IAlloyxConfig(treasuryAddress(config));
  }

  function getGoldfinchDesk(AlloyxConfig config) internal view returns (IGoldfinchDesk) {
    return IGoldfinchDesk(goldfinchDeskAddress(config));
  }

  function getStableCoinDesk(AlloyxConfig config) internal view returns (IStableCoinDesk) {
    return IStableCoinDesk(stableCoinDeskAddress(config));
  }

  function getStakeDesk(AlloyxConfig config) internal view returns (IStakeDesk) {
    return IStakeDesk(stakeDeskAddress(config));
  }

  function getAlloyxStakeInfo(AlloyxConfig config) internal view returns (IAlloyxStakeInfo) {
    return IAlloyxStakeInfo(alloyxStakeInfoAddress(config));
  }

  function getPoolTokens(AlloyxConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getSeniorPool(AlloyxConfig config) internal view returns (ISeniorPool) {
    return ISeniorPool(seniorPoolAddress(config));
  }

  function getSortedGoldfinchTranches(AlloyxConfig config)
    internal
    view
    returns (ISortedGoldfinchTranches)
  {
    return ISortedGoldfinchTranches(sortedGoldfinchTranchesAddress(config));
  }

  function getFIDU(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(fiduAddress(config));
  }

  function getGFI(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(gfiAddress(config));
  }

  function getUSDC(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(usdcAddress(config));
  }

  function getDURA(AlloyxConfig config) internal view returns (IMintBurnableERC20) {
    return IMintBurnableERC20(duraAddress(config));
  }

  function getCRWN(AlloyxConfig config) internal view returns (IMintBurnableERC20) {
    return IMintBurnableERC20(crwnAddress(config));
  }

  function getBackerRewards(AlloyxConfig config) internal view returns (IBackerRewards) {
    return IBackerRewards(backerRewardsAddress(config));
  }

  function getPermillageDuraRedemption(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageDuraRedemption));
  }

  function getPermillageDuraToFiduFee(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageDuraToFiduFee));
  }

  function getPermillageDuraRepayment(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageDuraRepayment));
  }

  function getPermillageCRWNEarning(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageCRWNEarning));
  }

  function getPermillageJuniorRedemption(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageJuniorRedemption));
  }

  function getPermillageInvestJunior(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageInvestJunior));
  }

  function getPermillageRewardPerYear(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.PermillageRewardPerYear));
  }

  function isPaused(AlloyxConfig config) internal view returns (bool) {
    return config.getBoolean(uint256(ConfigOptions.Booleans.IsPaused));
  }
}