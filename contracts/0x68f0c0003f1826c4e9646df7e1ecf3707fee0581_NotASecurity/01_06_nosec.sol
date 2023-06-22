// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NotASecurity is ERC20, ERC20Burnable {
  constructor(address initialAccount, uint256 initialSupply) ERC20("Not A Security", "NOSEC") {
    require(initialAccount != address(0), "NotASecurity: mint to the zero address");
    require(initialSupply > 0, "NotASecurity: initial supply must be greater than 0");
    _mint(initialAccount, initialSupply * 10 ** decimals());
  }
}