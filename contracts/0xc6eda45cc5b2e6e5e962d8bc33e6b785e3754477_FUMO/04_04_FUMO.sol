/*
Alien Milady Fumo 2.0

- Fully Community Driven Token
- Lets bring old eth back

https://t.me/Fumo20Portal
https://twitter.com/fumo20erc

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract FUMO is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);
  

    constructor() ERC20("Alien Milady Fumo 2.0", "FUMO2.0", 18, 0x7c39E49e5d8b29002B2a3E5dAabf4B7c6e104425, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 121348113;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
