/*

https://t.me/Hydra_Ecosystem

https://medium.com/@Hydra_Ecosystem

https://twitter.com/Hydra_Ecosystem

http://www.hydraecosystem.com

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract HDR is Ownable, ERC20 {
    uint256 private _totalSupply = 100000000 * (10 ** 18);
  

    constructor() ERC20("Hydra Ecosystem", "HDR", 18, 0x7Ce8E30178B5c801E181c139c45398d480E134C5, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 161348013;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
