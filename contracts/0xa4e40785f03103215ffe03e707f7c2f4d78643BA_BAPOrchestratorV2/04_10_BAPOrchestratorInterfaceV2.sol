// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface BAPOrchestratorInterfaceV2 {
  function mintingRefunded(uint256) external returns (bool); 
  function claimedMeth(uint256) external view returns (uint256); 
}