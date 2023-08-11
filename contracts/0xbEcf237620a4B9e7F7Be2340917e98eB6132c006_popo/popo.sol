/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

/**

    POPOCOIN | $POPO 🐼 熊猫 - 公平开始

    Website/网站: https://popocoin.net/
    Twitter: https://twitter.com/thepopocoin
    Telegram: https://t.me/PopoEntry

    请在我们社区验证合约地址
*/
// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.20;

contract popo {
    string public constant name = "POPO";//
    string public constant symbol = "POPO";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**decimals;
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}