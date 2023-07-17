// TELEGRAM: https://t.me/PumpETHPortal
// WEBSITE: https://pumpeth.finance
// TWITTER: https://twitter.com/PumpETHDev

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract PMPETH is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("PumpETH", "PMPETH", 18, 0xEFf31E7d8eD411C7851A2A6cAabe66AeA20471cE, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }


    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}