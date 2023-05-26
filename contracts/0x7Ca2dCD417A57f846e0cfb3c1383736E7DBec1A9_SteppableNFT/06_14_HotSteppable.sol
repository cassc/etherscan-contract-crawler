// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Contract module which allows children to implement a surge
 * pricing mechanism that can be configured by an authorized account.
 *
 */
abstract contract HotSteppable is Context {
  // Use of constants as this will be part of the agreed offering
  // that I don't think you can change midway, so why not save the gas:
  uint256 constant DEVIATION_PERCENTAGE = 20; // 20%
  uint256 constant BUCKET_LENGTH_IN_SECONDS = 900; // 15 minutes
  uint256 constant FORTY_EIGHT_HOURS_IN_SECONDS = 172800; // 48 hours

  bool private _surgeModeActive;
  uint256 public _basePrice;
  uint256 public _maxPrice;
  uint256 public _currentPrice;
  uint256 public _previousPrice;
  uint256 public _priceBufferInSeconds;
  uint256 public _currentTimeBucket;
  uint256 public _priceIncrement;
  uint256 public _zeroPointReference;
  uint256 public _endTimeStamp;
  uint256 public _countCurrentBucket;
  uint256 public _countPreviousBucket;
  uint256 public _pausedAt;
  uint256 public _totalSecondsPaused;
  uint256 public _maxBatchMint;

  event _BasePriceSet(uint256 basePrice);

  event _MaxPriceSet(uint256 maxPrice);

  event _StartPreviousPriceSet(uint256 previousPrice);

  event _StartPriceSet(uint256 currentPrice);

  event _ZeroPointReferenceSet(uint256 startTimeStamp);

  event _EndTimeStampSet(uint256 endTimeStamp);

  event _PriceBufferSet(uint256 priceBufferInSeconds);

  event _PriceIncrementSet(uint256 priceIncrement);

  event _MaxBatchMintSet(uint256 maxBatchMint);

  event _StartPreviousBucketSet(uint256 previousBucketStartValue);

  event _steppableMinting(
    address recipient,
    uint256 quantity,
    uint256 mintCost,
    uint256 mintTimeStamp
  );

  event _developerAllocationMinting(
    address recipient,
    uint256 quantity,
    uint256 remainingAllocation,
    uint256 mintTimeStamp
  );

  event _SurgeOff(address account);

  event _SurgeOn(address account);

  constructor() {}

  modifier whenSurge() {
    require(_surgeModeActive, "Surge: Surge mode is OFF");
    _;
  }

  modifier whenNotSurge() {
    require(!_surgeModeActive, "Surge: Surge mode is ON");
    _;
  }

  function _handleZeroPointReference() internal virtual {
    _pausedAt = block.timestamp;
  }

  function _updateZeroPoint() internal virtual {
    if (_pausedAt != 0) {
      _totalSecondsPaused = (_totalSecondsPaused +
        (block.timestamp - _pausedAt));
      _setZeroPointReference(_zeroPointReference + _totalSecondsPaused);
    } else {
      if (_zeroPointReference == 0) {
        _setZeroPointReference(block.timestamp);
        _setEndTimeStamp(block.timestamp + FORTY_EIGHT_HOURS_IN_SECONDS);
      }
    }
  }

  function _setBasePrice(uint256 _basePriceToSet)
    internal
    virtual
    returns (bool)
  {
    _basePrice = _basePriceToSet;
    emit _BasePriceSet(_basePriceToSet);
    return true;
  }

  function _setMaxPrice(uint256 _maxPriceToSet)
    internal
    virtual
    returns (bool)
  {
    _maxPrice = _maxPriceToSet;
    emit _MaxPriceSet(_maxPriceToSet);
    return true;
  }

  function _setZeroPointReference(uint256 _zeroPointReferenceToSet)
    internal
    virtual
    returns (bool)
  {
    _zeroPointReference = _zeroPointReferenceToSet;
    emit _ZeroPointReferenceSet(_zeroPointReference);
    return true;
  }

  function _setEndTimeStamp(uint256 _endTimeStampToSet)
    internal
    virtual
    returns (bool)
  {
    _endTimeStamp = _endTimeStampToSet;
    emit _EndTimeStampSet(_endTimeStamp);
    return true;
  }

  function _setStartPrice(uint256 _startPriceToSet)
    internal
    virtual
    returns (bool)
  {
    _currentPrice = _startPriceToSet;
    emit _StartPriceSet(_currentPrice);
    return true;
  }

  function _setStartPreviousPrice(uint256 _startPreviousPriceToSet)
    internal
    virtual
    returns (bool)
  {
    _previousPrice = _startPreviousPriceToSet;
    emit _StartPreviousPriceSet(_previousPrice);
    return true;
  }

  function _setPriceBufferInSeconds(uint256 _bufferInSecondsToSet)
    internal
    virtual
    returns (bool)
  {
    _priceBufferInSeconds = _bufferInSecondsToSet;
    emit _PriceBufferSet(_priceBufferInSeconds);
    return true;
  }

  function _setPriceIncrement(uint256 _priceIncrementToSet)
    internal
    virtual
    returns (bool)
  {
    _priceIncrement = _priceIncrementToSet;
    emit _PriceIncrementSet(_priceIncrementToSet);
    return true;
  }

  function _setMaxBatchMint(uint256 _maxBatchMintToSet)
    internal
    virtual
    returns (bool)
  {
    _maxBatchMint = _maxBatchMintToSet;
    emit _MaxBatchMintSet(_maxBatchMint);
    return true;
  }

  function _setStartPreviousBucketCount(uint256 _startPreviousBucketCount)
    internal
    virtual
    returns (bool)
  {
    _countPreviousBucket = _startPreviousBucketCount;
    emit _StartPreviousBucketSet(_startPreviousBucketCount);
    return true;
  }

  function _setSurgeModeOff() internal virtual whenSurge {
    _surgeModeActive = false;
    emit _SurgeOff(_msgSender());
  }

  function _setSurgeModeOn() internal virtual whenNotSurge {
    _surgeModeActive = true;
    emit _SurgeOn(_msgSender());
  }

  function surgeModeActive() external view virtual returns (bool) {
    return _surgeModeActive;
  }

  function _updateBuckets(
    uint256 _bucketNumberToAdd,
    uint256 _newPrice,
    uint256 _oldPrice,
    uint256 _quantity
  ) internal virtual {
    if (_surgeModeActive) {
      // This is called on mint when we know that the bucket must advance
      _currentTimeBucket = _currentTimeBucket + _bucketNumberToAdd;
      // More than one bucket to add indicates the most recent previous bucket must have been a zeromint:
      if (_bucketNumberToAdd > 1) {
        _countPreviousBucket = 0;
      } else {
        _countPreviousBucket = _countCurrentBucket;
      }
      _countCurrentBucket = _quantity;
      _previousPrice = _oldPrice;
      _currentPrice = _newPrice;
    }
  }

  function _recordMinting(uint256 _quantity) internal virtual {
    if (_surgeModeActive) {
      // This is called on mint when within a bucket. Just increment the current bucket counter
      _countCurrentBucket += _quantity;
    }
  }

  function _withinBuffer(uint256 _bucketNumberToAdd)
    internal
    view
    virtual
    returns (bool)
  {
    // Check if we are within the buffer period:
    uint256 bucketStart = _zeroPointReference +
      ((_currentTimeBucket + _bucketNumberToAdd) * BUCKET_LENGTH_IN_SECONDS);
    return ((block.timestamp - bucketStart) <= _priceBufferInSeconds);
  }

  function _bullish() internal view virtual returns (bool) {
    return ((_countCurrentBucket * 100) >=
      (_countPreviousBucket * (100 + DEVIATION_PERCENTAGE)));
  }

  function _bearish() internal view virtual returns (bool) {
    return ((_countPreviousBucket * 100) >=
      (_countCurrentBucket * (100 + DEVIATION_PERCENTAGE)));
  }

  function _inCurrentBucket() internal view virtual returns (bool) {
    return (((block.timestamp - _zeroPointReference) /
      BUCKET_LENGTH_IN_SECONDS) == _currentTimeBucket);
  }

  function _getPrice()
    internal
    view
    virtual
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 calculatedPrice = _currentPrice;
    uint256 calculatedPreviousPrice = _previousPrice;
    uint256 numberOfElapsedBucketsSinceCurrent = 0;

    // Only do surge pricing if this is active, otherwise we are in openmint mode:
    if (_surgeModeActive) {
      if (_inCurrentBucket()) {
        // Nothing extra to do - we have set the calculatedPrice to the _currentPrice
        // and the calculatedPreviousPrice to the _previousPrice above.
      } else {
        // First, we have moved buckets, so change the previous price to what was the current price:
        calculatedPreviousPrice = _currentPrice;

        // We need to work our current price based on:
        // (a) How many time buckets have passed
        // (b) How each one (if more than one has passed) relates to the one before
        // Now, any mint in that time period that occured AFTER that bucket has closed will have closed that
        // bucket and opened a new one. So we KNOW that any mints in countCurrentBucket apply to the bucket
        // that is bucketStart + BUCKET_LENGTH_IN_SECONDS and no others occured in that bucket.
        // So first we record what effect that had on the price:
        // See if we have gone down by the deviation percentage. Be aware that in instances of both the
        // current and the previous bucket having a count of 0 BOTH bullish and bearish will resolve to true,
        // as thanks to maths 0 * anything will still = 0. But we put bearish first, as if we had no sales
        // in the previous bucket and no sales in this bucket that is bearish.

        if (_bearish()) {
          if (calculatedPrice > _priceIncrement) {
            calculatedPrice = calculatedPrice - _priceIncrement;
          }
        } else {
          if (_bullish()) {
            // The count for that current bucket was higher than the deviation percentage above the previous
            // bucket therefore we increase the price by _priceIncrement:
            calculatedPrice = calculatedPrice + _priceIncrement;
          } else {
            // _crabish: Current count is within both the increase and decrease boundary. Price stays the same
            // Nothing extra to do - we have set the calculatedPrice to the _currentPrice
            // and the calculatedPreviousPrice to the _previousPrice above.
          }
        }
        // We now need to check how many buckets have passed, as there could be multiple that have not
        // had a mint event to close the previous one and open a new one. These also need to be considered
        // in the pricing:
        numberOfElapsedBucketsSinceCurrent =
          ((block.timestamp - _zeroPointReference) / BUCKET_LENGTH_IN_SECONDS) -
          _currentTimeBucket;
        // A result of 1 means we have ticked over into just one time bucket beyond the current. Anything more than 1 is a zeromint
        // bucket that must be represented.
        // Every time period with 0 mints by definition should be considered to be a decrease event, as
        // either it is infinitely less (as a %) than whatever the previous value was, or is a continuation of
        // no one being willing to mint at this price:

        // Change to increments not %s:
        if (numberOfElapsedBucketsSinceCurrent > 1) {
          if (numberOfElapsedBucketsSinceCurrent > 2) {
            uint256 previousReduction = (_priceIncrement *
              (numberOfElapsedBucketsSinceCurrent - 2));
            if (calculatedPreviousPrice > previousReduction) {
              calculatedPreviousPrice = (calculatedPrice - previousReduction);
            } else {
              calculatedPreviousPrice = 0;
            }
          } else {
            calculatedPreviousPrice = calculatedPrice;
          }

          uint256 currentReduction = (_priceIncrement *
            (numberOfElapsedBucketsSinceCurrent - 1));
          if (calculatedPrice > currentReduction) {
            calculatedPrice = (calculatedPrice - currentReduction);
          } else {
            calculatedPrice = 0;
          }
        }
      }

      // Implement Max price checks:
      if (calculatedPrice < _basePrice) {
        calculatedPrice = _basePrice;
      }

      if (calculatedPrice > _maxPrice) {
        calculatedPrice = _maxPrice;
      }

      if (calculatedPreviousPrice < _basePrice) {
        calculatedPreviousPrice = _basePrice;
      }

      if (calculatedPreviousPrice > _maxPrice) {
        calculatedPreviousPrice = _maxPrice;
      }
    } else {
      // Openmint mode - current and previous price are set from the base price:
      calculatedPreviousPrice = _basePrice;
      calculatedPrice = _basePrice;
      numberOfElapsedBucketsSinceCurrent = 0;
    }

    return (
      calculatedPrice,
      numberOfElapsedBucketsSinceCurrent,
      calculatedPreviousPrice
    );
  }
}