// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

abstract contract Timelock is ReentrancyGuard {
  IERC20 public staderToken;
  ///@notice time in secs for withholding transfer transaction
  ///@dev min 1 day of time for withdrawing balance.
  uint256 constant public  fixedLockedPeriod = 0;
  ///@dev variable time in secs for withdrawing balance. Currently sent at 2 days.
  uint256 public lockedPeriod = fixedLockedPeriod + 0;

  ///@notice transaction data structure
  struct Withdraw {
    uint256 timestamp;
    uint256 lockedAmount;
    address payable to;
  }
  ///@notice list of all the transactions active and completed
  Withdraw[] public withdrawQueue;

  ///@notice event fired when the transfer transaction is queued
  event Queued(uint256 indexed index, uint256 amount);
  ///@notice event fired when the tokens are transferred successfully to the specified account
  event Transferred(uint256 indexed index, uint256 amount, address payable to);
  ///@notice event is fired when the admin owner cancels the transaction
  event WithdrawCancelled(uint256 indexed index, uint256 amount);
  ///@notice event is fired when the owner is changed
  event OwnerChanged(address to, address from);
  ///@notice event is fired when the locked time period is updated
  event LockPeriodChanged(uint256 to, uint256 from);

  /// @notice address of multisig admin account for SD Token mover to new contract
  address timelockOwner;

  /// @notice Check for zero address before setting the address
  /// @dev Modifier
  /// @param _address the address to check
  modifier checkZeroAddress(address _address) {
    require(_address != address(0), 'Address cannot be zero');
    _;
  }
  /// @notice Check for checking the owner for transaction
  /// @dev Modifier
  modifier checkOwner() {
    if (msg.sender != timelockOwner) revert('You are not the owner');
    _;
  }

  /// @notice Constructor
  /// @param _timelockOwner the address of owner/admin for carrying out the transaction
  constructor(IERC20 _staderToken, address _timelockOwner) checkZeroAddress(_timelockOwner) {
    staderToken = _staderToken;
    timelockOwner = _timelockOwner;
  }

  /********************************
   * Admin Tx functions   *
   ********************************/
  /// @notice queue the transaction for withdrawal with a specified amount
  /// @param to address of the account to transfer the tokens to
  /// @param amount the index of the transaction queue which is to be withdrawn
  function queuePartialFunds(address payable to, uint256 amount)
    external
    checkZeroAddress(to)
    checkOwner
  {
    if (amount > staderToken.balanceOf(address(this))) revert('Amount exceeds balance');
    uint256 index = withdrawQueue.length;
    Withdraw memory withdrawData = Withdraw({
      timestamp: block.timestamp,
      lockedAmount: amount,
      to: to
    });
    withdrawQueue.push(withdrawData);
    emit Queued(index, amount);
  }

  /// @notice queue the transaction for withdrawal of the entire contract balance
  /// @param to address of the account to transfer the tokens to
  function queueAllFunds(address payable to) external checkZeroAddress(to) checkOwner {
    uint256 index = withdrawQueue.length;
    Withdraw memory userTransaction = Withdraw({
      timestamp: block.timestamp,
      lockedAmount: staderToken.balanceOf(address(this)),
      to: to
    });
    withdrawQueue.push(userTransaction);
    emit Queued(index, staderToken.balanceOf(address(this)));
  }

  /// @notice Withdraws the funds from the contract post cooldown period
  /// @param index the index of the transaction queue which is to be withdrawn
  function withdraw(uint256 index) external nonReentrant {
    if (staderToken.balanceOf(address(this)) == 0) revert('No funds to withdraw');
    if (index >= withdrawQueue.length) revert('Invalid index');
    Withdraw storage withdrawData = withdrawQueue[index];
    if (withdrawData.timestamp + lockedPeriod >= block.timestamp)
      revert('Unlock period not expired');
    if (withdrawData.lockedAmount == 0) revert('Amount not available');
    address payable to = withdrawData.to;
    uint256 amount = withdrawData.lockedAmount;
    delete withdrawQueue[index];
    emit Transferred(index, amount, to);
    require(staderToken.transfer(to, amount), 'Withdraw failed');
  }

  /// @notice Cancels the withdraw transaction in the queue
  /// @param index index value of the transaction to be cancelled
  function cancelWithdraw(uint256 index) external checkOwner {
    if (index >= withdrawQueue.length) revert('Invalid index');
    uint256 amount = withdrawQueue[index].lockedAmount;
    emit WithdrawCancelled(index, amount);
    delete withdrawQueue[index];
  }

  /**********************
   * Setter functions   *
   **********************/
  /// @notice Set new multisig owner for the transfer of SD Token to new version
  /// @param _timelockOwner the new owner of SD Token withdrawal to new version
  function setTimeLockOwner(address _timelockOwner)
    external
    checkZeroAddress(_timelockOwner)
    checkOwner
  {
    emit OwnerChanged(_timelockOwner, timelockOwner);
    timelockOwner = _timelockOwner;
  }

  /// @notice Set the locking period for the transfer of tokens
  /// @param _lockedPeriod time in secs for withholding transfer transaction
  function setLockedPeriod(uint256 _lockedPeriod) external checkOwner {
    _lockedPeriod = fixedLockedPeriod + _lockedPeriod;
    require(_lockedPeriod != lockedPeriod, 'Lock period unchanged');
    emit LockPeriodChanged(_lockedPeriod, lockedPeriod);
    lockedPeriod = _lockedPeriod;
  }
}