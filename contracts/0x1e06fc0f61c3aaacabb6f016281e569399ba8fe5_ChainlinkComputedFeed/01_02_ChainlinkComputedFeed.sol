// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ChainlinkComputedFeed
 *
 * @author Xocolatl.eth
 *
 * @notice Contract that combines two chainlink price feeds into
 * one resulting feed denominated in another currency asset.
 *
 * @dev For example: [wsteth/eth]-feed and [eth/usd]-feed to return a [wsteth/usd]-feed.
 * Note: Ensure units work, this contract multiplies the feeds.
 */

import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

contract ChainlinkComputedFeed {
  struct ChainlinkResponse {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }

  ///@dev custom errors
  error ChainlinkComputedFeed_invalidInput();
  error ChainlinkComputedFeed_fetchFeedAssetFailed();
  error ChainlinkComputedFeed_fetchFeedInterFailed();
  error ChainlinkComputedFeed_lessThanOrZeroAnswer();
  error ChainlinkComputedFeed_noRoundId();
  error ChainlinkComputedFeed_noValidUpdateAt();
  error ChainlinkComputedFeed_staleFeed();

  string private _description;

  uint8 private immutable _decimals;
  uint8 private immutable _feedAssetDecimals;
  uint8 private immutable _feedInterAssetDecimals;

  IAggregatorV3 public immutable feedAsset;
  IAggregatorV3 public immutable feedInterAsset;

  uint256 public immutable allowedTimeout;

  constructor(
    string memory description_,
    uint8 decimals_,
    address feedAsset_,
    address feedInterAsset_,
    uint256 allowedTimeout_
  ) {
    _description = description_;
    _decimals = decimals_;

    if (feedAsset_ == address(0) || feedInterAsset_ == address(0) || allowedTimeout_ == 0) {
      revert ChainlinkComputedFeed_invalidInput();
    }

    feedAsset = IAggregatorV3(feedAsset_);
    feedInterAsset = IAggregatorV3(feedInterAsset_);

    _feedAssetDecimals = IAggregatorV3(feedAsset_).decimals();
    _feedInterAssetDecimals = IAggregatorV3(feedInterAsset_).decimals();

    allowedTimeout = allowedTimeout_;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function description() external view returns (string memory) {
    return _description;
  }

  function latestAnswer() external view returns (int256) {
    ChainlinkResponse memory clComputed = _computeLatestRoundData();
    return clComputed.answer;
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    ChainlinkResponse memory clComputed = _computeLatestRoundData();
    roundId = clComputed.roundId;
    answer = clComputed.answer;
    startedAt = clComputed.startedAt;
    updatedAt = clComputed.updatedAt;
    answeredInRound = roundId;
  }

  function _computeLatestRoundData() private view returns (ChainlinkResponse memory clComputed) {
    (ChainlinkResponse memory clFeed, ChainlinkResponse memory clInter) = _callandCheckFeeds();

    clComputed.answer = _computeAnswer(clFeed.answer, clInter.answer);
    clComputed.roundId = clFeed.roundId > clInter.roundId ? clFeed.roundId : clInter.roundId;
    clComputed.startedAt =
      clFeed.startedAt < clInter.startedAt ? clFeed.startedAt : clInter.startedAt;
    clComputed.updatedAt =
      clFeed.updatedAt > clInter.updatedAt ? clFeed.updatedAt : clInter.updatedAt;
    clComputed.answeredInRound = clComputed.roundId;
  }

  function _computeAnswer(
    int256 assetAnswer,
    int256 interAssetAnswer
  )
    private
    view
    returns (int256)
  {
    uint256 price = (uint256(assetAnswer) * uint256(interAssetAnswer) * 10 ** (uint256(_decimals)))
      / 10 ** (uint256(_feedAssetDecimals + _feedInterAssetDecimals));
    return int256(price);
  }

  function _callandCheckFeeds()
    private
    view
    returns (ChainlinkResponse memory clFeed, ChainlinkResponse memory clInter)
  {
    (clFeed.roundId, clFeed.answer, clFeed.startedAt, clFeed.updatedAt, clFeed.answeredInRound) =
      feedAsset.latestRoundData();

    (clInter.roundId, clInter.answer, clInter.startedAt, clInter.updatedAt, clInter.answeredInRound)
    = feedInterAsset.latestRoundData();

    // Perform checks to the returned chainlink responses
    if (clFeed.answer <= 0 || clInter.answer <= 0) {
      revert ChainlinkComputedFeed_lessThanOrZeroAnswer();
    } else if (clFeed.roundId == 0 || clInter.roundId == 0) {
      revert ChainlinkComputedFeed_noRoundId();
    } else if (
      clFeed.updatedAt > block.timestamp || clFeed.updatedAt == 0
        || clInter.updatedAt > block.timestamp || clInter.updatedAt == 0
    ) {
      revert ChainlinkComputedFeed_noValidUpdateAt();
    } else if (
      block.timestamp - clFeed.updatedAt > allowedTimeout
        || block.timestamp - clInter.updatedAt > allowedTimeout
    ) {
      revert ChainlinkComputedFeed_staleFeed();
    }
  }
}