pragma solidity 0.6.6;

import {TypedMemView} from "../summa-tx/TypedMemView.sol";
import {ViewBTC} from "../summa-tx/ViewBTC.sol";
import {ViewSPV} from "../summa-tx/ViewSPV.sol";
import {IRelay} from "../summa-tx/IRelay.sol";

/** @title MockRelay */
/** half-hearted implementation for testing */

contract MockRelay is IRelay {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using ViewSPV for bytes29;

  bytes32 bestKnownDigest;
  bytes32 lastReorgCommonAncestor;
  uint256 public currentEpochDiff;
  mapping(bytes32 => uint256) public heights;

  constructor(
    bytes32 _bestKnownDigest,
    uint256 _bestKnownHeight,
    bytes32 _lastReorgCommonAncestor,
    uint256 _lastReorgHeight
  ) public {
    bestKnownDigest = _bestKnownDigest;
    heights[_bestKnownDigest] = _bestKnownHeight;
    lastReorgCommonAncestor = _lastReorgCommonAncestor;
    heights[_lastReorgCommonAncestor] = _lastReorgHeight;
  }

  function addHeader(bytes32 _digest, uint256 _height) external {
    heights[_digest] = _height;
  }

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest
  /// @return     The hash of the best marked chain tip
  function getBestKnownDigest() public override view returns (bytes32) {
    return bestKnownDigest;
  }

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest
  /// @return     The hash of the shared ancestor of the most recent fork
  function getLastReorgCommonAncestor() public override view returns (bytes32) {
    return lastReorgCommonAncestor;
  }

  /// @notice     Getter for bestKnownDigest
  /// @dev        This updated only by calling markNewHeaviest

  function setBestKnownDigest(bytes32 _bestKnownDigest) external {
    require(heights[_bestKnownDigest] > 0, "not found");
    bestKnownDigest = _bestKnownDigest;
  }

  /// @notice     Getter for relayGenesis
  /// @dev        This is updated only by calling markNewHeaviest

  function setLastReorgCommonAncestor(bytes32 _lrca) external {
    require(heights[_lrca] > 0, "not found");
    require(heights[_lrca] <= heights[bestKnownDigest], "ahead of tip");
    lastReorgCommonAncestor = _lrca;
  }

  /// @notice         Finds the height of a header by its digest
  /// @dev            Will fail if the header is unknown
  /// @param _digest  The header digest to search for
  /// @return         The height of the header, or error if unknown
  function findHeight(bytes32 _digest) external override view returns (uint256) {
    return heights[_digest];
  }

  /// @notice             Checks if a digest is an ancestor of the current one
  /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
  /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
  function isAncestor(
    bytes32,
    bytes32,
    uint256
  ) external override view returns (bool) {
    return true;
  }

  function addHeaders(bytes calldata _anchor, bytes calldata _headers)
    external
    override
    returns (bool)
  {
    require(_headers.length % 80 == 0, "Header array length must be divisible by 80");
    bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
    bytes29 _anchorView = _anchor.ref(0).tryAsHeader();

    require(_headersView.notNull(), "Header array length must be divisible by 80");
    require(_anchorView.notNull(), "Anchor must be 80 bytes");
    return _addHeaders(_anchorView, _headersView);
  }

  /// @notice             Adds headers to storage after validating
  /// @dev                We check integrity and consistency of the header chain
  /// @param  _anchor     The header immediately preceeding the new chain
  /// @param  _headers    A tightly-packed list of new 80-byte Bitcoin headers to record
  /// @return             True if successfully written, error otherwise
  function _addHeaders(bytes29 _anchor, bytes29 _headers) internal returns (bool) {
    uint256 _height;
    bytes32 _currentDigest;
    bytes32 _previousDigest = _anchor.hash256();

    uint256 _anchorHeight = heights[_previousDigest]; /* NB: errors if unknown */
    require(_anchorHeight > 0, "anchor height can not be 0");

    /*
    NB:
    1. check that the header has sufficient work
    2. check that headers are in a coherent chain (no retargets, hash links good)
    3. Store the block connection
    4. Store the height
    */
    for (uint256 i = 0; i < _headers.len() / 80; i += 1) {
      bytes29 _header = _headers.indexHeaderArray(i);
      _height = _anchorHeight + (i + 1);
      _currentDigest = _header.hash256();
      heights[_currentDigest] = _height;
      require(_header.checkParent(_previousDigest), "Headers do not form a consistent chain");
      _previousDigest = _currentDigest;
    }

    emit Extension(_anchor.hash256(), _currentDigest);
    return true;
  }

  function addHeadersWithRetarget(
    bytes calldata,
    bytes calldata _oldPeriodEndHeader,
    bytes calldata _headers
  ) external override returns (bool) {
    bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
    bytes29 _anchorView = _oldPeriodEndHeader.ref(0).tryAsHeader();

    require(_headersView.notNull(), "Header array length must be divisible by 80");
    require(_anchorView.notNull(), "Anchor must be 80 bytes");
    return _addHeaders(_anchorView, _headersView);
  }

  function markNewHeaviest(
    bytes32 _ancestor,
    bytes calldata _currentBest,
    bytes calldata _newBest,
    uint256 _limit
  ) external override returns (bool) {
    bytes29 _new = _newBest.ref(0).tryAsHeader();
    bytes29 _current = _currentBest.ref(0).tryAsHeader();
    require(_new.notNull() && _current.notNull(), "Bad args. Check header and array byte lengths.");
    return _markNewHeaviest(_ancestor, _current, _new, _limit);
  }

  /// @notice                   Marks the new best-known chain tip
  /// @param  _ancestor         The digest of the most recent common ancestor
  /// @param  _current          The 80-byte header referenced by bestKnownDigest
  /// @param  _new              The 80-byte header to mark as the new best
  /// @param  _limit            Limit the amount of traversal of the chain
  /// @return                   True if successfully updates bestKnownDigest, error otherwise
  function _markNewHeaviest(
    bytes32 _ancestor,
    bytes29 _current, // Header
    bytes29 _new, // Header
    uint256 _limit
  ) internal returns (bool) {
    require(_limit <= 2016, "Requested limit is greater than 1 difficulty period");
    bytes32 _newBestDigest = _new.hash256();
    bytes32 _currentBestDigest = _current.hash256();
    require(_currentBestDigest == bestKnownDigest, "Passed in best is not best known");
    require(heights[_newBestDigest] > 0, "New best is unknown");

    bestKnownDigest = _newBestDigest;
    lastReorgCommonAncestor = _ancestor;

    uint256 _newDiff = _new.diff();
    if (_newDiff != currentEpochDiff) {
      currentEpochDiff = _newDiff;
    }

    emit NewTip(_currentBestDigest, _newBestDigest, _ancestor);
    return true;
  }
}