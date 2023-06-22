// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

/**
 * @author Balancer Labs
 * @title Put all the constants in one place
 */

contract BConst {
  // State variables (must be constant in a library)

  // B "ONE" - all math is in the "realm" of 10 ** 18;
  // where numeric 1 = 10 ** 18
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_WEIGHT = BONE;
  uint256 internal constant MAX_WEIGHT = BONE * 50;
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint256 internal constant MIN_BALANCE = BONE / 10**6;
  uint256 internal constant MAX_BALANCE = BONE * 10**12;
  uint256 internal constant MIN_POOL_SUPPLY = BONE * 100;
  uint256 internal constant MAX_POOL_SUPPLY = BONE * 10**9;
  uint256 internal constant MIN_FEE = BONE / 10**6;
  uint256 internal constant MAX_FEE = BONE / 10;
  // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
  uint256 internal constant EXIT_FEE = 0;
  uint256 internal constant MAX_IN_RATIO = BONE / 2;
  uint256 internal constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
  // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
  uint256 internal constant MIN_ASSET_LIMIT = 2;
  uint256 internal constant MAX_ASSET_LIMIT = 8;
  uint256 internal constant MAX_UINT = uint256(-1);

  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}