// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeTestToken is Ownable, ERC20 {
  constructor(uint256 _totalSupply) ERC20("PepeTest", "PEPETest") {
    _mint(msg.sender, _totalSupply);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}