// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { ERC20, ERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract BaseToken is ERC20Permit, Ownable {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_) {}

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyOwner {
    _burn(from, amount);
  }
}