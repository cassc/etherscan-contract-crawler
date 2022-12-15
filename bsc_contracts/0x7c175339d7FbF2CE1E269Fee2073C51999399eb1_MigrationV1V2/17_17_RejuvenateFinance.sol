// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RejuvenateFinance is ERC20, ERC20Burnable, Pausable, AccessControl {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant MAX_SUPPLY = 10000000000000000000000000;

  constructor() ERC20("Rejuvenate Finance", "RJVF") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(
    address to,
    uint256 amount
  ) public whenNotPaused onlyRole(MINTER_ROLE) {
    require(totalSupply() + amount <= MAX_SUPPLY, "!max_supply");
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  function inCaseTokensGetStuck(
    address token_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(token_ != address(this), "!token");
    uint256 amount = IERC20(token_).balanceOf(address(this));
    IERC20(token_).transfer(msg.sender, amount);
  }
}