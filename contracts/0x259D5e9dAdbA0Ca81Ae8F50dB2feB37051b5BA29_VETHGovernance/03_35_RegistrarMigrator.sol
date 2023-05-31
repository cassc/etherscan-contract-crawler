// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Registrar } from "./Registrar.sol";
import { AdminAgent } from "./access/AdminAgent.sol";
import { VYToken } from "./token/VYToken.sol";

abstract contract RegistrarMigrator is AdminAgent {

  Registrar private _registrar;
  uint256 private _contractIndex;

  constructor(
    address registrarAddress,
    uint256 contractIndex,
    address[] memory adminAgents
  ) AdminAgent(adminAgents) {
    require(registrarAddress != address(0), "Invalid address");

    _registrar = Registrar(registrarAddress);
    _contractIndex = contractIndex;
  }

  modifier onlyUnfinalized() {
    require(_registrar.isFinalized() == false, "Registrar already finalized");
    _;
  }

  function registrarMigrateTokens() external onlyAdminAgents onlyUnfinalized {
    VYToken vyToken = VYToken(_registrar.getVYToken());
    vyToken.registrarMigrateTokens(_registrar.getEcosystemId(), _contractIndex);
  }
}