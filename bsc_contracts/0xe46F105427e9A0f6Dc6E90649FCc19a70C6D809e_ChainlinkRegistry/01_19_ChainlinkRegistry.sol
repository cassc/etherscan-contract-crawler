// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '../interfaces/IChainlinkRegistry.sol';
import '../utils/CollectableDust.sol';

contract ChainlinkRegistry is AccessControl, CollectableDust, IChainlinkRegistry {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  mapping(bytes32 => AssignedFeed) internal _feeds;

  constructor(address _superAdmin, address[] memory _initialAdmins) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i = 0; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc IChainlinkRegistry
  function getAssignedFeed(address _base, address _quote) external view returns (AssignedFeed memory) {
    return _feeds[_getKey(_base, _quote)];
  }

  /// @inheritdoc IChainlinkRegistry
  function assignFeeds(Feed[] calldata _feedsToAssign) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _feedsToAssign.length; i++) {
      Feed memory _feed = _feedsToAssign[i];
      _feeds[_getKey(_feed.base, _feed.quote)] = AssignedFeed(AggregatorV2V3Interface(_feed.feed), _isProxy(_feed.feed));
    }
    emit FeedsModified(_feedsToAssign);
  }

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external onlyRole(ADMIN_ROLE) {
    _sendDust(_to, _token, _amount);
  }

  function _getAssignedFeedOrFail(address _base, address _quote) internal view returns (AggregatorV2V3Interface) {
    AggregatorV2V3Interface _feed = _feeds[_getKey(_base, _quote)].feed;
    if (address(_feed) == address(0)) revert FeedNotFound();
    return _feed;
  }

  function _isProxy(address _feed) internal view returns (bool) {
    if (_feed == address(0)) return false;
    try IAggregatorProxy(_feed).aggregator() returns (AggregatorV2V3Interface) {
      return true;
    } catch {
      return false;
    }
  }

  /// @inheritdoc FeedRegistryInterface
  function decimals(address _base, address _quote) external view returns (uint8) {
    return _getAssignedFeedOrFail(_base, _quote).decimals();
  }

  /// @inheritdoc FeedRegistryInterface
  function description(address _base, address _quote) external view returns (string memory) {
    return _getAssignedFeedOrFail(_base, _quote).description();
  }

  /// @inheritdoc FeedRegistryInterface
  function version(address _base, address _quote) external view returns (uint256) {
    return _getAssignedFeedOrFail(_base, _quote).version();
  }

  /// @inheritdoc FeedRegistryInterface
  function latestRoundData(address _base, address _quote)
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return _getAssignedFeedOrFail(_base, _quote).latestRoundData();
  }

  /// @inheritdoc FeedRegistryInterface
  function getRoundData(
    address _base,
    address _quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return _getAssignedFeedOrFail(_base, _quote).getRoundData(_roundId);
  }

  /// @inheritdoc FeedRegistryInterface
  function latestAnswer(address _base, address _quote) external view returns (int256) {
    return _getAssignedFeedOrFail(_base, _quote).latestAnswer();
  }

  /// @inheritdoc FeedRegistryInterface
  function latestTimestamp(address _base, address _quote) external view returns (uint256) {
    return _getAssignedFeedOrFail(_base, _quote).latestTimestamp();
  }

  /// @inheritdoc FeedRegistryInterface
  function latestRound(address _base, address _quote) external view returns (uint256) {
    return _getAssignedFeedOrFail(_base, _quote).latestRound();
  }

  /// @inheritdoc FeedRegistryInterface
  function getAnswer(
    address _base,
    address _quote,
    uint256 _roundId
  ) external view returns (int256) {
    return _getAssignedFeedOrFail(_base, _quote).getAnswer(_roundId);
  }

  /// @inheritdoc FeedRegistryInterface
  function getTimestamp(
    address _base,
    address _quote,
    uint256 _roundId
  ) external view returns (uint256) {
    return _getAssignedFeedOrFail(_base, _quote).getTimestamp(_roundId);
  }

  /// @inheritdoc FeedRegistryInterface
  function getFeed(address _base, address _quote) external view returns (AggregatorV2V3Interface) {
    AssignedFeed memory _feed = _feeds[_getKey(_base, _quote)];
    if (address(_feed.feed) == address(0)) revert FeedNotFound();
    if (_feed.isProxy) {
      return IAggregatorProxy(address(_feed.feed)).aggregator();
    } else {
      return _feed.feed;
    }
  }

  /// @inheritdoc FeedRegistryInterface
  function getPhaseFeed(
    address,
    address,
    uint16
  ) external pure returns (AggregatorV2V3Interface) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function isFeedEnabled(address) external pure returns (bool) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getPhase(
    address,
    address,
    uint16
  ) external pure returns (Phase memory) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getRoundFeed(
    address,
    address,
    uint80
  ) external pure returns (AggregatorV2V3Interface) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getPhaseRange(
    address,
    address,
    uint16
  ) external pure returns (uint80, uint80) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getPreviousRoundId(
    address,
    address,
    uint80
  ) external pure returns (uint80) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getNextRoundId(
    address,
    address,
    uint80
  ) external pure returns (uint80) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function proposeFeed(
    address,
    address,
    address
  ) external pure {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function confirmFeed(
    address,
    address,
    address
  ) external pure {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getProposedFeed(address, address) external pure returns (AggregatorV2V3Interface) {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function proposedGetRoundData(
    address,
    address,
    uint80
  )
    external
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function proposedLatestRoundData(address, address)
    external
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    _throwNotSupported();
  }

  /// @inheritdoc FeedRegistryInterface
  function getCurrentPhaseId(address, address) external pure returns (uint16) {
    _throwNotSupported();
  }

  function _getKey(address _base, address _quote) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_base, _quote));
  }

  function _throwNotSupported() internal pure {
    revert FunctionNotSupported();
  }
}

interface IAggregatorProxy is AggregatorV2V3Interface {
  function aggregator() external view returns (AggregatorV2V3Interface);
}