// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShroomsToken is Ownable, ERC20 {
  mapping(address => bool) public blacklists;

  constructor(uint256 _totalSupply) ERC20("SHROOMS", "SHROOMS") {
    _mint(msg.sender, _totalSupply);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256
  ) override internal virtual {
      require(!blacklists[to] && !blacklists[from], "Blacklisted");
  }

  function blacklist(address _address, bool _blacklisted) external onlyOwner {
    blacklists[_address] = _blacklisted;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}