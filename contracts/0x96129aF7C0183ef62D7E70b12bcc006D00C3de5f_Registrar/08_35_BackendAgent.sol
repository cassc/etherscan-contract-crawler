// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";

contract BackendAgent is Context {

  mapping(address => bool) private _backendAdminAgents;
  mapping(address => bool) private _backendAgents;

  event SetBackendAgent(address agent);
  event RevokeBackendAgent(address agent);

  modifier onlyBackendAdminAgents() {
    require(_backendAdminAgents[_msgSender()], "Unauthorized");
    _;
  }

  modifier onlyBackendAgents() {
    require(_backendAgents[_msgSender()], "Unauthorized");
    _;
  }

  function _setBackendAgents(address[] memory backendAgents) internal {
      for (uint i = 0; i < backendAgents.length; i++) {
      _backendAgents[backendAgents[i]] = true;
    }
  }

  function _setBackendAdminAgents(address[] memory backendAdminAgents) internal {
    for (uint i = 0; i < backendAdminAgents.length; i++) {
      _backendAdminAgents[backendAdminAgents[i]] = true;
    }
  }

  function setBackendAgent(address _agent) external onlyBackendAdminAgents {
    _backendAgents[_agent] = true;
    emit SetBackendAgent(_agent);
  }

  function revokeBackendAgent(address _agent) external onlyBackendAdminAgents {
    _backendAgents[_agent] = false;
    emit RevokeBackendAgent(_agent);
  }
}