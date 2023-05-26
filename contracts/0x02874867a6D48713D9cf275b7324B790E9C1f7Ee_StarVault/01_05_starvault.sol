/*
                                   ./((((.
                               ((&&&&&&&&&&&((
                             (&&&&@@@@&&&&&&&&&(
                           (&&&@@@@@@@@@&&&&&&&&&(
                         #(&&@@@@@@@@@@@&&&&&&&&&&(
                        (#&&@@@@@@@@@@@@&&&&&&&&&&&(        /(((#%%&&%#((,
     /((#%%%%#(((/     *(&&@@@@@@@@@@@&&&&&&&&&&&&&&(  ((%&&&&&@@@@@@&&&&&&((
  (#&&&&@@@@@@@@&&&&#(#(&&&@@@@@@@@@@&&&&&&&&&&&&&&&%&&&&&&@@@@@@@@@@@&&&&&&%(
 (&&&&&@@@@@@@@@@@@@&&&&&&&&@@@@@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&&&&&&(
 (&&&&&@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@&&&&&&&&&&#(
 (&&&&&&&&@@@@@@@@@@@&&&%#(%%(#&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&#(
  (&&&&&&&&&&&&&&&&&&&%#(%%%(%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
    (&&&&&&&&&&&&&&&&%(%&&(%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&((
      (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(
         ((&&&&&&&&&&&&&&&&&%#((%&&&&&&&&&&&&&&#((#%%%&&&%(&&&&&&&&((
           (#&&&&&&&&%(&&&%%%%%%%%&&&&&(&(#&&&&%%%%%%%%&&&(&&&&&&&&&&((
        ((&&&&&&&&&&&&(&&&%%%%%%%%&&&&&&&&&&&&&&%%%%%%&&&((&&&&&&&&&&&&(*
      ,#&&&&&&&&&&&&&&((&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(((((&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&((((((&&&&&&&&&&&&&&&&&&&&&&&&#((%&&&&&&&&&&&&&&&&&(
    (&&&&&&&&&&&&&&&&&&&&&%((&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&%(
    (&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&(&&&&&@@@&&%(&&&&&&&&&&&&&&&&&&&&#.
      (%&&&&&&&&&&&&&&&&&&&&&%(&@@@@@@&&&((&&&@@@&&&((&&&&&&&&&&&&&&&&&&&(.
         *(%&&&&&&&&&&&&&&&&&(((%&&&&&&(*   /((((/   (&&&&&&&&&&&&&&&&%(
                *(((((((/,                             /((#%%%%#((((/
 - XxStarChadxX -
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol"; 

/**
 * @dev Contract implements a Pull Payments pattern for withdrawing funds based
 * on a pre-set vesting schedule.  Similar to OZ escrow contract, with added
 * vesting schedule.  Payees are only settable once, inside construction.
 *
 * Payees should not be contract addresses, these are explicitly disallowed in
 * claim functions for added safety.
 *
 * Vesting begins once {startTimer} is called, {startTimer} is only callable
 * once.  After vestDays + failSafeDays {claimAll} is unlocked.
 */
contract StarVault is Ownable, ReentrancyGuard {
  using Address for address payable;

  event Deposited(address indexed payee, uint weiAmount);
  event Withdrawn(address indexed payee, uint weiAmount);

  mapping(address => uint) public payeeLedger;
  uint public totalReceived = 0;

  /**
   * @dev initialized in {constructor}.
   */
  mapping(address => bool) public vaultPayees;
  uint private _cliffSeconds    = 0;
  uint private _vestSeconds     = 0;
  uint private _failsafeSeconds = 0;
  uint private _numPayees       = 0;

  /**
   * @dev initialized in {startTimer}.
   */
  uint256 public startTimestamp = 0;

  constructor(
    address[] memory payees,
    uint cliffDays,
    uint vestDays,
    uint failsafeDays
  ) {
    for (uint i = 0; i < payees.length; i++) {
      vaultPayees[payees[i]] = true;
    }
    _numPayees = payees.length;
    _cliffSeconds = cliffDays * 1 days;
    _vestSeconds = vestDays * 1 days;
    _failsafeSeconds = failsafeDays * 1 days;
  }

  /**
   * @dev Ensures vesting schedule has begun, and msg.sender is a valid payee.
   */
  modifier claimCompliance(address payee) {
    require(
      vaultPayees[msg.sender],
      "Invalid payee"
    );
    require(
      startTimestamp > 0,
      "Vest timestamp not set"
    );
    require(
      address(this).balance > 0,
      "Contract balance is 0"
    );
    require(
      msg.sender == payee,
      "Claim must be for self"
    );
    require(
      msg.sender == tx.origin,
      "Caller cannot be contract"
    );
    _;
  }

  /**
   * @dev Once callable function to start vesting schedule.
   */
  function startTimer()
    public
    onlyOwner
  {
    require(
      startTimestamp == 0,
      "Timer already started"
    );
    startTimestamp = block.timestamp;
  }

  /**
   * @dev Special failsafe claim in the event any funds go un-claimed.
   */
  function claimAll(address payable payee)
    public
    claimCompliance(payee)
    nonReentrant()
  {
    require(
      block.timestamp > startTimestamp + _vestSeconds + _failsafeSeconds,
      "It is too early to claimAll"
    );

    uint payment = address(this).balance;
    Address.sendValue(payee, payment);
    emit Withdrawn(payee, payment);
  }

  /**
   * @dev Claim pays out all available funds to payee.
   */
  function claim(address payable payee)
    public 
    claimCompliance(payee)
    nonReentrant()
  {
    uint payment = maxClaimable(payee);
    payeeLedger[payee] = payeeLedger[payee] + payment;
    payee.sendValue(payment);
    emit Withdrawn(payee, payment);
  }

  /**
   * @dev Returns max claimable by the provided payee.
   */
  function maxClaimable(address payee)
    public
    view
    virtual
    claimCompliance(payee)
    returns (uint claimableWei)
  {
    require(
      msg.sender == payee,
      "Claim must be for self"
    );
    if (block.timestamp < startTimestamp + _cliffSeconds) {
      return 0;
    }
    uint _maxPayable = totalReceived / _numPayees;
    uint _secondsElapsed = block.timestamp - startTimestamp;
    return _maxPayable * _secondsElapsed / _vestSeconds - payeeLedger[payee];
  }

  receive() external payable {
    totalReceived = totalReceived + msg.value;
    emit Deposited(msg.sender, msg.value);
  }
}