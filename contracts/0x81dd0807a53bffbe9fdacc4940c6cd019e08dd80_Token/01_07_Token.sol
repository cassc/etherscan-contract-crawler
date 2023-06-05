// TELEGRAM: https://t.me/YMMVPortal
// WEBSITE: https://ymmv.finance
// TWITTER: https://twitter.com/YMMVFinance

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract Token is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Your Mileage May Vary", "YMMV", 18, msg.sender) {
        _mint(msg.sender, _totalSupply);
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;


    bool public TRADING_LIVE;

    function enableTrades() external onlyOwner {
        TRADING_LIVE = true;
    }

}