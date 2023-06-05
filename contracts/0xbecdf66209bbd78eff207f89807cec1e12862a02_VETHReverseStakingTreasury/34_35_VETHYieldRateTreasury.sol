// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminGovernanceAgent } from "../access/AdminGovernanceAgent.sol";
import { Governable } from "../governance/Governable.sol";
import { VETHReverseStakingTreasury } from "../VETHReverseStakingTreasury.sol";
import { RegistrarClient } from "../RegistrarClient.sol";

contract VETHYieldRateTreasury is AdminGovernanceAgent, Governable, RegistrarClient {

  address private _migration;
  VETHReverseStakingTreasury private _vethReverseStakingTreasury;

  event ReverseStakingTransfer(address recipient, uint256 amount);

  constructor(
    address registrarAddress,
    address[] memory adminGovAgents
  ) AdminGovernanceAgent(adminGovAgents)
    RegistrarClient(registrarAddress) {
  }

  modifier onlyReverseStakingTreasury() {
    require(address(_vethReverseStakingTreasury) == _msgSender(), "Unauthorized");
    _;
  }

  function getYieldRateTreasuryValue() external view returns (uint256) {
    return address(this).balance + _vethReverseStakingTreasury.getTotalClaimedYield();
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    _transfer(_migration, amount, "");
  }

  function reverseStakingTransfer(address recipient, uint256 amount) external onlyReverseStakingTreasury {
    _transfer(recipient, amount, "");
    emit ReverseStakingTransfer(recipient, amount);
  }

  function reverseStakingRoute(address recipient, uint256 amount, bytes memory selector) external onlyReverseStakingTreasury {
    _transfer(recipient, amount, selector);
    emit ReverseStakingTransfer(recipient, amount);
  }

  function updateAddresses() external override onlyRegistrar {
    _vethReverseStakingTreasury = VETHReverseStakingTreasury(payable(_registrar.getVETHReverseStakingTreasury()));
    _updateGovernable(_registrar);
  }

  function _transfer(address recipient, uint256 amount, bytes memory payload) private {
    require(address(this).balance >= amount, "Insufficient balance");
    (bool sent,) = recipient.call{value: amount}(payload);
    require(sent, "Failed to send Ether");
  }

  receive() external payable {}
}