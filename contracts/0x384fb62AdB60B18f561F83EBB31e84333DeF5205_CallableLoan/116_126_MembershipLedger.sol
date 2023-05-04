// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IMembershipLedger} from "../../../interfaces/IMembershipLedger.sol";

import {Context} from "../../../cake/Context.sol";
import {Base} from "../../../cake/Base.sol";
import "../../../cake/Routing.sol" as Routing;

import {Epochs} from "./Epochs.sol";

using Routing.Context for Context;

contract MembershipLedger is IMembershipLedger, Base, Initializable {
  error InvalidAlphaGTE1();
  error InvalidAlphaUndefined();
  error InvalidAlphaNumerator();
  error InvalidAlphaDenominator();

  struct Fraction {
    uint128 numerator;
    uint128 denominator;
  }

  /// rewards allocated to and not yet claimed by an address
  mapping(address => uint256) private allocatedRewards;

  /// Alpha param for the cobb douglas function
  Fraction public alpha;

  /// @notice Construct the contract
  constructor(Context _context) Base(_context) {}

  function initialize() public initializer {
    alpha = Fraction(1, 2);
  }

  /// @inheritdoc IMembershipLedger
  function resetRewards(address addr) external onlyOperator(Routing.Keys.MembershipDirector) {
    allocatedRewards[addr] = 0;
  }

  /// @inheritdoc IMembershipLedger
  function allocateRewardsTo(
    address addr,
    uint256 amount
  ) external onlyOperator(Routing.Keys.MembershipDirector) returns (uint256 rewards) {
    allocatedRewards[addr] += amount;

    return allocatedRewards[addr];
  }

  /// @inheritdoc IMembershipLedger
  function getPendingRewardsFor(address addr) external view returns (uint256 rewards) {
    return allocatedRewards[addr];
  }

  /// @notice Set the alpha parameter used in the membership score formula. Alpha is defined as a fraction in
  ///  the range (0, 1) and constrained to (0,20) / (0,20], so a minimum of 1/20 and a maximum of 19/20.
  /// @param numerator the numerator of the fraction, must be in the range (0, 20)
  /// @param denominator the denominator of the fraction, must be in the range (0, 20] and greater than the numerator
  function setAlpha(uint128 numerator, uint128 denominator) external onlyAdmin {
    // Numerator in range (0, 20)
    if (numerator >= 20 || numerator == 0) revert InvalidAlphaNumerator();

    // Denominator in range (0, 20]
    if (denominator > 20 || denominator == 0) revert InvalidAlphaDenominator();

    // Total fraction less than 1
    if (numerator >= denominator) revert InvalidAlphaGTE1();

    alpha = Fraction(numerator, denominator);
  }
}