// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract vLit is ERC20, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  constructor() ERC20("vLit", "VLIT") {
    // Grant the contract deployer the default admin role:
    // It will be able to grant and revoke any roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    // Grant minter role, must be reassigned to staking pool after deployment
    _setupRole(MINTER_ROLE, msg.sender);

    // Grant burner role, must be reassigned to vLitBurner after deployment
    _setupRole(BURNER_ROLE, msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "Caller is not a minter");
    _;
  }

  modifier onlyBurner(address from) {
    require(isBurner(msg.sender) || msg.sender == from, "Caller is not a burner");
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account) || hasRole(MINTER_ROLE, account);
  }

  function isBurner(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account) || hasRole(BURNER_ROLE, account);
  }

  function mint(address to, uint256 amount) public onlyMinter {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyBurner(from) {
    _burn(from, amount);
  }
}