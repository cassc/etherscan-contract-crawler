// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {AggregatorV2V3Interface} from './dependencies/chainlink/AggregatorV2V3Interface.sol';
import {IHESynchronicityPriceAdapter} from './interfaces/IHESynchronicityPriceAdapter.sol';
import {IStETH} from './interfaces/IStETH.sol';

/**
 * @title WstETHSynchronicityPriceAdapter
 * @author Hope Ecosystem
 * @notice Price adapter to calculate price of (wstETH / USD) pair by using
 * @notice Chainlink data feed for (ETH / USD) and (wstETH / stETH) ratio.
 */
contract WstETHSynchronicityPriceAdapter is IHESynchronicityPriceAdapter {
  /**
   * @notice Price feed for (ETH / Base) pair
   */
  AggregatorV2V3Interface public immutable ETH_TO_BASE;

  /**
   * @notice stETH token contract to get ratio
   */
  IStETH public immutable STETH;

  /**
   * @notice Number of decimals for wstETH / stETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  /**
   * @param ethToBaseAggregatorAddress the address of ETH / BASE feed
   * @param stEthAddress the address of the stETH contract
   */
  constructor(address ethToBaseAggregatorAddress, address stEthAddress) {
    ETH_TO_BASE = AggregatorV2V3Interface(ethToBaseAggregatorAddress);
    STETH = IStETH(stEthAddress);

    DECIMALS = ETH_TO_BASE.decimals();
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return 'wstETH/ETH/USD';
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToBasePrice = ETH_TO_BASE.latestAnswer();
    int256 ratio = int256(STETH.getPooledEthByShares(10 ** RATIO_DECIMALS));

    if (ethToBasePrice <= 0 || ratio <= 0) {
      return 0;
    }

    return (ethToBasePrice * ratio) / int256(10 ** RATIO_DECIMALS);
  }
}