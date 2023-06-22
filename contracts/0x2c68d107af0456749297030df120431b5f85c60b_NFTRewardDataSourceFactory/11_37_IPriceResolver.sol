// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import './ITokenSupplyDetails.sol';

interface IPriceResolver {
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails token
  ) external returns (uint256);
}