// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";

contract AdminGovernanceAgent is Context {

  mapping(address => bool) private _adminGovAgents;

  constructor(address[] memory adminGovAgents_) {
    for (uint i = 0; i < adminGovAgents_.length; i++) {
      require(adminGovAgents_[i] != address(0), "Invalid address");
      _adminGovAgents[adminGovAgents_[i]] = true;
    }
  }

  modifier onlyAdminGovAgents() {
    require(_adminGovAgents[_msgSender()], "Unauthorized");
    _;
  }
}