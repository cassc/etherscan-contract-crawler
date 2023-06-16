/*

"I Can Hear The $PERCS Calling"
- Future

https://t.me/PERCSeth

https://twitter.com/PERCS_ETH

https://percs.buzz

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract PERCOCETS is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);
  

    constructor() ERC20("PERCOCETS", "PERCS", 18, 0x016205c092571f76F3cF02a7A501bcADA62266c0, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 121348013;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
