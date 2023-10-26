// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOwnableV2 } from "../Control/IOwnableV2.sol";

interface IGovernable is IOwnableV2 {
  event GovernorshipTransferred(address indexed oldGovernor, address indexed newGovernor);

  function governor() external view returns (address);
  function transferGovernorship(address newGovernor) external;
}