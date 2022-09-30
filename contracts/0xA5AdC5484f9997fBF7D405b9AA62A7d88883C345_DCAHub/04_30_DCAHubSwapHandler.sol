// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '../interfaces/IDCAHubSwapCallee.sol';
import '../libraries/Intervals.sol';
import '../libraries/FeeMath.sol';
import './DCAHubConfigHandler.sol';

abstract contract DCAHubSwapHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubSwapHandler {
  struct PairMagnitudes {
    uint256 magnitudeA;
    uint256 magnitudeB;
  }

  using SafeERC20 for IERC20Metadata;

  function _registerSwap(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint256 _ratioAToB,
    uint256 _ratioBToA,
    uint32 _timestamp
  ) internal virtual {
    SwapData memory _swapDataMem = swapData[_tokenA][_tokenB][_swapIntervalMask];
    if (_swapDataMem.nextAmountToSwapAToB > 0 || _swapDataMem.nextAmountToSwapBToA > 0) {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_tokenA][_tokenB][_swapIntervalMask];
      mapping(uint32 => SwapDelta) storage _swapAmountDeltaRef = swapAmountDelta[_tokenA][_tokenB][_swapIntervalMask];
      AccumRatio memory _accumRatioMem = _accumRatioRef[_swapDataMem.performedSwaps];
      _accumRatioRef[_swapDataMem.performedSwaps + 1] = AccumRatio({
        accumRatioAToB: _accumRatioMem.accumRatioAToB + _ratioAToB,
        accumRatioBToA: _accumRatioMem.accumRatioBToA + _ratioBToA
      });
      SwapDelta memory _swapDeltaMem = _swapAmountDeltaRef[_swapDataMem.performedSwaps + 2];
      uint224 _nextAmountToSwapAToB = _swapDataMem.nextAmountToSwapAToB - _swapDeltaMem.swapDeltaAToB;
      uint224 _nextAmountToSwapBToA = _swapDataMem.nextAmountToSwapBToA - _swapDeltaMem.swapDeltaBToA;
      swapData[_tokenA][_tokenB][_swapIntervalMask] = SwapData({
        performedSwaps: _swapDataMem.performedSwaps + 1,
        lastSwappedAt: _timestamp,
        nextAmountToSwapAToB: _nextAmountToSwapAToB,
        nextAmountToSwapBToA: _nextAmountToSwapBToA
      });
      delete _swapAmountDeltaRef[_swapDataMem.performedSwaps + 2];
      if (_nextAmountToSwapAToB == 0 && _nextAmountToSwapBToA == 0) {
        _markIntervalAsInactive(_tokenA, _tokenB, _swapIntervalMask);
      }
    } else {
      _markIntervalAsInactive(_tokenA, _tokenB, _swapIntervalMask);
    }
  }

  function _convertTo(
    uint256 _fromTokenMagnitude,
    uint256 _amountFrom,
    uint256 _ratioFromTo,
    uint32 _swapFee
  ) internal pure returns (uint256 _amountTo) {
    uint256 _numerator = FeeMath.subtractFeeFromAmount(_swapFee, _amountFrom * _ratioFromTo);
    _amountTo = _numerator / _fromTokenMagnitude;
    // Note: we need to round up because we can't ask for less than what we actually need
    if (_numerator % _fromTokenMagnitude != 0) _amountTo++;
  }

  function _getTimestamp() internal view virtual returns (uint32 _blockTimestamp) {
    _blockTimestamp = uint32(block.timestamp);
  }

  function _getTotalAmountsToSwap(
    address _tokenA,
    address _tokenB,
    bool _calculatePrivilegedAvailability
  )
    internal
    view
    virtual
    returns (
      uint256 _totalAmountToSwapTokenA,
      uint256 _totalAmountToSwapTokenB,
      bytes1 _intervalsInSwap
    )
  {
    bytes1 _activeIntervals = activeSwapIntervals[_tokenA][_tokenB];
    uint32 _blockTimestamp = _getTimestamp();
    bytes1 _mask = 0x01;
    while (_activeIntervals >= _mask && _mask > 0) {
      if (_activeIntervals & _mask != 0) {
        SwapData memory _swapDataMem = swapData[_tokenA][_tokenB][_mask];
        uint32 _swapInterval = Intervals.maskToInterval(_mask);
        uint32 _nextSwapAvailableAt = ((_swapDataMem.lastSwappedAt / _swapInterval) + 1) * _swapInterval;
        if (!_calculatePrivilegedAvailability) {
          // If the caller does not have privileges, then they will have to wait a little more to execute swaps
          _nextSwapAvailableAt += _swapInterval / 3;
        }
        if (_nextSwapAvailableAt > _blockTimestamp) {
          // Note: this 'break' is both an optimization and a search for more CoW. Since this loop starts with the smaller intervals, it is
          // highly unlikely that if a small interval can't be swapped, a bigger interval can. It could only happen when a position was just
          // created for a new swap interval. At the same time, by adding this check, we force intervals to be swapped together. Therefore
          // increasing the chance of CoW (Coincidence of Wants), and reducing the need for external funds.
          break;
        }
        _intervalsInSwap |= _mask;
        _totalAmountToSwapTokenA += _swapDataMem.nextAmountToSwapAToB;
        _totalAmountToSwapTokenB += _swapDataMem.nextAmountToSwapBToA;
      }
      _mask <<= 1;
    }

    if (_totalAmountToSwapTokenA == 0 && _totalAmountToSwapTokenB == 0) {
      // Note: if there are no tokens to swap, then we don't want to execute any swaps for this pair
      _intervalsInSwap = 0;
    }
  }

  function _calculateRatio(
    address _tokenA,
    address _tokenB,
    ITokenPriceOracle _oracle,
    bytes calldata _oracleData
  )
    internal
    view
    virtual
    returns (
      uint256 _ratioAToB,
      uint256 _ratioBToA,
      PairMagnitudes memory _magnitudes
    )
  {
    _magnitudes.magnitudeA = tokenMagnitude[_tokenA];
    _magnitudes.magnitudeB = tokenMagnitude[_tokenB];
    _ratioBToA = _oracle.quote(_tokenB, _magnitudes.magnitudeB, _tokenA, _oracleData);
    _ratioAToB = (_magnitudes.magnitudeB * _magnitudes.magnitudeA) / _ratioBToA;
  }

  /// @inheritdoc IDCAHubSwapHandler
  function getNextSwapInfo(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairs,
    bool _calculatePrivilegedAvailability,
    bytes calldata _oracleData
  ) public view virtual returns (SwapInfo memory _swapInformation) {
    // Note: we are caching these variables in memory so we can read storage only once (it's cheaper that way)
    uint32 _swapFee = swapFee;
    ITokenPriceOracle _oracle = oracle;

    uint256[] memory _total = new uint256[](_tokens.length);
    uint256[] memory _needed = new uint256[](_tokens.length);
    _swapInformation.pairs = new PairInSwap[](_pairs.length);

    for (uint256 i = 0; i < _pairs.length; ) {
      uint8 indexTokenA = _pairs[i].indexTokenA;
      uint8 indexTokenB = _pairs[i].indexTokenB;
      if (
        indexTokenA >= indexTokenB ||
        (i > 0 &&
          (indexTokenA < _pairs[i - 1].indexTokenA || (indexTokenA == _pairs[i - 1].indexTokenA && indexTokenB <= _pairs[i - 1].indexTokenB)))
      ) {
        // Note: this confusing condition verifies that the pairs are sorted, first by token A, and then by token B
        revert InvalidPairs();
      }

      PairInSwap memory _pairInSwap;
      _pairInSwap.tokenA = _tokens[indexTokenA];
      _pairInSwap.tokenB = _tokens[indexTokenB];

      (_pairInSwap.totalAmountToSwapTokenA, _pairInSwap.totalAmountToSwapTokenB, _pairInSwap.intervalsInSwap) = _getTotalAmountsToSwap(
        _pairInSwap.tokenA,
        _pairInSwap.tokenB,
        _calculatePrivilegedAvailability
      );

      _total[indexTokenA] += _pairInSwap.totalAmountToSwapTokenA;
      _total[indexTokenB] += _pairInSwap.totalAmountToSwapTokenB;

      // Note: it would be better to calculate the magnitudes here instead of inside `_calculateRatio`, but it throws a "stack too deep" error
      PairMagnitudes memory _magnitudes;
      (_pairInSwap.ratioAToB, _pairInSwap.ratioBToA, _magnitudes) = _calculateRatio(
        _pairInSwap.tokenA,
        _pairInSwap.tokenB,
        _oracle,
        _oracleData
      );

      _needed[indexTokenA] += _convertTo(_magnitudes.magnitudeB, _pairInSwap.totalAmountToSwapTokenB, _pairInSwap.ratioBToA, _swapFee);
      _needed[indexTokenB] += _convertTo(_magnitudes.magnitudeA, _pairInSwap.totalAmountToSwapTokenA, _pairInSwap.ratioAToB, _swapFee);

      _swapInformation.pairs[i] = _pairInSwap;
      unchecked {
        i++;
      }
    }

    // Note: we are caching this variable in memory so we can read storage only once (it's cheaper that way)
    uint16 _platformFeeRatio = platformFeeRatio;

    _swapInformation.tokens = new TokenInSwap[](_tokens.length);
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      address _token = _tokens[i];
      if (!allowedTokens[_token]) revert IDCAHubConfigHandler.UnallowedToken();
      if (i > 0 && _token <= _tokens[i - 1]) {
        revert IDCAHub.InvalidTokens();
      }

      TokenInSwap memory _tokenInSwap;
      _tokenInSwap.token = _token;

      uint256 _neededInSwap = _needed[i];
      uint256 _totalBeingSwapped = _total[i];

      if (_neededInSwap > 0 || _totalBeingSwapped > 0) {
        uint256 _totalFee = FeeMath.calculateSubtractedFee(_swapFee, _neededInSwap);

        int256 _platformFee = int256((_totalFee * _platformFeeRatio) / MAX_PLATFORM_FEE_RATIO);

        // If diff is negative, we need tokens. If diff is positive, then we have more than is needed
        int256 _diff = int256(_totalBeingSwapped) - int256(_neededInSwap);

        // Instead of checking if diff is positive or not, we compare against the platform fee. This is to avoid any rounding issues
        if (_diff > _platformFee) {
          _tokenInSwap.reward = uint256(_diff - _platformFee);
        } else if (_diff < _platformFee) {
          _tokenInSwap.toProvide = uint256(_platformFee - _diff);
        }
        _tokenInSwap.platformFee = uint256(_platformFee);
      }
      _swapInformation.tokens[i] = _tokenInSwap;
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAHubSwapHandler
  function swap(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairsToSwap,
    address _rewardRecipient,
    address _callbackHandler,
    uint256[] calldata _borrow,
    bytes calldata _callbackData,
    bytes calldata _oracleData
  ) public nonReentrant whenNotPaused returns (SwapInfo memory _swapInformation) {
    // Note: we are caching this variable in memory so we can read storage only once (it's cheaper that way)
    uint32 _swapFee = swapFee;

    {
      _swapInformation = getNextSwapInfo(_tokens, _pairsToSwap, hasRole(PRIVILEGED_SWAPPER_ROLE, msg.sender), _oracleData);

      uint32 _timestamp = _getTimestamp();
      bool _executedAPair;
      for (uint256 i = 0; i < _swapInformation.pairs.length; ) {
        PairInSwap memory _pairInSwap = _swapInformation.pairs[i];
        bytes1 _intervalsInSwap = _pairInSwap.intervalsInSwap;
        bytes1 _mask = 0x01;
        while (_intervalsInSwap >= _mask && _mask > 0) {
          if (_intervalsInSwap & _mask != 0) {
            _registerSwap(
              _pairInSwap.tokenA,
              _pairInSwap.tokenB,
              _mask,
              _subtractFeeFromAmount(_swapFee, _pairInSwap.ratioAToB),
              _subtractFeeFromAmount(_swapFee, _pairInSwap.ratioBToA),
              _timestamp
            );
            if (!_executedAPair) {
              _executedAPair = true;
            }
          }
          _mask <<= 1;
        }
        unchecked {
          i++;
        }
      }

      if (!_executedAPair) {
        revert NoSwapsToExecute();
      }
    }

    uint256[] memory _beforeBalances = new uint256[](_swapInformation.tokens.length);
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      TokenInSwap memory _tokenInSwap = _swapInformation.tokens[i];

      uint256 _amountToBorrow = _borrow[i];

      // Remember balances before callback
      if (_tokenInSwap.toProvide > 0 || _amountToBorrow > 0) {
        _beforeBalances[i] = _balanceOf(_tokenInSwap.token);
      }

      // Optimistically transfer tokens
      if (_rewardRecipient == _callbackHandler) {
        uint256 _amountToSend = _tokenInSwap.reward + _amountToBorrow;
        _transfer(_tokenInSwap.token, _callbackHandler, _amountToSend);
      } else {
        _transfer(_tokenInSwap.token, _rewardRecipient, _tokenInSwap.reward);
        _transfer(_tokenInSwap.token, _callbackHandler, _amountToBorrow);
      }
      unchecked {
        i++;
      }
    }

    // Make call
    IDCAHubSwapCallee(_callbackHandler).DCAHubSwapCall(msg.sender, _swapInformation.tokens, _borrow, _callbackData);

    // Checks and balance updates
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      TokenInSwap memory _tokenInSwap = _swapInformation.tokens[i];
      uint256 _addToPlatformBalance = _tokenInSwap.platformFee;

      if (_tokenInSwap.toProvide > 0 || _borrow[i] > 0) {
        uint256 _amountToHave = _beforeBalances[i] + _tokenInSwap.toProvide - _tokenInSwap.reward;

        uint256 _currentBalance = _balanceOf(_tokenInSwap.token);

        // Make sure tokens were sent back
        if (_currentBalance < _amountToHave) {
          revert IDCAHub.LiquidityNotReturned();
        }

        // Any extra tokens that might have been received, are set as platform balance
        _addToPlatformBalance += (_currentBalance - _amountToHave);
      }

      // Update platform balance
      if (_addToPlatformBalance > 0) {
        platformBalance[_tokenInSwap.token] += _addToPlatformBalance;
      }
      unchecked {
        i++;
      }
    }

    // Emit event
    emit Swapped(msg.sender, _rewardRecipient, _callbackHandler, _swapInformation, _borrow, _swapFee);
  }

  // Note: This is almost exactly as FeeMath.subtractFeeFromAmount, but without dividing by FEE_PRECISION.
  // We will make that division when calculating how much was swapped. By doing so, we don't lose precision which,
  // in the case of tokens with a small amount of decimals (like USDC), can end up being a lot of funds
  function _subtractFeeFromAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return _amount * (FeeMath.FEE_PRECISION - _fee / 100);
  }

  function _markIntervalAsInactive(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask
  ) internal {
    activeSwapIntervals[_tokenA][_tokenB] &= ~_swapIntervalMask;
  }
}