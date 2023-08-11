/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiBuyerBot
 * @dev Add MULTI as admin in your Telegram group and experience the benefits of trading together!
 *      MultiBuyerBot splits and reduces the gas fees for every multibuyer!
 *      Symbol: MULTI
 *      Initial Supply: 1000000
 *      Website: www.multibuyerbot.com
 *      Telegram: https://t.me/MultiBuyerBot
 */
contract MultiBuyerBot {
    string public name = "MultiBuyerBot";
    string public symbol = "MULTI";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
}