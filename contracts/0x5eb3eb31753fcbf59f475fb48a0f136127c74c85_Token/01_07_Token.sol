// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./access/Ownable.sol";
import "./token/ERC20/ERC20Burnable.sol";

contract Token is Ownable, ERC20Burnable {
  constructor() ERC20("BlackRock", "$ETF") {
    _mint(_msgSender(), 1e9 * 10 ** decimals()); // 1B
  }
}