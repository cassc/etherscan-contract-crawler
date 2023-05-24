// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@balancer-labs/v2-interfaces/contracts/vault/IVault.sol';
import '@balancer-labs/v2-pool-utils/contracts/lib/VaultReentrancyLib.sol';
import './interfaces/IOracle.sol';
import './interfaces/IOracleValidate.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/IBalancerStablePool.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @dev Oracle contract for BALBBAUSD LP Token
 */
contract BALBBA3USDOracle is IOracle, IOracleValidate {
  IBalancerStablePool private constant BAL_BB_A3_USD =
    IBalancerStablePool(0xfeBb0bbf162E64fb9D0dfe186E517d84C395f016);
  IBalancerStablePool private constant BAL_BB_A3_USDC =
    IBalancerStablePool(0xcbFA4532D8B2ade2C261D3DD5ef2A2284f792692);
  IBalancerStablePool private constant BAL_BB_A3_USDT =
    IBalancerStablePool(0xA1697F9Af0875B63DdC472d6EeBADa8C1fAB8568);
  IBalancerStablePool private constant BAL_BB_A3_DAI =
    IBalancerStablePool(0x6667c6fa9f2b3Fc1Cc8D85320b62703d938E4385);

  IChainlinkAggregator private constant DAI =
    IChainlinkAggregator(0x773616E4d11A78F511299002da57A0a94577F1f4);
  IChainlinkAggregator private constant USDC =
    IChainlinkAggregator(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
  IChainlinkAggregator private constant USDT =
    IChainlinkAggregator(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);

  address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  /**
   * @dev Get LP Token Price
   */
  function _get() internal view returns (uint256) {
    uint256 usdcLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_USDC);
    uint256 usdtLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_USDT);
    uint256 daiLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_DAI);

    uint256 minValue = Math.min(
      Math.min(usdcLinearPoolPrice, usdtLinearPoolPrice),
      daiLinearPoolPrice
    );

    return (BAL_BB_A3_USD.getRate() * minValue) / 1e18;
  }

  /**
   * @dev Get price for LinearPool LP Token
   */
  function _getLinearPoolPrice(IBalancerStablePool _poolAddress) internal view returns (uint256) {
    IChainlinkAggregator mainToken;

    if (_poolAddress == BAL_BB_A3_USDC) mainToken = USDC;
    else if (_poolAddress == BAL_BB_A3_USDT) mainToken = USDT;
    else mainToken = DAI;

    (, int256 mainTokenPrice, , , ) = mainToken.latestRoundData();
    return (_poolAddress.getRate() * uint256(mainTokenPrice)) / 1e18;
  }

  // Get the latest exchange rate, if no valid (recent) rate is available, return false
  /// @inheritdoc IOracle
  function get() public view override returns (bool, uint256) {
    return (true, _get());
  }

  // Check the last exchange rate without any state changes
  /// @inheritdoc IOracle
  function peek() public view override returns (bool, int256) {
    return (true, int256(_get()));
  }

  // Check the current spot exchange rate without any state changes
  /// @inheritdoc IOracle
  function latestAnswer() external view override returns (int256 rate) {
    return int256(_get());
  }

  // Check the oracle (re-entrancy)
  /// @inheritdoc IOracleValidate
  function check() external {
    VaultReentrancyLib.ensureNotInVaultContext(IVault(BALANCER_VAULT));
  }
}