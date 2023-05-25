// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../MintingCeremony.sol";

contract MintingCeremonyHarness is MintingCeremony {
  constructor(
    address governance_,
    address monetaryPolicy_,
    address basket_,
    address float_,
    address[] memory allowanceTokens_,
    uint256 ceremonyStart
  )
    MintingCeremony(
      governance_,
      monetaryPolicy_,
      basket_,
      float_,
      allowanceTokens_,
      ceremonyStart
    )
  {}

  function __monetaryPolicy() external view returns (address) {
    return address(monetaryPolicy);
  }

  function __basket() external view returns (address) {
    return address(basket);
  }

  function __float() external view returns (address) {
    return address(float);
  }

  function __allowanceTokens(uint256 idx) external view returns (address) {
    return address(allowanceTokens[idx]);
  }
}