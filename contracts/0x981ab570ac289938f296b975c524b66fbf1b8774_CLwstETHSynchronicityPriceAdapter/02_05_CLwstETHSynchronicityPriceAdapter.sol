// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {IStETH} from '../interfaces/IStETH.sol';
import {CLSynchronicityPriceAdapterPegToBase} from './CLSynchronicityPriceAdapterPegToBase.sol';

/**
 * @title CLwstETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (wstETH / USD) pair by using
 * @notice Chainlink Data Feeds for (stETH / ETH) and (ETH / USd) pairs and (wstETH / stETH) ratio.
 */
contract CLwstETHSynchronicityPriceAdapter is
  CLSynchronicityPriceAdapterPegToBase
{
  /**
   * @notice stETH token contract
   */
  IStETH public immutable STETH;

  /**
   * @notice Number of decimals for wstETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  constructor(
    address pegToBaseAggregatorAddress,
    address assetToPegAggregatorAddress,
    uint8 decimals,
    address stETHAddress
  )
    CLSynchronicityPriceAdapterPegToBase(
      pegToBaseAggregatorAddress,
      assetToPegAggregatorAddress,
      decimals
    )
  {
    STETH = IStETH(stETHAddress);
  }

  /// @inheritdoc CLSynchronicityPriceAdapterPegToBase
  function latestAnswer() public view override returns (int256) {
    int256 stethToUsdPrice = super.latestAnswer();

    int256 ratio = int256(STETH.getPooledEthByShares(10 ** RATIO_DECIMALS));

    return (stethToUsdPrice * int256(ratio)) / int256(10 ** RATIO_DECIMALS);
  }
}