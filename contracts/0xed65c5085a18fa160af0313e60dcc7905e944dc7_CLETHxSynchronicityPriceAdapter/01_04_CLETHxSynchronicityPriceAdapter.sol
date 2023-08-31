// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IChainlinkAggregator} from './interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from './interfaces/ICLSynchronicityPriceAdapter.sol';
import {IStaderStakePoolManager} from './interfaces/IStaderStakePoolManager.sol';

/**
 * @title CLETHxSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (ETHx / USD) pair by using
 * @notice Chainlink Data Feed for (ETH / USD) pair and (ETHx / ETH) ratio.
 */
contract CLETHxSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (ETH / USD) pair
   */
  IChainlinkAggregator public immutable ETH_TO_USD;

  /**
   * @notice SSPM contract
   */
  IStaderStakePoolManager public immutable STADER_STAKE_POOL_MANAGER;

  /**
   * @notice Number of decimals for the ETHx / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  string private _name;

  /**
   * @param ethToUSDAggregatorAddress the address of ETH / USD feed
   * @param stakePoolManager the address of staderStakePoolManagerContract
   * @param pairName name identifier
   */
  constructor(address ethToUSDAggregatorAddress, address stakePoolManager, string memory pairName) {
    ETH_TO_USD = IChainlinkAggregator(ethToUSDAggregatorAddress);
    STADER_STAKE_POOL_MANAGER = IStaderStakePoolManager(stakePoolManager);

    _name = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function name() external view returns (string memory) {
    return _name;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToUsdPrice = ETH_TO_USD.latestAnswer();
    int256 ethToETHxRatio = int256(STADER_STAKE_POOL_MANAGER.getExchangeRate());

    if (ethToUsdPrice <= 0) {
      return 0;
    }

    return ((ethToUsdPrice * ethToETHxRatio) / int256(10 ** RATIO_DECIMALS));
  }
}