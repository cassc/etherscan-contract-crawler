// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../libraries/Intervals.sol';
import './DCAHubConfigHandler.sol';
import '../libraries/FeeMath.sol';

abstract contract DCAHubPositionHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubPositionHandler {
  struct DCA {
    uint32 swapWhereLastUpdated; // Includes both modify and withdraw
    uint32 finalSwap;
    bytes1 swapIntervalMask;
    address from;
    uint24 rateLower; // We are splitting the rate into two different uints, so that we can use only 2 storage slots
    uint96 rateHigher;
    address to;
  }

  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubPositionHandler
  IDCAPermissionManager public permissionManager;
  mapping(uint256 => DCA) internal _userPositions;
  mapping(uint256 => uint256) internal _swappedBeforeModified;
  /// @inheritdoc IDCAHubPositionHandler
  uint256 public totalCreatedPositions;

  constructor(IDCAPermissionManager _permissionManager) {
    _assertNonZeroAddress(address(_permissionManager));
    permissionManager = _permissionManager;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function userPosition(uint256 _positionId) external view returns (UserPosition memory _userPosition) {
    DCA memory _position = _userPositions[_positionId];
    uint32 _performedSwaps = _getPerformedSwaps(_position.from, _position.to, _position.swapIntervalMask);
    uint32 _newestSwapToConsider = _min(_performedSwaps, _position.finalSwap);
    _userPosition.from = IERC20Metadata(_position.from);
    _userPosition.to = IERC20Metadata(_position.to);
    _userPosition.swapsExecuted = _subtractIfPossible(_newestSwapToConsider, _position.swapWhereLastUpdated);
    _userPosition.swapsLeft = _subtractIfPossible(_position.finalSwap, _performedSwaps);
    _userPosition.remaining = _calculateUnswapped(_position, _performedSwaps);
    _userPosition.rate = _mergeRate(_position);
    if (_position.swapIntervalMask > 0) {
      _userPosition.swapInterval = Intervals.maskToInterval(_position.swapIntervalMask);
      _userPosition.swapped = _calculateSwapped(_positionId, _position, _performedSwaps);
    }
  }

  /// @inheritdoc IDCAHubPositionHandler
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions
  ) public nonReentrant whenNotPaused returns (uint256) {
    if (_from == address(0) || _to == address(0) || _owner == address(0)) revert IDCAHub.ZeroAddress();
    if (_from == _to) revert InvalidToken();
    if (_amount == 0) revert ZeroAmount();
    if (_amountOfSwaps == 0) revert ZeroSwaps();
    _assertTokensAreAllowed(_from, _to);
    uint120 _rate = _calculateRate(_amount, _amountOfSwaps);
    uint256 _positionId = ++totalCreatedPositions;
    DCA memory _userPosition = _buildPosition(_from, _to, _amountOfSwaps, Intervals.intervalToMask(_swapInterval), _rate);
    if (allowedSwapIntervals & _userPosition.swapIntervalMask == 0) revert IntervalNotAllowed();
    permissionManager.mint(_positionId, _owner, _permissions);
    _updateActiveIntervalsAndOracle(_from, _to, _userPosition.swapIntervalMask);
    _addToDelta(_from, _to, _userPosition.swapIntervalMask, _userPosition.finalSwap, _rate);
    _userPositions[_positionId] = _userPosition;
    IERC20Metadata(_from).safeTransferFrom(msg.sender, address(this), _amount);
    emit Deposited(
      msg.sender,
      _owner,
      _positionId,
      _from,
      _to,
      _swapInterval,
      _rate,
      _userPosition.swapWhereLastUpdated + 1,
      _userPosition.finalSwap,
      _permissions
    );
    return _positionId;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external returns (uint256 _positionId) {
    _positionId = deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
    if (_miscellaneous.length > 0) {
      emit Miscellaneous(_positionId, _miscellaneous);
    }
  }

  /// @inheritdoc IDCAHubPositionHandler
  function withdrawSwapped(uint256 _positionId, address _recipient) external nonReentrant returns (uint256) {
    _assertNonZeroAddress(_recipient);

    (uint256 _swapped, address _to) = _executeWithdraw(_positionId);
    _transfer(_to, _recipient, _swapped);
    emit Withdrew(msg.sender, _recipient, _positionId, _to, _swapped);
    return _swapped;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function withdrawSwappedMany(PositionSet[] calldata _positions, address _recipient) external nonReentrant returns (uint256[] memory _swapped) {
    _assertNonZeroAddress(_recipient);
    _swapped = new uint256[](_positions.length);
    for (uint256 i = 0; i < _positions.length; ) {
      address _token = _positions[i].token;
      uint256[] memory _positionIds = _positions[i].positionIds;
      for (uint256 j = 0; j < _positionIds.length; ) {
        (uint256 _swappedByPosition, address _to) = _executeWithdraw(_positionIds[j]);
        if (_to != _token) revert PositionDoesNotMatchToken();
        _swapped[i] += _swappedByPosition;
        unchecked {
          j++;
        }
      }
      _transfer(_token, _recipient, _swapped[i]);
      unchecked {
        i++;
      }
    }
    emit WithdrewMany(msg.sender, _recipient, _positions, _swapped);
  }

  /// @inheritdoc IDCAHubPositionHandler
  function terminate(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external nonReentrant returns (uint256 _unswapped, uint256 _swapped) {
    if (_recipientUnswapped == address(0) || _recipientSwapped == address(0)) revert IDCAHub.ZeroAddress();

    DCA memory _userPosition = _userPositions[_positionId];
    _assertPositionExistsAndCallerHasPermission(_positionId, _userPosition, IDCAPermissionManager.Permission.TERMINATE);
    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);

    _swapped = _calculateSwapped(_positionId, _userPosition, _performedSwaps);
    _unswapped = _calculateUnswapped(_userPosition, _performedSwaps);

    _removeFromDelta(_userPosition, _performedSwaps);
    delete _userPositions[_positionId];
    delete _swappedBeforeModified[_positionId];
    permissionManager.burn(_positionId);

    _transfer(_userPosition.to, _recipientSwapped, _swapped);
    _transfer(_userPosition.from, _recipientUnswapped, _unswapped);

    emit Terminated(msg.sender, _recipientUnswapped, _recipientSwapped, _positionId, _unswapped, _swapped);
  }

  /// @inheritdoc IDCAHubPositionHandler
  function increasePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps
  ) external nonReentrant whenNotPaused {
    _modify(_positionId, _amount, _newAmountOfSwaps, address(0));
  }

  /// @inheritdoc IDCAHubPositionHandler
  function reducePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps,
    address _recipient
  ) external nonReentrant {
    _assertNonZeroAddress(_recipient);
    _modify(_positionId, _amount, _newAmountOfSwaps, _recipient);
  }

  function _modify(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps,
    address _recipient
  ) internal {
    DCA memory _userPosition = _userPositions[_positionId];
    bool _increase = _recipient == address(0);
    _assertPositionExistsAndCallerHasPermission(
      _positionId,
      _userPosition,
      _increase ? IDCAPermissionManager.Permission.INCREASE : IDCAPermissionManager.Permission.REDUCE
    );

    if (_increase) {
      _assertTokensAreAllowed(_userPosition.from, _userPosition.to);
      (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_userPosition.from, _userPosition.to);
      activeSwapIntervals[_tokenA][_tokenB] |= _userPosition.swapIntervalMask;
    }

    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);
    uint256 _unswapped = _calculateUnswapped(_userPosition, _performedSwaps);
    uint256 _total = _increase ? _unswapped + _amount : _unswapped - _amount;
    if (_total != 0 && _newAmountOfSwaps == 0) revert ZeroSwaps();
    if (_total == 0 && _newAmountOfSwaps > 0) _newAmountOfSwaps = 0;

    uint120 _newRate = _newAmountOfSwaps == 0 ? 0 : _calculateRate(_total, _newAmountOfSwaps);
    (_userPositions[_positionId].rateLower, _userPositions[_positionId].rateHigher) = _splitRate(_newRate);

    uint32 _finalSwap = _performedSwaps + _newAmountOfSwaps;
    _userPositions[_positionId].swapWhereLastUpdated = _performedSwaps;
    _userPositions[_positionId].finalSwap = _finalSwap;
    _swappedBeforeModified[_positionId] = _calculateSwapped(_positionId, _userPosition, _performedSwaps);

    _removeFromDelta(_userPosition, _performedSwaps);
    _addToDelta(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask, _finalSwap, _newRate);

    if (_amount > 0) {
      if (_increase) {
        IERC20Metadata(_userPosition.from).safeTransferFrom(msg.sender, address(this), _amount);
      } else {
        _transfer(_userPosition.from, _recipient, _amount);
      }
    }

    emit Modified(msg.sender, _positionId, _newRate, _performedSwaps + 1, _finalSwap);
  }

  function _assertTokensAreAllowed(address _tokenA, address _tokenB) internal view {
    if (!allowedTokens[_tokenA] || !allowedTokens[_tokenB]) revert IDCAHubConfigHandler.UnallowedToken();
  }

  function _assertPositionExistsAndCallerHasPermission(
    uint256 _positionId,
    DCA memory _userPosition,
    IDCAPermissionManager.Permission _permission
  ) internal view {
    if (_userPosition.swapIntervalMask == 0) revert InvalidPosition();
    if (!permissionManager.hasPermission(_positionId, msg.sender, _permission)) revert UnauthorizedCaller();
  }

  function _addToDelta(
    address _from,
    address _to,
    bytes1 _swapIntervalMask,
    uint32 _finalSwap,
    uint120 _rate
  ) internal {
    _modifyDelta(_from, _to, _swapIntervalMask, _finalSwap, _rate, true);
  }

  function _removeFromDelta(DCA memory _userPosition, uint32 _performedSwaps) internal {
    if (_userPosition.finalSwap > _performedSwaps) {
      _modifyDelta(
        _userPosition.from,
        _userPosition.to,
        _userPosition.swapIntervalMask,
        _userPosition.finalSwap,
        _mergeRate(_userPosition),
        false
      );
    }
  }

  function _modifyDelta(
    address _from,
    address _to,
    bytes1 _swapIntervalMask,
    uint32 _finalSwap,
    uint120 _rate,
    bool _add
  ) internal {
    if (_from < _to) {
      if (_add) {
        swapData[_from][_to][_swapIntervalMask].nextAmountToSwapAToB += _rate;
        swapAmountDelta[_from][_to][_swapIntervalMask][_finalSwap + 1].swapDeltaAToB += _rate;
      } else {
        swapData[_from][_to][_swapIntervalMask].nextAmountToSwapAToB -= _rate;
        swapAmountDelta[_from][_to][_swapIntervalMask][_finalSwap + 1].swapDeltaAToB -= _rate;
      }
    } else {
      if (_add) {
        swapData[_to][_from][_swapIntervalMask].nextAmountToSwapBToA += _rate;
        swapAmountDelta[_to][_from][_swapIntervalMask][_finalSwap + 1].swapDeltaBToA += _rate;
      } else {
        swapData[_to][_from][_swapIntervalMask].nextAmountToSwapBToA -= _rate;
        swapAmountDelta[_to][_from][_swapIntervalMask][_finalSwap + 1].swapDeltaBToA -= _rate;
      }
    }
  }

  function _updateActiveIntervalsAndOracle(
    address _from,
    address _to,
    bytes1 _mask
  ) internal {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_from, _to);
    bytes1 _activeIntervals = activeSwapIntervals[_tokenA][_tokenB];
    if (_activeIntervals & _mask == 0) {
      if (_activeIntervals == 0) {
        oracle.addSupportForPairIfNeeded(_tokenA, _tokenB, '');
      }
      activeSwapIntervals[_tokenA][_tokenB] = _activeIntervals | _mask;
    }
  }

  /** Returns the amount of tokens swapped in TO */
  function _calculateSwapped(
    uint256 _positionId,
    DCA memory _userPosition,
    uint32 _performedSwaps
  ) internal view returns (uint256 _swapped) {
    uint32 _newestSwapToConsider = _min(_performedSwaps, _userPosition.finalSwap);

    if (_userPosition.swapWhereLastUpdated > _newestSwapToConsider) {
      // If last update happened after the position's final swap, then a withdraw was executed, and we just return 0
      return 0;
    } else if (_userPosition.swapWhereLastUpdated == _newestSwapToConsider) {
      // If the last update matches the positions's final swap, then we can avoid all calculation below
      return _swappedBeforeModified[_positionId];
    }

    uint256 _positionsAccumRatio;
    if (_userPosition.from < _userPosition.to) {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_userPosition.from][_userPosition.to][_userPosition.swapIntervalMask];
      _positionsAccumRatio =
        _accumRatioRef[_newestSwapToConsider].accumRatioAToB -
        _accumRatioRef[_userPosition.swapWhereLastUpdated].accumRatioAToB;
    } else {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_userPosition.to][_userPosition.from][_userPosition.swapIntervalMask];
      _positionsAccumRatio =
        _accumRatioRef[_newestSwapToConsider].accumRatioBToA -
        _accumRatioRef[_userPosition.swapWhereLastUpdated].accumRatioBToA;
    }

    uint256 _magnitude = tokenMagnitude[_userPosition.from];
    uint120 _rate = _mergeRate(_userPosition);
    (bool _ok, uint256 _mult) = SafeMath.tryMul(_positionsAccumRatio, _rate);
    uint256 _swappedInCurrentPosition = (_ok ? _mult / _magnitude : (_positionsAccumRatio / _magnitude) * _rate) / FeeMath.FEE_PRECISION;
    _swapped = _swappedInCurrentPosition + _swappedBeforeModified[_positionId];
  }

  /** Returns how many FROM remains unswapped  */
  function _calculateUnswapped(DCA memory _userPosition, uint32 _performedSwaps) internal pure returns (uint256 _unswapped) {
    _unswapped = uint256(_subtractIfPossible(_userPosition.finalSwap, _performedSwaps)) * _mergeRate(_userPosition);
  }

  function _executeWithdraw(uint256 _positionId) internal returns (uint256 _swapped, address _to) {
    DCA memory _userPosition = _userPositions[_positionId];
    _assertPositionExistsAndCallerHasPermission(_positionId, _userPosition, IDCAPermissionManager.Permission.WITHDRAW);
    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);
    _swapped = _calculateSwapped(_positionId, _userPosition, _performedSwaps);
    _to = _userPosition.to;
    _userPositions[_positionId].swapWhereLastUpdated = _performedSwaps;
    delete _swappedBeforeModified[_positionId];
  }

  function _getPerformedSwaps(
    address _from,
    address _to,
    bytes1 _swapIntervalMask
  ) internal view returns (uint32) {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_from, _to);
    return swapData[_tokenA][_tokenB][_swapIntervalMask].performedSwaps;
  }

  function _buildPosition(
    address _from,
    address _to,
    uint32 _amountOfSwaps,
    bytes1 _mask,
    uint120 _rate
  ) internal view returns (DCA memory _userPosition) {
    uint32 _performedSwaps = _getPerformedSwaps(_from, _to, _mask);
    (uint24 _lower, uint96 _higher) = _splitRate(_rate);
    _userPosition = DCA({
      swapWhereLastUpdated: _performedSwaps,
      finalSwap: _performedSwaps + _amountOfSwaps,
      swapIntervalMask: _mask,
      rateLower: _lower,
      rateHigher: _higher,
      from: _from,
      to: _to
    });
  }

  function _calculateRate(uint256 _amount, uint32 _amountOfSwaps) internal pure returns (uint120) {
    uint256 _rate = _amount / _amountOfSwaps;
    if (_rate > type(uint120).max) revert AmountTooBig();
    return uint120(_rate);
  }

  function _mergeRate(DCA memory _userPosition) internal pure returns (uint120) {
    return (uint120(_userPosition.rateHigher) << 24) + _userPosition.rateLower;
  }

  function _splitRate(uint120 _rate) internal pure returns (uint24 _lower, uint96 _higher) {
    _lower = uint24(_rate);
    _higher = uint96(_rate >> 24);
  }

  function _min(uint32 _a, uint32 _b) internal pure returns (uint32) {
    return _a > _b ? _b : _a;
  }

  function _subtractIfPossible(uint32 _a, uint32 _b) internal pure returns (uint32) {
    return _a > _b ? _a - _b : 0;
  }
}