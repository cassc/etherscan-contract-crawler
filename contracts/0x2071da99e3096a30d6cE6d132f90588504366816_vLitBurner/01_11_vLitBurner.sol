// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./vLit.sol";

contract vLitBurner is Ownable  {

  vLit public _vLit;
  IERC20 public _lit;

  constructor(vLit vLit_, IERC20 lit_) {
    _vLit = vLit_;
    _lit = lit_;
  }

  function convert(uint256 amount) public {
    require(_vLit.balanceOf(msg.sender) >= amount, "not enough vlit");
    require(_lit.balanceOf(address(this)) >= amount, "need lit top-up");

    _vLit.burn(msg.sender, amount);
    _lit.transfer(msg.sender, amount);
  }

  function recover(address token, uint256 amount) public onlyOwner {
    IERC20(token).transfer(msg.sender, amount);
  }
}