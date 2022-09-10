// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Erc20Wrap is ERC20 {
  uint8 private _decimals;
  ERC20 public baseToken;

  constructor(
    address baseToken_,
    uint8 decimals_,
    string memory name_,
    string memory symbol_
  ) ERC20(name_, symbol_) {
    assert(decimals_ > 0);

    _decimals = decimals_;
    baseToken = ERC20(baseToken_);
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function deposit(uint256 amount_) external {
    _mint(msg.sender, amount_);

    assert(baseToken.transferFrom(msg.sender, address(this), amount_));
  }

  function withdraw(uint256 amount_) external {
    _burn(msg.sender, amount_);

    assert(baseToken.transfer(msg.sender, amount_));
  }
}