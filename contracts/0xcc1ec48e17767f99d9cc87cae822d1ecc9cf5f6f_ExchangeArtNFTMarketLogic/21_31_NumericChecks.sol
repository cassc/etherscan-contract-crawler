// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../mixins/shared/Errors.sol";

library NumericChecks {
  function mustBeGreaterThan(uint256 value, uint256 compareTo) internal pure {
    if (compareTo >= value) {
      revert ValueNotMet(value, compareTo);
    }
  }

  function mustBeEqualTo(uint256 value, uint256 compareTo) internal pure {
    if (compareTo != value) {
      revert ValuesNotEqauls(value, compareTo);
    }
  }

  function mustBeValidAmount(uint256 value) internal pure {
    if (value < 10_000_000_000_000) {
      revert ValueMustBeAboveMinimumAmount(value);
    }

    if (value % 10_000_000_000_000 != 0) {
      revert ValueMustBeMultipleOfMinimumAmount(value);
    }
  }
}