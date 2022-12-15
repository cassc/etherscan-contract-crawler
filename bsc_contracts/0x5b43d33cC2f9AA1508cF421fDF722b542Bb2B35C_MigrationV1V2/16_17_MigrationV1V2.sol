// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../tokens/rejuvenate/RejuvenateFinance.sol";

contract MigrationV1V2 is Ownable, Pausable, ReentrancyGuard {
  IERC20 private v1;
  RejuvenateFinance private v2;

  constructor(address _v1, address _v2) {
    v1 = IERC20(_v1);
    v2 = RejuvenateFinance(_v2);
  }

  function migrate(uint256 _amount) external whenNotPaused nonReentrant {
    v1.transferFrom(msg.sender, address(0), _amount);
    v2.mint(msg.sender, _amount);
  }

  function inCaseTokensGetStuck(address _token) external onlyOwner {
    require(_token != address(v2) && _token != address(v1), "!token");
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, amount);
  }
}