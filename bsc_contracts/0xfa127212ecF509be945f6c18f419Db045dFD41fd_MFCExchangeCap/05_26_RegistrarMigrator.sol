// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/utils/Context.sol";
import "./Registrar.sol";
import "./access/AdminAgent.sol";

abstract contract RegistrarMigrator is Context, AdminAgent {

  address private _migrationDestination;
  Registrar private _registrar;

  constructor(address registrar_, address[] memory adminAgents_) AdminAgent(adminAgents_) {
    _registrar = Registrar(registrar_);
  }

  modifier onlyUnfinalized() {
    require(_registrar.isFinalized() == false, "Registrar already finalized");
    _;
  }

  function getRegistrarMigrateDestination() public view returns(address) {
    return _migrationDestination;
  }

  function setRegistrarMigrateDestination(address destination) external onlyAdminAgents onlyUnfinalized {
    _migrationDestination = destination;
  }

  function registrarMigrate(uint256 amount) external onlyAdminAgents onlyUnfinalized {
    require(_migrationDestination != address(0), "Migration destination is not set");
    _registrarMigrate(amount);
  }

  // All subclasses must implement this function
  function _registrarMigrate(uint256 amount) internal virtual;
}