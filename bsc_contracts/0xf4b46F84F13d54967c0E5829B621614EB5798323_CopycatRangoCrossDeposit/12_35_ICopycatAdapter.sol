// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "./ICopycatPlugin.sol";

interface ICopycatAdapter is ICopycatPlugin {
  function sync() external;
  function withdrawTo(address to, uint256 amount) external;
}