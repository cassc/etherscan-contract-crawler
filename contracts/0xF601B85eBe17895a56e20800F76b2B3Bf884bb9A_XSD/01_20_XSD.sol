// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./02_20_ERC20.sol";
import "./03_20_ERC20Burnable.sol";
import "./04_20_draft-ERC20Permit.sol";
import "./05_20_ERC20Votes.sol";

import "./06_20_AccessControl.sol";

contract XSD is ERC20, ERC20Burnable, ERC20Permit, AccessControl {
  bytes32 public constant SUPPLY_ROLE = keccak256('SUPPLY_ROLE');

  constructor() ERC20('XSD', 'xSD') ERC20Permit('XSD') {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(SUPPLY_ROLE, msg.sender);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    super._afterTokenTransfer(from, to, amount);
  }

  function mint(address to, uint256 amount) external onlyRole(SUPPLY_ROLE) {
    _mint(to, amount);
  }

  function setSupplyRole(address _supplyRole) external onlyRole(SUPPLY_ROLE) {
    _grantRole(SUPPLY_ROLE, _supplyRole);
    approve(_supplyRole, type(uint256).max);
  }
}