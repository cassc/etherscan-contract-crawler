// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "../interfaces/IInterestCalculator.sol";

abstract contract InterestCalculator is IInterestCalculator {
  function simpleInterest(uint256 interest, uint256 maturity) public view virtual override returns (uint256) {
    return _simpleInterest(interest, maturity);
  }

  function _simpleInterest(uint256 interest, uint256 maturity) internal view virtual returns (uint256) {
    return maturity * interest;
  }
}