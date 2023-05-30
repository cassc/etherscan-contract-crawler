// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title Represents ownership over a fee of some percentage.
  @author Tim Clancy
*/
contract FeeOwner is Ownable {
  using SafeMath for uint256;

  /// A version number for this FeeOwner contract's interface.
  uint256 public version = 1;

  /// The percent fee due to this contract's owner, represented as 1/1000th of a percent. That is, a 1% fee maps to 1000.
  uint256 public fee;

  /// The maximum configurable percent fee due to this contract's owner, represented as 1/1000th of a percent.
  uint256 public maximumFee;

  /// An event for tracking modification of the fee.
  event FeeChanged(uint256 oldFee, uint256 newFee);

  /**
    Construct a new FeeOwner by providing specifying a fee.

    @param _fee The percent fee to apply, represented as 1/1000th of a percent.
    @param _maximumFee The maximum possible fee that the owner can set.
  */
  constructor(uint256 _fee, uint256 _maximumFee) public {
    require(_fee <= _maximumFee, "The fee cannot be set above its maximum.");
    fee = _fee;
    maximumFee = _maximumFee;
  }

  /**
    Allows the owner of this fee to modify what they take, within bounds.

    @param newFee The new fee to begin using.
  */
  function changeFee(uint256 newFee) external onlyOwner {
    require(newFee <= maximumFee, "The fee cannot be set above its original maximum.");
    emit FeeChanged(fee, newFee);
    fee = newFee;
  }
}