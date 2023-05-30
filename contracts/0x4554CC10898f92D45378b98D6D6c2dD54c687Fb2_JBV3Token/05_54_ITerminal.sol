// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ITerminalDirectory.sol';

interface ITerminal {
  function terminalDirectory() external view returns (ITerminalDirectory);

  function migrationIsAllowed(ITerminal _terminal) external view returns (bool);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    string calldata _memo,
    bool _preferUnstakedTickets
  ) external payable returns (uint256 fundingCycleId);

  function addToBalance(uint256 _projectId) external payable;

  function allowMigration(ITerminal _contract) external;

  function migrate(uint256 _projectId, ITerminal _to) external;
}