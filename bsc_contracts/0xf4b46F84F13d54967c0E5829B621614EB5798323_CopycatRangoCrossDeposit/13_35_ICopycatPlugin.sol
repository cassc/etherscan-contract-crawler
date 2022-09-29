// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "../CopycatLeader.sol";

interface ICopycatPlugin {
  function pluginType() external view returns(string memory);

  function balance() external view returns(uint256);

  function contractSignature() external view returns(bytes32);

  function factory() external view returns(address);
  function leaderContract() external view returns(CopycatLeader);
  function leaderAddress() external view returns(address);
}