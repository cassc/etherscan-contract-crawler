// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library Calculator {
  uint256 private constant E5 = 1e5;
  using SafeERC20 for IERC20;

  function duration(
    uint256 _rentalStartTimestamp,
    uint256 _rentalDurationByDay,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    uint256 _maxRentalDuration,
    uint256 _minRentalDuration
  ) public view returns (uint256 _rentalStartTime, uint256 _rentalExpireTime) {
    _rentalStartTime = block.timestamp;

    // Check to see if the number of days or date conditions set by lend are met.
    require(
      _rentalExpireTime < _lockExpireTime || _lockExpireTime - _lockStartTime == 0,
      'RentalExpireAfterLockExpire'
    );
    require(
      _minRentalDuration <= _rentalDurationByDay && _rentalDurationByDay <= _maxRentalDuration,
      'RentalDurationIsOutOfRange'
    );

    // For Reservation
    if (_rentalStartTimestamp != 0) {
      require(_rentalStartTimestamp > _rentalStartTime, 'rentalStartShouldBeNow/Later');
      _rentalStartTime = _rentalStartTimestamp;
    }
    // Arguments are passed in days, so they are converted to seconds
    _rentalExpireTime = _rentalStartTime + (_rentalDurationByDay * 1 days);
  }

  function fee(
    uint256 _dailyRentalPrice,
    uint64 _lockStartTime,
    uint64 _lockExpireTime,
    address _lender,
    address _paymentToken,
    uint256 _adminFeeRatio,
    uint256 _rentalDurationByDay,
    uint256 _amount,
    uint256 _collectionOwnerFeeRatio
  )
    public
    returns (
      uint256 _lenderBenefit,
      uint256 _collectionOwnerFee,
      uint256 _adminFee
    )
  {
    /*
     * If the amount is greater than 1 in ERC721,
     * the renter will only pay more than necessary,
     * so we do not revert here to save on gas costs.
     */
    uint256 _rentalFee = _dailyRentalPrice * _amount * _rentalDurationByDay; // dailyRentalPrice per Unit * Rental Amount * rentalDuration(days)
    _adminFee = (_rentalFee * _adminFeeRatio) / E5;
    _collectionOwnerFee = (_rentalFee * _collectionOwnerFeeRatio) / E5;
    uint256 _lenderFee = _rentalFee - _adminFee - _collectionOwnerFee;

    require(_rentalFee == _adminFee + _collectionOwnerFee + _lenderFee, 'invalidCalc');
    // If the lockDuration is Zero, fee is sent to lender this time
    if (_lockStartTime < _lockExpireTime) _lenderBenefit = _lenderFee;

    // Native token
    if (_paymentToken == address(0)) {
      require(msg.value >= _rentalFee, 'InsufficientFunds');
      if (msg.value > _rentalFee) payable(msg.sender).transfer(msg.value - _rentalFee);
      // If No Locked
      if (_lockStartTime == _lockExpireTime) payable(_lender).transfer(_lenderFee); //lenderに送るのは、_lenderFeeのみ。 adminFeeとCollectionOwnerFeeはmsg.valueで送られている
      // If Loked, protocol received fee by msg.value. so no method required.
    }
    //ERC20 token
    else {
      // If No Locked
      if (_lockStartTime == _lockExpireTime) {
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(_lender), _lenderFee); //lenderに送るのは、_lenderFeeのみ
        IERC20(_paymentToken).safeTransferFrom(
          msg.sender,
          address(this),
          _collectionOwnerFee + _adminFee
        );
      }
      // If Locked, pay all fee to protocol
      else {
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _rentalFee);
      }
    }
  }
}