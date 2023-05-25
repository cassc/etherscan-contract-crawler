// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./IPool.sol";

interface IMigrator {
  function receiveDeposits(address _staker, IPool.User memory _user) external;
}