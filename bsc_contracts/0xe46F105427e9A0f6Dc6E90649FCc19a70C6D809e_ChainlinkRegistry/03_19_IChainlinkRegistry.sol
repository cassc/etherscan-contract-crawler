// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol';
import './utils/ICollectableDust.sol';

interface IChainlinkRegistry is FeedRegistryInterface, ICollectableDust {
  /// @notice A Chainlink feed
  struct Feed {
    address base;
    address quote;
    address feed;
  }

  /// @notice A feed that was assigned
  struct AssignedFeed {
    // The feed
    AggregatorV2V3Interface feed;
    // Whether the feed is a proxy or the actual aggregator
    bool isProxy;
  }

  /// @notice Thrown when trying to execute a call with a base and quote that don't have a feed assigned
  error FeedNotFound();

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /**
   * @notice Thrown when a function that is not supported is called
   *         We want to implement Chainlink's feed registry interface completely, but some of the functions
   *         don't make sense in our context. Specially those meant for management. So we will implement
   *         those functions, but we will revert when they are called
   */
  error FunctionNotSupported();

  /**
   * @notice Emitted when fees are modified
   * @param feeds The feeds that were modified
   */
  event FeedsModified(Feed[] feeds);

  /**
   * @notice Returns the assigned feed for a specific quote and base
   * @param base The base asset address
   * @param quote The quote asset address
   * @return The assigned feed (or zero-ed if none was assigned)
   */
  function getAssignedFeed(address base, address quote) external view returns (AssignedFeed memory);

  /**
   * @notice Sets or deletes feeds for specific quotes and bases
   * @dev A feed's address could be set to the zero address to delete a feed
   *      Can only be set by admins
   * @param feedsToAssign The feeds to set
   */
  function assignFeeds(Feed[] calldata feedsToAssign) external;
}