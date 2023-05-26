// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {ICbEthRateProvider} from '../interfaces/ICbEthRateProvider.sol';

/**
 * @title CbEthSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (cbETH / USD) pair by using
 * @notice Chainlink Data Feed for (ETH / USD) and rate provider for (cbETH / ETH).
 */
contract CbEthSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (cbETH / Base) pair
   */
  IChainlinkAggregator public immutable CBETH_TO_BASE;

  /**
   * @notice rate provider for (cbETH / Base)
   */
  ICbEthRateProvider public immutable RATE_PROVIDER;

  /**
   * @notice Number of decimals for cbETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  string private _description;

  /**
   * @param cbETHToBaseAggregatorAddress the address of cbETH / BASE feed
   * @param rateProviderAddress the address of the rate provider
   * @param pairName name identifier
   */
  constructor(
    address cbETHToBaseAggregatorAddress,
    address rateProviderAddress,
    string memory pairName
  ) {
    CBETH_TO_BASE = IChainlinkAggregator(cbETHToBaseAggregatorAddress);
    RATE_PROVIDER = ICbEthRateProvider(rateProviderAddress);

    DECIMALS = CBETH_TO_BASE.decimals();

    _description = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return _description;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToBasePrice = CBETH_TO_BASE.latestAnswer();
    int256 ratio = int256(RATE_PROVIDER.exchangeRate());

    if (ethToBasePrice <= 0 || ratio <= 0) {
      return 0;
    }

    return (ethToBasePrice * ratio) / int256(10 ** RATIO_DECIMALS);
  }
}