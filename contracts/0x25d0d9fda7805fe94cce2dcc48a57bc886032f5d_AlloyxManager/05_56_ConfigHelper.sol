// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../goldfinch/interfaces/ISeniorPool.sol";
import "../../goldfinch/interfaces/IPoolTokens.sol";
import "../interfaces/IAlloyxWhitelist.sol";
import "../interfaces/IAlloyxTreasury.sol";
import "../interfaces/IGoldfinchDesk.sol";
import "../interfaces/ITruefiDesk.sol";
import "../interfaces/IBackerRewards.sol";
import "../interfaces/IMapleDesk.sol";
import "../interfaces/IClearPoolDesk.sol";
import "../interfaces/IRibbonDesk.sol";
import "../interfaces/IRibbonLendDesk.sol";
import "../interfaces/ICredixDesk.sol";
import "../interfaces/ICredixOracle.sol";
import "../interfaces/IAlloyxManager.sol";
import "../interfaces/IAlloyxStakeInfo.sol";
import "../interfaces/IAlloyxOperator.sol";
import "../interfaces/IStakeDesk.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IFluxDesk.sol";
import "../interfaces/IBackedDesk.sol";
import "../interfaces/IBackedOracle.sol";
import "../interfaces/IERC20Token.sol";
import "./AlloyxConfig.sol";
import "./ConfigOptions.sol";
import "../interfaces/IWalletDesk.sol";
import "../interfaces/IOpenEdenDesk.sol";
import "../interfaces/IAlloyxDesk.sol";
import "../interfaces/IAlloyxV1StableCoinDesk.sol";
import "../interfaces/IAlloyxV1Exchange.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the AlloyxConfig contract
 * @author AlloyX
 */

