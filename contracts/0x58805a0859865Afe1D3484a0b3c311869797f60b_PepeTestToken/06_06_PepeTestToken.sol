// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeTestToken is Ownable, ERC20 {
  mapping(address => bool) public blacklists;

  constructor(uint256 _totalSupply) ERC20("BOTE", "Bob Test Token") {
    _mint(msg.sender, _totalSupply);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 /* amount */
  ) override internal virtual {
      require(!blacklists[to] && !blacklists[from], "Blacklisted");

      // if (uniswapV2Pair == address(0)) {
      //     require(from == owner() || to == owner(), "trading is not started");
      //     return;
      // }

      // if (limited && from == uniswapV2Pair) {
      //     require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
      // }
  }

  function blacklist(address _address, bool _blacklisted) external onlyOwner {
    blacklists[_address] = _blacklisted;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}