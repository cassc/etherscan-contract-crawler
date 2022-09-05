// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Reservoir Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Compound
 */
contract Reservoir {
  /// @notice The block number when the Reservoir started (immutable)
  uint256 public dripStart;

  /// @notice Tokens per block that to drip to target (immutable)
  uint256 public dripRate;

  /// @notice Reference to token to drip (immutable)
  EIP20Interface public token;

  /// @notice Target to receive dripped tokens (immutable)
  address public target;

  /// @notice Amount that has already been dripped
  uint256 public dripped;

  /**
   * @notice Constructs a Reservoir
   * @param dripRate_ Numer of tokens per block to drip
   * @param token_ The token to drip
   * @param target_ The recipient of dripped tokens
   */
  constructor(
    uint256 dripRate_,
    EIP20Interface token_,
    address target_
  ) public {
    dripStart = block.number;
    dripRate = dripRate_;
    token = token_;
    target = target_;
    dripped = 0;
  }

  /**
   * @notice Drips the maximum amount of tokens to match the drip rate since inception
   * @dev Note: this will only drip up to the amount of tokens available.
   * @return The amount of tokens dripped in this call
   */
  function drip() public returns (uint256) {
    // First, read storage into memory
    EIP20Interface token_ = token;
    uint256 reservoirBalance_ = token_.balanceOf(address(this)); // TODO: Verify this is a static call
    uint256 dripRate_ = dripRate;
    uint256 dripStart_ = dripStart;
    uint256 dripped_ = dripped;
    address target_ = target;
    uint256 blockNumber_ = block.number;

    // Next, calculate intermediate values
    uint256 dripTotal_ = mul(dripRate_, blockNumber_ - dripStart_, "dripTotal overflow");
    uint256 deltaDrip_ = sub(dripTotal_, dripped_, "deltaDrip underflow");
    uint256 toDrip_ = min(reservoirBalance_, deltaDrip_);
    uint256 drippedNext_ = add(dripped_, toDrip_, "tautological");

    // Finally, write new `dripped` value and transfer tokens to target
    dripped = drippedNext_;
    token_.transfer(target_, toDrip_);

    return toDrip_;
  }

  /* Internal helper functions for safe math */

  function add(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c;
    unchecked {
      c = a + b;
    }
    require(c >= a, errorMessage);
    return c;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c;
    unchecked {
      c = a * b;
    }
    require(c / a == b, errorMessage);
    return c;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }
}

import "./EIP20Interface.sol";