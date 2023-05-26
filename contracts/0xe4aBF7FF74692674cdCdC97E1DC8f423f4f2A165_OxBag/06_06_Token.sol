// twitter 
// https://twitter.com/0xbagcoin
// telegram
// https://t.me/bag0xportal	
// website
// https://0xbag.shop	


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract OxBag is Ownable, ERC20 { 
  mapping(address => bool) public blacklists;

  constructor(uint256 _totalSupply) ERC20("0xBag", "0xBag") {
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