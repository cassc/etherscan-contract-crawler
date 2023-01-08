// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/// @title Minimum amount payment splitter
contract PaymentMinimum is PaymentSplitter {
  address private immutable AGENCY;
  uint256 private _minimumPayment;
  
  constructor(
    uint256 _min,
    address _agency,
    address[] memory _shareholders,
    uint256[] memory _shares
  ) PaymentSplitter(_shareholders, _shares) {
    _minimumPayment = _min;
    AGENCY = _agency;
  }

  /// @notice Only agency can call
  modifier onlyAgency(address _account) {
    require(AGENCY == _account, "PaymentMinimum: Account is not agency.");
    _;
  }

  /// @notice Only after minimum payment is met
  modifier onlyAfterMinimum() {
    require(_minimumPayment == 0, "PaymentMinimum: Minimum payment is not met.");
    _;
  }

  /// @notice Function for agency to release minimum funds
  /// @param _account Agency account
  function agencyRelease(address payable _account) public virtual onlyAgency(_account) {
    uint256 _balance = address(this).balance;
    uint256 _remaining = _minimumPayment;
    require(_remaining > 0, "PaymentMinimum: Minimum payment is already met.");
    require (_balance > 0, "PaymentMinimum: Contract has no funds.");

    uint256 _payment = _balance >= _remaining ? _remaining : _balance;
    _minimumPayment -= _payment;
    Address.sendValue(_account, _payment);
  }

  /// @dev Require minimum to be met before allowing a call
  function release(address payable account) public virtual override onlyAfterMinimum() {
    super.release(account);
  }

  /// @dev require minimum to be met before allowing a call
  function release(IERC20 token, address account) public virtual override onlyAfterMinimum() {
    super.release(token, account);
  }
}