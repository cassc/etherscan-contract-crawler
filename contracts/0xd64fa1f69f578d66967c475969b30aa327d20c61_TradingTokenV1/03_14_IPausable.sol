// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOwnableV2 } from "./IOwnableV2.sol";

interface IPausable is IOwnableV2 {
  function paused() external view returns (bool);
  function setPaused(bool value) external;
}