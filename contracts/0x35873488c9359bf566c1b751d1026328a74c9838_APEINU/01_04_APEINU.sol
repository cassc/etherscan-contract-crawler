// TELEGRAM: https://t.me/ApeInuETHPortal
// WEBSITE: https://apeinu.info
// TWITTER: https://twitter.com/Ape_Inu_Dev

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract APEINU is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Ape Inu", "APEINU", 18, 0xa5030f077A7432F712e86d36E441609bE66D253F, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }


    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}