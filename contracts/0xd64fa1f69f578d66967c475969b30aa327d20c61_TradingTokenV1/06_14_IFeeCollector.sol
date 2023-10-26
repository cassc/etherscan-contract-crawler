// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOwnableV2 } from "../Control/IOwnableV2.sol";

interface IFeeCollector is IOwnableV2 {
  function feesContract() external view returns (address);
  function setFeesContract(address contractAddress_) external;
  function feePercentDenominator() external view returns (uint256);
  function setFeePercentDenominator(uint256 value) external;
  function getFeePercentInRange(
    string memory minFeeType,
    string memory maxFeeType,
    uint256 input,
    uint256 percent
  ) external view returns (uint256 output);
}