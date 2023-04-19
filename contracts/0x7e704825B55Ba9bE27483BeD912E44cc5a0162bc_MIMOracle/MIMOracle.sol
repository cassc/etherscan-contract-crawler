/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;



interface IOracle {
  /// @notice Get the latest price.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function get() external returns (bool success, uint256 rate);

  /// @notice Check the last price without any state changes.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function peek() external view returns (bool success, int256 rate);

  /// @notice Check the current spot price without any state changes. For oracles like TWAP this will be different from peek().
  /// @return rate The rate of the requested asset / pair / pool.
  function latestAnswer() external view returns (int256 rate);
}


interface IChainlinkAggregator {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// Using the same Copyleft License as in the original Repository
/**
 * @dev Oracle contract for MIM Token
 */
contract MIMOracle is IOracle {
  IChainlinkAggregator private constant MIM =
    IChainlinkAggregator(0x7A364e8770418566e3eb2001A96116E6138Eb32F);
  IChainlinkAggregator private constant ETH =
    IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  /**
   * @dev Get Token Price
   */
  function _get() internal view returns (uint256) {
    (, int256 mimPrice, , , ) = MIM.latestRoundData();
    (, int256 ethPrice, , , ) = ETH.latestRoundData();

    return (uint256(mimPrice) * 1e18) / uint256(ethPrice);
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
}