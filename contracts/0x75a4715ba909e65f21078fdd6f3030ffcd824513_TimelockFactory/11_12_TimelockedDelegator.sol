// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ITimelockedDelegator, IDelegatable} from "./interface/ITimelockedDelegator.sol";
import {LinearTokenTimelock} from "./LinearTokenTimelock.sol";

/// @title a proxy delegate contract for token
/// @author Fei Protocol, modified by Connext. Fei reference:
///         https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/timelocks/LinearTimelockedDelegator.sol
/// @dev https://eips.ethereum.org/EIPS/eip-4758 -> inclusion seems likely within
///      the next 4 years, so selfdestruct was removed from withdraw()
/// @dev
contract Delegatee is Ownable {
  IDelegatable public token;

  /// @notice Delegatee constructor
  /// @param _delegatee the address to delegate token to
  /// @param _token the delegatable token address
  constructor(address _delegatee, address _token) {
    token = IDelegatable(_token);
    token.delegate(_delegatee);
  }

  /// @notice send token back to timelock
  function withdraw() public onlyOwner {
    IDelegatable _token = token;
    uint256 balance = _token.balanceOf(address(this));
    _token.transfer(owner(), balance);
  }
}

/// @title a timelock for token allowing for sub-delegation
/// @author Fei Protocol
/// @notice allows the timelocked token to be delegated by the beneficiary while locked
contract TimelockedDelegator is ITimelockedDelegator, LinearTokenTimelock {
  /// @notice associated delegate proxy contract for a delegatee
  mapping(address => address) public override delegateContract;

  /// @notice associated delegated amount of token for a delegatee
  /// @dev Using as source of truth to prevent accounting errors by transferring to Delegate contracts
  mapping(address => uint256) public override delegateAmount;

  /// @notice the token contract
  IDelegatable public override token;

  /// @notice the total delegated amount of token
  uint256 public override totalDelegated;

  /// @notice Delegatee constructor
  /// @param _token the token address
  /// @param _beneficiary default delegate, admin, and timelock beneficiary
  /// @param _clawbackAdmin who can withdraw unclaimed tokens if timelock halted. use address(0) if there
  ///        shouldn't be clawbacks for this contract
  /// @param _cliffDuration cliff of unlock, in seconds. Use 0 for no cliff.
  /// @param _startTime start time of unlock period, in seconds. Use 0 for now.
  /// @param _duration duration of the token timelock window
  constructor(
    address _token,
    address _beneficiary,
    address _clawbackAdmin,
    uint256 _cliffDuration,
    uint256 _startTime,
    uint256 _duration
  ) LinearTokenTimelock(_beneficiary, _duration, _token, _cliffDuration, _clawbackAdmin, _startTime) {
    token = IDelegatable(_token);
    token.delegate(_beneficiary);
  }

  /// @notice delegate locked token to a delegatee
  /// @param delegatee the target address to delegate to
  /// @param amount the amount of token to delegate. Will increment existing delegated token
  function delegate(address delegatee, uint256 amount) public override onlyBeneficiary {
    require(amount <= _tokenBalance(), "TimelockedDelegator: Not enough balance");

    // withdraw and include an existing delegation
    if (delegateContract[delegatee] != address(0)) {
      amount = amount + undelegate(delegatee);
    }

    IDelegatable _token = token;
    address _delegateContract = address(new Delegatee(delegatee, address(_token)));
    delegateContract[delegatee] = _delegateContract;

    delegateAmount[delegatee] = amount;
    totalDelegated = totalDelegated + amount;

    _token.transfer(_delegateContract, amount);

    emit Delegate(delegatee, amount);
  }

  /// @notice return delegated token to the timelock
  /// @param delegatee the target address to undelegate from
  /// @return the amount of token returned
  function undelegate(address delegatee) public override onlyBeneficiary returns (uint256) {
    address _delegateContract = delegateContract[delegatee];
    require(_delegateContract != address(0), "TimelockedDelegator: Delegate contract nonexistent");

    Delegatee(_delegateContract).withdraw();

    uint256 amount = delegateAmount[delegatee];
    totalDelegated = totalDelegated - amount;

    delegateContract[delegatee] = address(0);
    delegateAmount[delegatee] = 0;

    emit Undelegate(delegatee, amount);

    return amount;
  }

  /// @notice calculate total token held plus delegated
  /// @dev used by LinearTokenTimelock to determine the released amount
  function totalToken() public view override returns (uint256) {
    return _tokenBalance() + totalDelegated;
  }

  /// @notice accept beneficiary role over timelocked token. Delegates all held (non-subdelegated) token to beneficiary
  function acceptBeneficiary() public override {
    _setBeneficiary(msg.sender);
    token.delegate(msg.sender);
  }

  function _tokenBalance() internal view returns (uint256) {
    return token.balanceOf(address(this));
  }
}