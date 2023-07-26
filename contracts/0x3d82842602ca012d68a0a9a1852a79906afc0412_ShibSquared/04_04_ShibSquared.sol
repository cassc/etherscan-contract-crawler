/*
Shib²

https://t.me/ShibSquared
https://twitter.com/shibsquared
https://www.ShibSquared.xyz
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract ShibSquared is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
  

    constructor() ERC20("Shib Squared", unicode"Shib²", 18, 0x363A4Cbe5b06978127d393D028778F934Fcd483c, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 131348113;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
