//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import {Errors} from './Errors.sol';
import {DataTypes, MAXIMUM_VALID_DURATION_IDX, MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX} from './DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library NFTStatus {
  uint256 constant MAXIMUM_DURATION_IDX_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC; // prettier-ignore
  uint256 constant MINIMUM_STRIKE_PRICE_GAP_IDX_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE3; // prettier-ignore
  uint256 constant IF_ON_MARKET_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDF; // prettier-ignore
  uint256 constant EXERCISE_TIME_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFF; // prettier-ignore
  uint256 constant END_TIME_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant MINIMUM_STRIKE_PRICE_MASK =       0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STRIKE_PRICE_MASK =             0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the Duration index, the start bit is 0 (up to 1), hence no bitshifting is needed
  uint256 constant MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION = 2;
  uint256 constant IF_ON_MARKET_START_BIT_POSITION = 5;
  uint256 constant EXERCISE_TIME_START_BIT_POSITION = 48;
  uint256 constant END_TIME_START_BIT_POSITION = 88;
  uint256 constant MINIMUM_STRIKE_PRICE_START_BIT_POSITION = 128;
  uint256 constant STRIKE_PRICE_START_BIT_POSITION = 192;
  

  
  function setMaximumDurationIdx(DataTypes.NFTStatusMap memory self, uint8 durationIdx) internal pure {
    require(durationIdx <= uint8(MAXIMUM_VALID_DURATION_IDX), Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);
    self.data = (self.data & MAXIMUM_DURATION_IDX_MASK) | uint256(durationIdx);
  }

  function getMaximumDurationIdx(DataTypes.NFTStatusMap storage self) internal view returns (uint8) {
    return uint8(self.data & ~MAXIMUM_DURATION_IDX_MASK);
  }

  function setMinimumStrikePriceGapIdx(DataTypes.NFTStatusMap memory self, uint8 strikePriceGapIdx) internal pure
  {
    require(strikePriceGapIdx <= uint8(MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX), Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);

    self.data =
      (self.data & MINIMUM_STRIKE_PRICE_GAP_IDX_MASK) |
      (uint256(strikePriceGapIdx) << MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION);
  }

  function getMinimumStrikePriceGapIdx(DataTypes.NFTStatusMap storage self) internal view returns (uint8)
  {
    return uint8((self.data & ~MINIMUM_STRIKE_PRICE_GAP_IDX_MASK) >> MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION);
  }

  function setIfOnMarket(DataTypes.NFTStatusMap memory self, bool ifOnMarket) internal pure
  {
    self.data = 
        (self.data & IF_ON_MARKET_MASK) |
        (uint256(ifOnMarket?1:0) << IF_ON_MARKET_START_BIT_POSITION);
  }

  function getIfOnMarket(DataTypes.NFTStatusMap storage self) internal view returns (bool)
  {
    return (self.data & ~IF_ON_MARKET_MASK) != 0;
  }

  function setExerciseTime(DataTypes.NFTStatusMap memory self, uint40 exerciseTime) internal pure
  {
    self.data = 
        (self.data & EXERCISE_TIME_MASK) |
        (uint256(exerciseTime) << EXERCISE_TIME_START_BIT_POSITION);
  }

  function getExerciseTime(DataTypes.NFTStatusMap storage self) internal view returns (uint40)
  {
    return uint40((self.data & ~EXERCISE_TIME_MASK) >> EXERCISE_TIME_START_BIT_POSITION);
  }

  function setEndTime(DataTypes.NFTStatusMap memory self, uint40 endTime) internal pure
  {
    self.data = 
        (self.data & END_TIME_MASK) |
        (uint256(endTime) << END_TIME_START_BIT_POSITION);
  }

  function getEndTime(DataTypes.NFTStatusMap storage self) internal view returns (uint40)
  {
    return uint40((self.data & ~END_TIME_MASK) >> END_TIME_START_BIT_POSITION);
  }

  function setMinimumStrikePrice(DataTypes.NFTStatusMap memory self, uint64 strikePriceLimit) internal pure
  {
    self.data = 
        (self.data & MINIMUM_STRIKE_PRICE_MASK) |
        (uint256(strikePriceLimit) << MINIMUM_STRIKE_PRICE_START_BIT_POSITION);
  }

  function getMinimumStrikePrice(DataTypes.NFTStatusMap storage self) internal view returns (uint64)
  {
    return uint64((self.data & ~MINIMUM_STRIKE_PRICE_MASK) >> MINIMUM_STRIKE_PRICE_START_BIT_POSITION);
  }

  function setStrikePrice(DataTypes.NFTStatusMap memory self, uint64 strikePrice) internal pure
  {
    self.data = 
        (self.data & STRIKE_PRICE_MASK) |
        (uint256(strikePrice) << STRIKE_PRICE_START_BIT_POSITION);
  }

  function getStrikePrice(DataTypes.NFTStatusMap storage self) internal view returns (uint64)
  {
    return uint64((self.data & ~STRIKE_PRICE_MASK) >> STRIKE_PRICE_START_BIT_POSITION);
  }

}