library ConfigHelper {
  function managerAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Manager));
  }

  function alyxAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ALYX));
  }

  function treasuryAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Treasury));
  }

  function configAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Config));
  }

  function permanentStakeInfoAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PermanentStakeInfo));
  }

  function regularStakeInfoAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RegularStakeInfo));
  }

  function stakeDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StakeDesk));
  }

  function goldfinchDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchDesk));
  }

  function truefiDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TruefiDesk));
  }

  function mapleDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.MapleDesk));
  }

  function clearPoolDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ClearPoolDesk));
  }

  function ribbonDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RibbonDesk));
  }

  function ribbonLendDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RibbonLendDesk));
  }

  function credixDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CredixDesk));
  }

  function credixOracleAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CredixOracle));
  }

  function backerRewardsAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackerRewards));
  }

  function whitelistAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Whitelist));
  }

  function poolTokensAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function seniorPoolAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPool));
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

  function mplAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.MPL));
  }

  function wethAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.WETH));
  }

  function swapRouterAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SwapRouter));
  }

  function operatorAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Operator));
  }

  function fluxTokenAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FluxToken));
  }

  function fluxDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FluxDesk));
  }

  function backedDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedDesk));
  }

  function backedOracleAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedOracle));
  }

  function backedTokenAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedToken));
  }

  function walletDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.WalletDesk));
  }

  function openEdenDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.OpenEdenDesk));
  }

  function alloyxV1DeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.AlloyxV1Desk));
  }

  function alloyxV1StableCoinDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.AlloyxV1StableCoinDesk));
  }

  function alloyxV1ExchangeAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.AlloyxV1Exchange));
  }

  function alloyxV1DuraAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.AlloyxV1Dura));
  }

  function getManager(AlloyxConfig config) internal view returns (IAlloyxManager) {
    return IAlloyxManager(managerAddress(config));
  }

  function getAlyx(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(alyxAddress(config));
  }

  function getTreasury(AlloyxConfig config) internal view returns (IAlloyxTreasury) {
    return IAlloyxTreasury(treasuryAddress(config));
  }

  function getPermanentStakeInfo(AlloyxConfig config) internal view returns (IAlloyxStakeInfo) {
    return IAlloyxStakeInfo(permanentStakeInfoAddress(config));
  }

  function getRegularStakeInfo(AlloyxConfig config) internal view returns (IAlloyxStakeInfo) {
    return IAlloyxStakeInfo(regularStakeInfoAddress(config));
  }

  function getConfig(AlloyxConfig config) internal view returns (IAlloyxConfig) {
    return IAlloyxConfig(treasuryAddress(config));
  }

  function getStakeDesk(AlloyxConfig config) internal view returns (IStakeDesk) {
    return IStakeDesk(stakeDeskAddress(config));
  }

  function getGoldfinchDesk(AlloyxConfig config) internal view returns (IGoldfinchDesk) {
    return IGoldfinchDesk(goldfinchDeskAddress(config));
  }

  function getTruefiDesk(AlloyxConfig config) internal view returns (ITruefiDesk) {
    return ITruefiDesk(truefiDeskAddress(config));
  }

  function getMapleDesk(AlloyxConfig config) internal view returns (IMapleDesk) {
    return IMapleDesk(mapleDeskAddress(config));
  }

  function getClearPoolDesk(AlloyxConfig config) internal view returns (IClearPoolDesk) {
    return IClearPoolDesk(clearPoolDeskAddress(config));
  }

  function getRibbonDesk(AlloyxConfig config) internal view returns (IRibbonDesk) {
    return IRibbonDesk(ribbonDeskAddress(config));
  }

  function getRibbonLendDesk(AlloyxConfig config) internal view returns (IRibbonLendDesk) {
    return IRibbonLendDesk(ribbonLendDeskAddress(config));
  }

  function getCredixDesk(AlloyxConfig config) internal view returns (ICredixDesk) {
    return ICredixDesk(credixDeskAddress(config));
  }

  function getCredixOracle(AlloyxConfig config) internal view returns (ICredixOracle) {
    return ICredixOracle(credixOracleAddress(config));
  }

  function getBackerRewards(AlloyxConfig config) internal view returns (IBackerRewards) {
    return IBackerRewards(backerRewardsAddress(config));
  }

  function getWhitelist(AlloyxConfig config) internal view returns (IAlloyxWhitelist) {
    return IAlloyxWhitelist(whitelistAddress(config));
  }

  function getPoolTokens(AlloyxConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getSeniorPool(AlloyxConfig config) internal view returns (ISeniorPool) {
    return ISeniorPool(seniorPoolAddress(config));
  }

  function getFIDU(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(fiduAddress(config));
  }

  function getGFI(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(gfiAddress(config));
  }

  function getUSDC(AlloyxConfig config) internal view returns (IERC20Token) {
    return IERC20Token(usdcAddress(config));
  }

  function getMPL(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(mplAddress(config));
  }

  function getWETH(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(wethAddress(config));
  }

  function getSwapRouter(AlloyxConfig config) internal view returns (ISwapRouter) {
    return ISwapRouter(swapRouterAddress(config));
  }

  function getOperator(AlloyxConfig config) internal view returns (IAlloyxOperator) {
    return IAlloyxOperator(operatorAddress(config));
  }

  function getFluxToken(AlloyxConfig config) internal view returns (ICToken) {
    return ICToken(fluxTokenAddress(config));
  }

  function getFluxDesk(AlloyxConfig config) internal view returns (IFluxDesk) {
    return IFluxDesk(fluxDeskAddress(config));
  }

  function getBackedDesk(AlloyxConfig config) internal view returns (IBackedDesk) {
    return IBackedDesk(backedDeskAddress(config));
  }

  function getBackedOracle(AlloyxConfig config) internal view returns (IBackedOracle) {
    return IBackedOracle(backedOracleAddress(config));
  }

  function getBackedToken(AlloyxConfig config) internal view returns (IERC20Token) {
    return IERC20Token(backedTokenAddress(config));
  }

  function getWalletDesk(AlloyxConfig config) internal view returns (IWalletDesk) {
    return IWalletDesk(walletDeskAddress(config));
  }

  function getOpenEdenDesk(AlloyxConfig config) internal view returns (IOpenEdenDesk) {
    return IOpenEdenDesk(openEdenDeskAddress(config));
  }

  function getAlloyxV1Desk(AlloyxConfig config) internal view returns (IAlloyxDesk) {
    return IAlloyxDesk(alloyxV1DeskAddress(config));
  }

  function getAlloyxV1StableCoinDesk(AlloyxConfig config) internal view returns (IAlloyxV1StableCoinDesk) {
    return IAlloyxV1StableCoinDesk(alloyxV1StableCoinDeskAddress(config));
  }

  function getAlloyxV1Exchange(AlloyxConfig config) internal view returns (IAlloyxV1Exchange) {
    return IAlloyxV1Exchange(alloyxV1ExchangeAddress(config));
  }

  function getAlloyxV1Dura(AlloyxConfig config) internal view returns (IERC20Token) {
    return IERC20Token(alloyxV1DuraAddress(config));
  }

  function getInflationPerYearForProtocolFee(AlloyxConfig config) internal view returns (uint256) {
    uint256 inflationPerYearForProtocolFee = config.getNumber(uint256(ConfigOptions.Numbers.InflationPerYearForProtocolFee));
    require(inflationPerYearForProtocolFee <= 10000, "inflation per year should be smaller or equal to 10000");
    return inflationPerYearForProtocolFee;
  }

  function getRegularStakerProportion(AlloyxConfig config) internal view returns (uint256) {
    uint256 regularStakerProportion = config.getNumber(uint256(ConfigOptions.Numbers.RegularStakerProportion));
    require(regularStakerProportion <= 10000, "regular staker proportion should be smaller or equal to 10000");
    return regularStakerProportion;
  }

  function getPermanentStakerProportion(AlloyxConfig config) internal view returns (uint256) {
    uint256 permanentStakerProportion = config.getNumber(uint256(ConfigOptions.Numbers.PermanentStakerProportion));
    require(permanentStakerProportion <= 10000, "permanent staker should be smaller or equal to 10000");
    return permanentStakerProportion;
  }

  function getUniswapFeeBasePoint(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.UniswapFeeBasePoint));
  }

  function getMinDelay(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.MinDelay));
  }

  function getQuorumPercentage(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.QuorumPercentage));
  }

  function getVotingPeriod(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.VotingPeriod));
  }

  function getVotingDelay(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.VotingDelay));
  }

  function getThresholdAlyxForVaultCreation(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ThresholdAlyxForVaultCreation));
  }

  function getThresholdUsdcForVaultCreation(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ThresholdUsdcForVaultCreation));
  }

  function isPaused(AlloyxConfig config) internal view returns (bool) {
    return config.getBoolean(uint256(ConfigOptions.Booleans.IsPaused));
  }
}