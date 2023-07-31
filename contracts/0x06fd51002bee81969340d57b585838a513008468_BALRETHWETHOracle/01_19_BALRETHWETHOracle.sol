// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity ^0.8.0;

import '@balancer-labs/v2-interfaces/contracts/vault/IVault.sol';
import {VaultReentrancyLib} from '@balancer-labs/v2-pool-utils/contracts/lib/VaultReentrancyLib.sol';
import './interfaces/IOracle.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/IBalancerStablePool.sol';
import '../interfaces/IRocketTokenRETH.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @dev Oracle contract for BALRETHWETH LP Token
 */
contract BALRETHWETHOracle is IOracle {
  IChainlinkAggregator private constant RETH_PRICE =
    IChainlinkAggregator(0x536218f9E9Eb48863970252233c8F271f554C2d0);
  IRocketTokenRETH private constant RETH =
    IRocketTokenRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
  IBalancerStablePool private constant BALRETHWETH =
    IBalancerStablePool(0x1E19CF2D73a72Ef1332C882F20534B6519Be0276);
  address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  /**
   * @dev Get LP Token Price
   */
  function _get() internal view returns (uint256) {
    // Check the oracle (re-entrancy)
    VaultReentrancyLib.ensureNotInVaultContext(IVault(BALANCER_VAULT));

    (, int256 rETHPrice, , uint256 updatedAt, ) = RETH_PRICE.latestRoundData();

    require(RETH_PRICE.decimals() == 18, Errors.O_WRONG_PRICE);
    require(updatedAt > block.timestamp - 1 days, Errors.O_WRONG_PRICE);
    require(rETHPrice > 0, Errors.O_WRONG_PRICE);

    uint256 redemptionPrice = RETH.getExchangeRate();
    uint256 normPrice = (uint256(rETHPrice) * 1e18) / redemptionPrice;
    uint256 minValue = Math.min(normPrice, 1e18);

    return (BALRETHWETH.getRate() * minValue) / 1e18;
  }

  // Get the latest exchange rate, if no valid (recent) rate is available, return false
  /// @inheritdoc IOracle
  function get() external view override returns (bool, uint256) {
    return (true, _get());
  }

  // Check the last exchange rate without any state changes
  /// @inheritdoc IOracle
  function peek() external view override returns (bool, int256) {
    return (true, int256(_get()));
  }

  // Check the current spot exchange rate without any state changes
  /// @inheritdoc IOracle
  function latestAnswer() external view override returns (int256 rate) {
    return int256(_get());
  }
}