// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILibStarVault {
  /**
   * The swap fee is over the maximum allowed
   */
  error FeeTooHigh(uint256 maxFeeBps);

  event Fee(
    address indexed partner,
    address indexed token,
    uint256 partnerFee,
    uint256 protocolFee
  );
}