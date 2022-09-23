// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/AggregatorV3Interface.sol";

/**
 * @title Contract to record a new answer when the roundId increments.
 */
contract LastUpdater is KeeperCompatibleInterface {
  /// @notice Struct to record round data from AggregatorV3Interface
  struct RoundData {
    uint80 roundId;
    int256 answer;
    /// @dev The block timestamp at which this round was updated by this Keeper
    uint256 timestamp;
  }

  /**
   * @notice Details of the last round returned by the feed.
   * @dev Updated whenever the target feed has a new round with data.
   */
  RoundData public s_lastRound;

  /// @notice A reference to the feed that the contract should read data from
  AggregatorV3Interface public immutable s_feed;

  event FeedAnswerUpdated(int256 _newValue, uint256 _time);

  constructor(address _feedContractAddress) {
    AggregatorV3Interface feed = AggregatorV3Interface(_feedContractAddress);
    s_feed = feed;

    // Initialise `s_lastRound` to the latest round
    (uint80 roundId, int256 answer, , , ) = feed.latestRoundData();
    s_lastRound = RoundData(roundId, answer, block.timestamp);
  }

  /**
   * @notice Determines whether or not the contract needs to perform an upkeep
   * @return upkeepNeeded as a boolean flag to tell Keepers whether or not to perform an upkeep
   */
  function checkUpkeep(bytes calldata) external view virtual override returns (bool upkeepNeeded, bytes memory) {
    (upkeepNeeded, , ) = checkForUpdate();
  }

  /**
   * @notice Performs the automated Keepers job to update the contract's timestamp if the feed was updated
   */
  function performUpkeep(bytes calldata) external virtual override {
    updateAnswer();
  }

  /**
   * @dev Check if the feed was updated, and update `s_lastRound` if it was.
   */
  function updateAnswer() internal returns (bool, int256) {
    (bool hasNewAnswer, uint80 roundId, int256 latestAnswer) = checkForUpdate();
    if (hasNewAnswer) {
      s_lastRound = RoundData(roundId, latestAnswer, block.timestamp);
      emit FeedAnswerUpdated(latestAnswer, block.timestamp);
    }
    return (hasNewAnswer, latestAnswer);
  }

  /**
   * @dev Check the latest round from the feed and indicate if it has been updated by
   *  checking if the `roundId` of the feed did increment.
   *  `roundId` can be assumed to increment when `latestRoundData` is called directly
   *  on an `AggregatorV3Interface` implementation.
   */
  function checkForUpdate()
    internal
    view
    returns (
      bool changed,
      uint80 roundId,
      int256 latestAnswer
    )
  {
    (roundId, latestAnswer, , , ) = s_feed.latestRoundData();
    if (roundId > s_lastRound.roundId) {
      changed = true;
    }
  }
}