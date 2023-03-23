// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IProtocolFeeManager {
  function determineProtocolFeeRate(address collection, uint256 tokenId, address lender) external view returns (uint256);  
}