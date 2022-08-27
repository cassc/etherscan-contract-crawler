/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import {FixedPointMathLib} from "./FixedPointMathLib.sol";

/* Introduction of "Perwei" struct:

  To ensure accounting precision, financial and scientific applications make
  use of a so called "parts-per" notation and so it turns out that: "One part
  per hundred is generally represented by the percent sign (%)" [1].

  But with Solidity and Ethereum having a precision of up to 18 decimal points
  but no native fixed point math arithmetic functions, we have to be careful
  when e.g. calculating fractions of a value.

  E.g. in cases where we want to calculate the tax of a property that's worth
  only 1000 Wei (= 0.000000000000001 Ether) using naive percentages leads to
  inaccuracies when dealing with Solidity's division operator. Hence, libraries
  like solmate and others have come up with "parts-per"-ready implementations
  where values are scaled up. The `Perwei` struct here represents a structure
  of numerator and denominator that allows precise calculations of up to 18
  decimals in the results, e.g. Perwei(1, 1e18).

  References:
  - 1:
https://en.wikipedia.org/w/index.php?title=Parts-per_notation&oldid=1068959843

*/
struct Perwei {
  uint256 numerator;
  uint256 denominator;
}

library Harberger {
  function getNextPrice(
    Perwei memory perwei,
    uint256 blockDiff,
    uint256 collateral
  ) internal pure returns (uint256, uint256) {
    uint256 taxes = taxPerBlock(perwei, blockDiff, collateral);
    int256 diff = int256(collateral) - int256(taxes);

    if (diff <= 0) {
      return (0, collateral);
    } else {
      return (uint256(diff), taxes);
    }
  }

  function taxPerBlock(
    Perwei memory perwei,
    uint256 blockDiff,
    uint256 collateral
  ) internal pure returns (uint256) {
    return FixedPointMathLib.fdiv(
      collateral * blockDiff * perwei.numerator,
      perwei.denominator * FixedPointMathLib.WAD,
      FixedPointMathLib.WAD
    );
  }
}