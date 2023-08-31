// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StandardERC20 is ERC20, Pausable, Ownable {
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) ERC20(name_, symbol_) {
    _decimals = decimals_;
    _mint(msg.sender, totalSupply_ * 10 ** decimals());
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}