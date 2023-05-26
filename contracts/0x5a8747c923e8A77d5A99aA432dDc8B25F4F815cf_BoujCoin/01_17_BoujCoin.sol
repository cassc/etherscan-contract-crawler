// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  BOUJ

  Meet Bouj, the fanciest feline on the block! Bouj's got a taste for the finer 
  things in life, and this kitty ain't playin' around. When it comes to spreading 
  the wealth, Bouj and their squad of fabulous furballs are all about making sure 
  you're living the good life, too.

  Bouj uses original AI art that combines technology and artistic expression to 
  create unique and original pieces of digital art. With Bouj, we're taking meme 
  culture to a whole new level, creating something truly unique and original that 
  stands out from the crowd. Join us on this journey and discover the magic of Bouj 
  for yourself.  
  
  https://bouj.io
  https://twitter.com/bouj_coin

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

//contract BoujCoin is Ownable, ERC20, ERC20Burnable {
contract BoujCoin is Ownable, ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
  bool public wlonly;
  bool public limited;
  address public uniswapV2Pair;
  uint256 public maxHoldingAmount;
  mapping(address => uint) public wlmap;

  uint constant BASE_DIVISOR = 10_000;

  //constructor(address[] memory _wls) ERC20("BOUJ", "BOUJ") {
  constructor(address[] memory _wls) ERC20("BOUJ", "BOUJ") ERC20Permit("BOUJ") {
    uint supply = 69_420_000_000 * 10 ** decimals();
    _mint(_msgSender(), supply);
    _setWl(_wls, 400, supply);
  }

  function setWl(address[] memory _wls, uint _max) external onlyOwner {
    _setWl(_wls, _max, totalSupply());
  }

  function _setWl(address[] memory _wls, uint _max, uint supply) internal {
    uint max = (supply * _max) / BASE_DIVISOR;
    for (uint i = 0; i < _wls.length; i++) {
      wlmap[_wls[i]] = max;
    }
  }

  function removeLimits() external onlyOwner {
    wlonly = false;
    limited = false;
    maxHoldingAmount = 0;
  }

  function allowAll() external onlyOwner {
    wlonly = false;
  }

  function setRule(address _uniswapV2Pair, uint256 _maxPct) external onlyOwner {
    wlonly = true;
    limited = true;
    uniswapV2Pair = _uniswapV2Pair;
    maxHoldingAmount = (totalSupply() * _maxPct) / BASE_DIVISOR;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    if (uniswapV2Pair == address(0)) {
      require(from == owner() || to == owner(), "!trading");
      return;
    }

    if (limited && from == uniswapV2Pair) {
      uint _max = wlmap[to];
      require(_max > 0 || !wlonly, "wlonly");
      _max = _max > 0 ? _max : maxHoldingAmount;
      require(super.balanceOf(to) + amount <= _max, ">max");
    }
  }

  /*
      For ERC20Votes
  */

  function _afterTokenTransfer(address from, address to, uint256 amount)
      internal
      override(ERC20, ERC20Votes)
  {
      super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount)
      internal
      override(ERC20, ERC20Votes)
  {
      super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
      internal
      override(ERC20, ERC20Votes)
  {
      super._burn(account, amount);
  }
    
}