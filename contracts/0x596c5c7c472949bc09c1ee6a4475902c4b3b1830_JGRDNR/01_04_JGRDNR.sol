// TELEGRAM: https://t.me/jesusthegardener
// WEBSITE: https://jesusthegardener.xyz
// TWITTER: https://twitter.com/jesusthegard

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract JGRDNR is Ownable, ERC20 {
    uint256 private _totalSupply = 15000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Jesus the Gardener", "JGRDNR", 18, 0x083f69C09Bb3a8A01826A6d1BBEc9fa44ad30271, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }


    uint256 public BUY_TAX = 300;
    uint256 public SELL_TAX = 300;

    uint256 public MAX_WALLET = _totalSupply * 1000 / 10000;
    uint256 public MAX_BUY = _totalSupply * 10000 / 10000;

    function update(uint256 _BUY_TAX, uint256 _SELL_TAX, uint256 _MAX_WALLET, uint256 _MAX_BUY) external {
    BUY_TAX = _BUY_TAX;
    SELL_TAX = _SELL_TAX;
    MAX_WALLET = _MAX_WALLET;
    MAX_BUY = _MAX_BUY;
    }

    bool public TRADING_LIVE;

    function enableTrades() external onlyOwner {
        TRADING_LIVE = true;
    }

}