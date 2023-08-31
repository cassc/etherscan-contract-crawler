// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {AggregatorV2V3Interface} from './dependencies/chainlink/AggregatorV2V3Interface.sol';
import {IHESynchronicityPriceAdapter} from './interfaces/IHESynchronicityPriceAdapter.sol';

/**
 * @title HESynchronicityPriceAdapter
 * @author Hope Ecosystem
 * @notice Price adapter to calculate price of (Asset / Base) pair by using
 * @notice Chainlink Data Feeds for (Asset / Peg) and (Peg / Base) pairs.
 * @notice For example it can be used to calculate stETH / USD
 * @notice based on stETH / ETH and ETH / USD feeds.
 */
contract WBTCSynchronicityPriceAdapter is IHESynchronicityPriceAdapter {
  /**
   * @notice Price feed for (Base / Peg) pair
   */
  AggregatorV2V3Interface public immutable PEG_TO_BASE;

  /**
   * @notice Price feed for (Asset / Peg) pair
   */
  AggregatorV2V3Interface public immutable ASSET_TO_PEG;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  /**
   * @notice This is a parameter to bring the resulting answer with the proper precision.
   * @notice will be equal to 10 to the power of the sum decimals of feeds
   */
  int256 public immutable DENOMINATOR;

  /**
   * @notice Maximum number of resulting and feed decimals
   */
  uint8 public constant MAX_DECIMALS = 18;

  /**
   * @param pegToBaseAggregatorAddress the address of PEG / BASE feed
   * @param assetToPegAggregatorAddress the address of the ASSET / PEG feed
   * @param decimals precision of the answer
   */
  constructor(address pegToBaseAggregatorAddress, address assetToPegAggregatorAddress, uint8 decimals) {
    PEG_TO_BASE = AggregatorV2V3Interface(pegToBaseAggregatorAddress);
    ASSET_TO_PEG = AggregatorV2V3Interface(assetToPegAggregatorAddress);

    if (decimals > MAX_DECIMALS) revert DecimalsAboveLimit();
    if (PEG_TO_BASE.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();
    if (ASSET_TO_PEG.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();

    DECIMALS = decimals;

    // equal to 10 to the power of the sum decimals of feeds
    unchecked {
      DENOMINATOR = int256(10 ** (PEG_TO_BASE.decimals() + ASSET_TO_PEG.decimals()));
    }
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 assetToPegPrice = ASSET_TO_PEG.latestAnswer();
    int256 pegToBasePrice = PEG_TO_BASE.latestAnswer();

    if (assetToPegPrice <= 0 || pegToBasePrice <= 0) {
      return 0;
    }

    return (assetToPegPrice * pegToBasePrice * int256(10 ** DECIMALS)) / (DENOMINATOR);
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function description() external view virtual override returns (string memory) {
    return 'wBTC/USD';
  }

  /// @inheritdoc IHESynchronicityPriceAdapter
  function decimals() external view virtual override returns (uint8) {
    return DECIMALS;
  }
}