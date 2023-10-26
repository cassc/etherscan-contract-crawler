// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20UtilityToken is ERC20, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
  }

  function mint(address to, uint256 amount) external {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20UtilityToken: must have minter role to mint");
    _mint(to, amount);
  }

  function burn(address account, uint256 amount) external {
    require(hasRole(BURNER_ROLE, _msgSender()), "ERC20UtilityToken: must have burner role to burn");
    _burn(account, amount);
  }
}