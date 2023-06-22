// SPDX-License-Identifier: MPL

pragma solidity 0.6.6;

/** @title IRelay */

interface IRelay {
  event Extension(bytes32 indexed _first, bytes32 indexed _last);
  event NewTip(bytes32 indexed _from, bytes32 indexed _to, bytes32 indexed _gcd);

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest
  /// @return     The hash of the best marked chain tip
  function getBestKnownDigest() external view returns (bytes32);

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest
  /// @return     The hash of the shared ancestor of the most recent fork
  function getLastReorgCommonAncestor() external view returns (bytes32);

  /// @notice         Finds the height of a header by its digest
  /// @dev            Will fail if the header is unknown
  /// @param _digest  The header digest to search for
  /// @return         The height of the header, or error if unknown
  function findHeight(bytes32 _digest) external view returns (uint256);

  /// @notice             Checks if a digest is an ancestor of the current one
  /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
  /// @param _ancestor    The prospective ancestor
  /// @param _descendant  The descendant to check
  /// @param _limit       The maximum number of blocks to check
  /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
  function isAncestor(
    bytes32 _ancestor,
    bytes32 _descendant,
    uint256 _limit
  ) external view returns (bool);

  function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

  function addHeadersWithRetarget(
    bytes calldata _oldPeriodStartHeader,
    bytes calldata _oldPeriodEndHeader,
    bytes calldata _headers
  ) external returns (bool);

  function markNewHeaviest(
    bytes32 _ancestor,
    bytes calldata _currentBest,
    bytes calldata _newBest,
    uint256 _limit
  ) external returns (bool);
}