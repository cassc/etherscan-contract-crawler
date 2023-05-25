// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../lib/openzeppelin/contracts/4.5.0/access/AccessControl.sol";
import "../lib/openzeppelin/contracts/4.5.0/token/ERC20/ERC20.sol";
import "../lib/openzeppelin/contracts/4.5.0/token/ERC20/extensions/ERC20Burnable.sol";
import "../lib/openzeppelin/contracts/4.5.0/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Stronger is ERC20, ERC20Burnable, ERC20Permit, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() ERC20("Stronger", "STRNGR") ERC20Permit("Stronger") {
    _mint(msg.sender, 10000000 * 10 ** decimals());
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }
}